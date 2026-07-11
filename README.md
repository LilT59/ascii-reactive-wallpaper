# ASCII Reactive Wallpaper

A KDE Plasma 6 wallpaper plugin that renders animated and reactive ASCII art with a native Qt Quick scene-graph renderer.

## Features

- Starfield, Matrix rain, plasma, fire, aurora, and nebula modes
- Static images and procedural animations converted to ASCII
- Adaptive source-color palettes with configurable color depth
- Pointer displacement and click ripples
- Configurable character ramp, size, speed, color, and frame rate
- Native batched rendering designed to avoid blocking Plasma's UI

## Requirements

- KDE Plasma 6
- CMake 3.21 or newer
- C++17 compiler
- Qt 6 Core, Gui, QML, and Quick development files

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

Validate project files:

```bash
qmllint -I contents/ui contents/ui/main.qml contents/ui/config.qml
xmllint --noout contents/config/main.xml
jq empty metadata.json
```

## Troubleshooting

Inspect Plasma logs:

```bash
journalctl --user -u plasma-plasmashell.service -f -o cat
```


## Packaging

This plugin contains a native QML extension. Distributions and release packages must compile it against their Qt version and CPU architecture; do not redistribute a locally built `.so` as a universal package.

## License

MIT. See [LICENSE](LICENSE).
