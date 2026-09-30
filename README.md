# Weevil City Cruisers

Lightweight nginx website for the Weevil City Cruisers car club in Enterprise, Alabama. Static HTML, CSS, JavaScript, and nginx's JSON directory index; no database, Node server, Python server, background scanner, or scheduled indexing process. Official `nginx:stable-alpine` base with one nginx worker to keep resource use small. HTTP port 80.

Source repository: https://github.com/avalanche208/weevilcitycruisers. Docker image target: `avalanche208/weevilcitycruisers:latest`. Check the Actions result and Docker Hub tags before deploying. The container serves HTTP only; your external proxy handles the certificate.

## unRAID setup

Create a container in unRAID with:

| Setting | Value |
|---|---|
| Repository | `avalanche208/weevilcitycruisers:latest` (after publication) |
| Network | Bridge |
| Container port | `80/TCP` |
| Host port | `8080`, or another available port |
| Container path | `/data` |
| Host path | `/mnt/user/appdata/weevil-city-cruisers` |
| Access mode | Read/Write |
| Privileged | No |
| WebUI | `http://[IP]:[PORT:80]/` |

The supplied `unraid/weevil-city-cruisers.xml` can be installed as a user template at `/boot/config/plugins/dockerMan/templates-user/my-weevil-city-cruisers.xml` on the unRAID host. Open Docker → Add Container and select Weevil-City-Cruisers. No existing application repositories are used.

Visit `http://YOUR-UNRAID-IP:8080`. For a public domain, put the HTTP container behind your existing reverse proxy with HTTPS and point the domain to that proxy.

## Add car show pictures

On the unRAID host, copy your pictures into:

```
/mnt/user/appdata/weevil-city-cruisers/car_show_pictures/2022/
/mnt/user/appdata/weevil-city-cruisers/car_show_pictures/2023/
/mnt/user/appdata/weevil-city-cruisers/car_show_pictures/2024/
/mnt/user/appdata/weevil-city-cruisers/car_show_pictures/2025/
/mnt/user/appdata/weevil-city-cruisers/car_show_pictures/2026/
```

Inside the container these are `/data/car_show_pictures/YYYY/`. The initial five folders are created on startup; empty albums show “Photos coming soon.” The container does not change existing ownership or permissions. Folders need to be traversable and photos readable by nginx. Normal directory permissions `755` and image permissions `644` work.

To add a future album, create `car_show_pictures/2027/` and add images. Its album appears automatically. No container rebuild, restart, database update, or index command is needed. Refresh the page after adding or removing photos. Gallery pages live at `/car-shows/YYYY/`. Old `/car-show-pictures-YYYY.html` URLs redirect to the new pages.

Supported: JPG, JPEG, PNG, WebP, GIF, AVIF, including uppercase extensions, spaces, and Unicode filenames. Convert HEIC files to JPEG first. Files must be directly inside the year folder; nested folders are intentionally ignored. Four-digit year folders are discovered automatically. Files are sorted naturally by filename. Hidden files are excluded from the gallery; only the listed image formats are served through the photo route. Other `/data` files are not publicly served. JSON album listings expose filenames inside the gallery folders, so use them only for public club photos.

The browser loads 48 photo tiles at a time, with lazy image loading. The viewer supports previous/next buttons, left/right arrow keys, Escape, and opening the original image. For large collections, resize photos to about 2000–2500 pixels wide before copying them; this nginx-only design does not generate thumbnails or modify originals.

Back up the host data folder separately. Replacing/updating the container does not remove mounted photographs. The only persistent runtime content is in `/data`.

## Build and run locally

```sh
docker compose up -d --build
```

Edit the host volume path in `docker-compose.yml` if not running on unRAID. Or:

```sh
docker build -t weevil-city-cruisers .
docker run -d --name weevil-city-cruisers --restart unless-stopped \
  -p 8080:80 \
  -v /mnt/user/appdata/weevil-city-cruisers:/data \
  weevil-city-cruisers
```

## New GitHub repository and Docker Hub publishing

The user created new GitHub and Docker Hub repositories named `weevilcitycruisers`. Use only these repositories for this app. For a fresh local checkout, the initial source push commands are:

```sh
git init -b main
git add .
git commit -m "Create Weevil City Cruisers nginx website"
git remote add origin https://github.com/avalanche208/weevilcitycruisers.git
git push -u origin main
```

Configure GitHub Actions secrets on this new repository:

- `DOCKER_USERNAME`: `avalanche208`
- `DOCKER_PASSWORD`: a Docker Hub access token with permission to push this image

Secrets on existing repositories do not automatically carry over. An organization-level secret must explicitly include the new repository if used instead.

The workflow runs container smoke tests before publishing `linux/amd64` and `linux/arm64` images. It publishes on pushes to `main`, `v*` tags, manual runs, and weekly Sunday rebuilds at 08:23 UTC to refresh the nginx base. Tags include `latest`, `2026.9.30-1a`, and a commit SHA tag. Increment the app version in the footer and workflow when changing the website. Change tags if maintaining multiple release lines.

Before deployment, verify the first workflow passes and the image exists on Docker Hub. The workflow includes tests for nginx configuration, initial year creation, deep links, filenames with spaces and punctuation, live additions and deletions, uppercase extensions, and blocking nonimage files.

```sh
bash tests/container-smoke.sh
```

## Recovered website content

Archive.org retrieval on September 30, 2026 found the former home and About pages and gallery pages for 2022, 2023, and 2024. The recovered pages established:

- The club formed in 1996 around a shared interest in old and new cars and trucks.
- Membership welcomes people with classic cars, new cars, or no vehicle.
- The club has a history of supporting local charities.
- The original Facebook link is https://www.facebook.com/WeevilCityCruisers.

Outdated officers, meeting locations, cruise-in schedules, and dated event announcements were not promoted as current facts. Facebook is the destination for current events and contact information.

The archived gallery HTML contains **140 references for 2022, 196 for 2023, and 119 for 2024**. Archive.org's image index returned only two older site images and **none of those 455 original gallery photographs**. The albums are ready for your own photo files; archived references are not represented as recovered photographs. The historical header was recovered for research, but contains an old schedule and is not displayed on the new website. No 2025 or 2026 gallery pages appeared in the recovered site navigation.

Reference snapshots:

- https://web.archive.org/web/20250301000000/https://www.weevilcitycruisers.com/
- https://web.archive.org/web/20250301000000/https://www.weevilcitycruisers.com/about-us.html
- https://web.archive.org/web/20250301000000/https://www.weevilcitycruisers.com/car-show-pictures-2022.html
- https://web.archive.org/web/20250301000000/https://www.weevilcitycruisers.com/car-show-pictures-2023.html
- https://web.archive.org/web/20250301000000/https://www.weevilcitycruisers.com/car-show-pictures-2024.html

The recovered historical text and image reference manifests are in `research/` and excluded from the Docker image. The new classic car illustration is an original SVG, not a club photograph.
