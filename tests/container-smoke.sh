#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
data_dir=$(mktemp -d)
chmod 755 "$data_dir"
container_name="wcc-test-${RANDOM}"
trap 'docker logs "$container_name" 2>&1 | tail -60; docker exec "$container_name" chmod -R a+rwX /data >/dev/null 2>&1 || true; docker rm -f "$container_name" >/dev/null 2>&1 || true; rm -rf "$data_dir"' EXIT
mkdir -p "$data_dir/car_show_pictures/2022"
python3 - "$data_dir/car_show_pictures/2022/a space & quote.jpg" <<'PYIMAGE'
import struct, sys, zlib
chunk = lambda t,d: struct.pack('!I',len(d))+t+d+struct.pack('!I',zlib.crc32(t+d)&0xffffffff)
data = b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',2400,1600,8,2,0,0,0))+chunk(b'IDAT',zlib.compress((b'\0'+b'\xff\x88\x22'*2400)*1600))+chunk(b'IEND',b'')
open(sys.argv[1],'wb').write(data)
PYIMAGE
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
curl -fsS "$base/photos/2022/a%20space%20%26%20quote.jpg" > "$data_dir/original-test"
cmp "$data_dir/original-test" "$data_dir/car_show_pictures/2022/a space & quote.jpg"
# Thumbnail is requested on demand, smaller, cached, and survives restart.
test "$(find "$data_dir/thumbnails" -name '*.jpg' | wc -l)" = 0
curl -fsS "$base/thumbnails/2022/a%20space%20%26%20quote.jpg" > "$data_dir/thumb-test"
python3 - "$data_dir/thumb-test" <<'PYJPEG'
import sys
assert open(sys.argv[1],'rb').read(2) == b'\xff\xd8'
PYJPEG
test "$(find "$data_dir/thumbnails" -name '*.jpg' | wc -l)" = 1
cache_before=$(find "$data_dir/thumbnails" -name '*.jpg' -printf '%f %T@')
docker exec "$container_name" sh -c 'vipsheader /data/thumbnails/*.jpg' | grep -F '720x480'
curl -fsS "$base/thumbnails/2022/a%20space%20%26%20quote.jpg" > "$data_dir/thumb-again"
cmp "$data_dir/thumb-test" "$data_dir/thumb-again"
test "$cache_before" = "$(find "$data_dir/thumbnails" -name '*.jpg' -printf '%f %T@')"
docker restart "$container_name"
for attempt in {1..30}; do curl -fsS "$base/healthz" && break || sleep 1; done
curl -fsS "$base/thumbnails/2022/a%20space%20%26%20quote.jpg" > "$data_dir/thumb-again"
cmp "$data_dir/thumb-test" "$data_dir/thumb-again"
test "$cache_before" = "$(find "$data_dir/thumbnails" -name '*.jpg' -printf '%f %T@')"
# Changed originals generate a fresh cache entry; the original is untouched.
touch -m -d '+2 seconds' "$data_dir/car_show_pictures/2022/a space & quote.jpg"
curl -fsS "$base/thumbnails/2022/a%20space%20%26%20quote.jpg" > /dev/null
test "$(find "$data_dir/thumbnails" -name '*.jpg' | wc -l)" = 2
cmp "$data_dir/original-test" "$data_dir/car_show_pictures/2022/a space & quote.jpg"
# No Python/image processor remains in memory between requests.
! docker exec "$container_name" ps -o comm | grep -E '^(python3|vipsthumbnail)$'
curl -fsS "$base/car-shows/2022/" | grep -F 'gallery-page'
# Live filesystem discovery: additions and deletions require no restart.
mkdir "$data_dir/car_show_pictures/2027"
printf 'new-image' > "$data_dir/car_show_pictures/2027/new.PNG"
curl -fsS "$base/api/years/" | python3 -c 'import json,sys; assert any(x["name"]=="2027" for x in json.load(sys.stdin))'
curl -fsS "$base/photos/2027/new.PNG" | grep -F new-image
rm "$data_dir/car_show_pictures/2027/new.PNG"
curl -fsS "$base/api/photos/2027/" | python3 -c 'import json,sys; assert json.load(sys.stdin)==[]'
for path in /thumbnails/2022/private.txt /thumbnails/2022/missing.jpg /_thumbnail_cache/test.jpg /thumbnails/2022/%2e%2e%2fsecret.jpg /photos/2022/private.txt /data/secret.txt /api/photos/not-a-year/ /photos/2022/../../secret.txt; do
 test "$(curl --path-as-is -s -o /dev/null -w '%{http_code}' "$base$path")" = 404
done
if [ "${BROWSER_TEST:-0}" = 1 ]; then
 TEST_BASE_URL="$base" node tests/browser-smoke.cjs
fi
printf '\nContainer smoke tests passed.\n'
