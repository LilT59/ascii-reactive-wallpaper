#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cmake -S "$project_dir/native" -B "$project_dir/build/native" -DCMAKE_BUILD_TYPE=Release
cmake --build "$project_dir/build/native" --parallel
