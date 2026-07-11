#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
install_root="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/wallpapers"
install_dir="$install_root/ascii-reactive-wallpaper"

"$project_dir/build-native.sh"

mkdir -p "$install_root"
if [[ -L "$install_dir" ]]; then
    rm "$install_dir"
elif [[ -e "$install_dir" ]]; then
    backup="$install_dir.backup.$(date +%Y%m%d%H%M%S)"
    mv "$install_dir" "$backup"
    printf 'Existing installation moved to %s\n' "$backup"
fi

mkdir -p "$install_dir"
cp -a "$project_dir/metadata.json" "$project_dir/contents" "$install_dir/"
printf 'Installed ASCII Reactive Wallpaper to %s\n' "$install_dir"
printf 'Select it in Plasma wallpaper settings, or switch away and back to reload it.\n'
