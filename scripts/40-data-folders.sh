#!/bin/sh
set -eu
for year in 2022 2023 2024 2025 2026; do
    mkdir -p "/data/car_show_pictures/$year"
done
# Never change ownership or permissions of existing user files.
