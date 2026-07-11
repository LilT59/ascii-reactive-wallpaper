#!/usr/bin/env bash
set -euo pipefail

QSB=${QSB:-/usr/lib/qt6/bin/qsb}

"$QSB" --qt6 -b contents/shaders/ascii.vert -o contents/shaders/ascii.vert.qsb
"$QSB" --qt6 contents/shaders/ascii.frag -o contents/shaders/ascii-v2.frag.qsb
"$QSB" --qt6 contents/shaders/diagnostic.frag -o contents/shaders/diagnostic.frag.qsb
