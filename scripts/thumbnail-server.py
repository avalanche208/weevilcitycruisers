#!/usr/bin/python3
"""On-demand CGI thumbnail generator. nginx serves the resulting bytes."""
import hashlib
import fcntl
import os
from pathlib import Path
import re
import subprocess
import tempfile
from urllib.parse import unquote, urlsplit

ROOT = Path('/data/car_show_pictures').resolve()
CACHE = Path('/data/thumbnails')
ROUTE = re.compile(r'/thumbnails/([0-9]{4})/([^/\\]+\.(?:jpe?g|png|webp|gif|avif))', re.I)


def reply(status, redirect=None):
    print(f'Status: {status}')
    if redirect:
        print('X-Accel-Redirect: ' + redirect)
    print('Content-Type: text/plain')
    print()


def main():
    path = unquote(urlsplit(os.environ.get('REQUEST_URI', '')).path)
    match = ROUTE.fullmatch(path)
    if not match or match[2].startswith('.') or any(ord(c) < 32 for c in path):
        reply('404 Not Found')
        return
    source = ROOT / match[1] / match[2]
    try:
        source.resolve().relative_to(ROOT)
        with source.open('rb') as original:
            stat = os.fstat(original.fileno())
            key = hashlib.sha256(f'v1:{source}:{stat.st_mtime_ns}:{stat.st_size}'.encode()).hexdigest()
            target = CACHE / (key + '.jpg')
            # A shared lock file coalesces simultaneous requests for the same image.
            with (CACHE / (key + '.lock')).open('a') as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                if not target.is_file():
                    fd, temporary = tempfile.mkstemp(suffix='.jpg', dir=CACHE)
                    os.close(fd)
                    try:
                        subprocess.run([
                            'vipsthumbnail', f'/proc/self/fd/{original.fileno()}',
                            '--size', '720x480', '--no-upsize',
                            '--output', temporary + '[Q=80,strip]',
                            '--vips-concurrency=1', '--vips-cache-max=0',
                        ], pass_fds=(original.fileno(),), check=True, timeout=60,
                            env={**os.environ, 'VIPS_CONCURRENCY': '1', 'VIPS_DISC_THRESHOLD': '32m'},
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                        os.chmod(temporary, 0o644)
                        os.replace(temporary, target)
                    finally:
                        Path(temporary).unlink(missing_ok=True)
    except (FileNotFoundError, NotADirectoryError, ValueError):
        reply('404 Not Found')
        return
    except (OSError, subprocess.SubprocessError):
        reply('503 Service Unavailable')
        return
    reply('200 OK', '/_thumbnail_cache/' + target.name)


if __name__ == '__main__':
    main()
