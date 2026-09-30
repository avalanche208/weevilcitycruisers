#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
data_dir=$(mktemp -d)
container_name="wcc-test-${RANDOM}"
trap 'docker rm -f "$container_name" >/dev/null 2>&1 || true; rm -rf "$data_dir"' EXIT
mkdir -p "$data_dir/car_show_pictures/2022"
printf 'test-image' > "$data_dir/car_show_pictures/2022/a space & quote.jpg"
printf 'private' > "$data_dir/secret.txt"
printf 'private' > "$data_dir/car_show_pictures/2022/private.txt"
docker build -t wcc-smoke .
docker run -d --name "$container_name" -p 127.0.0.1::80 -v "$data_dir:/data" wcc-smoke
docker exec "$container_name" nginx -t
port=$(docker port "$container_name" 80/tcp | sed 's/.*://')
base="http://127.0.0.1:$port"
for attempt in {1..30}; do curl -fsS "$base/healthz" && break || sleep 1; done
curl -fsS "$base/" | grep -F 'Weevil City Cruisers'
curl -fsS "$base/api/years/" | python3 -c 'import json,sys; assert {str(y) for y in range(2022,2027)} <= {x["name"] for x in json.load(sys.stdin)}'
curl -fsS "$base/api/photos/2022/" | python3 -c 'import json,sys; assert any(x["name"] == "a space & quote.jpg" for x in json.load(sys.stdin))'
test "$(curl -fsS "$base/photos/2022/a%20space%20%26%20quote.jpg")" = test-image
curl -fsS "$base/car-shows/2022/" | grep -F 'gallery-page'
# Live filesystem discovery: additions and deletions require no restart.
mkdir "$data_dir/car_show_pictures/2027"
printf 'new-image' > "$data_dir/car_show_pictures/2027/new.PNG"
curl -fsS "$base/api/years/" | python3 -c 'import json,sys; assert any(x["name"]=="2027" for x in json.load(sys.stdin))'
curl -fsS "$base/photos/2027/new.PNG" | grep -F new-image
rm "$data_dir/car_show_pictures/2027/new.PNG"
curl -fsS "$base/api/photos/2027/" | python3 -c 'import json,sys; assert json.load(sys.stdin)==[]'
for path in /photos/2022/private.txt /data/secret.txt /api/photos/not-a-year/ /photos/2022/../../secret.txt; do
 test "$(curl --path-as-is -s -o /dev/null -w '%{http_code}' "$base$path")" = 404
done
if [ "${BROWSER_TEST:-0}" = 1 ]; then
 TEST_BASE_URL="$base" node tests/browser-smoke.cjs
fi
printf '\nContainer smoke tests passed.\n' 
