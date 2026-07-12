# ASCII Reactive Wallpaper

A KDE Plasma 6 wallpaper plugin that renders animated and reactive ASCII art with a native Qt Quick scene-graph renderer.

![Demo](https://github.com/LilT59/ascii-reactive-wallpaper/releases/download/v1.0.0/demo.gif)

Version 2.0 adds saved profiles, image-quality controls, live configuration previews, expanded appearance controls, battery-aware pausing, smoother transitions, and substantial renderer allocation reductions.

## Features

- Starfield, Matrix rain, Matrix 3D, plasma, fire, aurora, nebula, and ocean waves modes
- Static images and procedural animations converted to ASCII
- Adaptive source-color palettes with configurable color depth
- Aspect-correct pointer displacement and click ripples with configurable speed and persistence
- Eight character-ramp presets, including block, Braille, geometric, and binary styles
- Configurable background, brightness, contrast, gamma, spacing, speed, color, and frame rate
- Saved profiles covering source, appearance, animation, and reactive settings
- Configurable monospace fonts, foreground opacity, glow, procedural scale, and intensity
- Ordered image dithering and edge-aware luminance enhancement
- Live configuration previews, performance presets, battery pausing, and smooth setting crossfades
- Immediate profile application with restoration of the last active profile
- Native batched rendering designed to avoid blocking Plasma's UI

## Requirements

- KDE Plasma 6
- CMake 3.21 or newer
- C++17 compiler
- Qt 6 Core, DBus, Gui, QML, and Quick development files

Ubuntu/Debian:

```bash
sudo apt install build-essential cmake qt6-base-dev qt6-declarative-dev
```

## Install

```bash
git clone https://github.com/LilT59/ascii-reactive-wallpaper.git
cd ascii-reactive-wallpaper
./install.sh
```

Then open the desktop wallpaper settings and select **ASCII Reactive Wallpaper**. If Plasma already loaded an older native module, switch to another wallpaper and back. Avoid restarting `plasmashell` as a routine reload method.

## Update

```bash
git pull
./install.sh
```

## Uninstall

```bash
./uninstall.sh
```

## Development

Build the architecture- and Qt-version-specific QML module:

```bash
./build-native.sh
```

The generated library is intentionally excluded from Git. Rebuild it after Qt ABI upgrades.

See [CHANGELOG.md](CHANGELOG.md) for release history.

Validate project files:

```bash
qmllint -I contents/ui contents/ui/main.qml contents/ui/config.qml
xmllint --noout contents/config/main.xml
jq empty metadata.json
ldd -r contents/ui/native/libasciireactivepointerplugin.so
```

Set `ASCII_WALLPAPER_PROFILE=1` before starting Plasma to log five-second renderer timing summaries, including character generation, ripple simulation, scene-graph updates, atlas creation, glyph counts, and batch counts.

## Troubleshooting

Inspect Plasma logs:

```bash
journalctl --user -u plasma-plasmashell.service -f -o cat
```


## Packaging

This plugin contains a native QML extension. Distributions and release packages must compile it against their Qt version and CPU architecture; do not redistribute a locally built `.so` as a universal package.

## License

MIT. See [LICENSE](LICENSE).
