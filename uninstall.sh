#!/usr/bin/env bash
set -euo pipefail

install_dir="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/wallpapers/ascii-reactive-wallpaper"

if [[ -L "$install_dir" || -d "$install_dir" ]]; then
    rm -rf "$install_dir"
    printf 'Removed %s\n' "$install_dir"
else
    printf 'ASCII Reactive Wallpaper is not installed at %s\n' "$install_dir"
fi
