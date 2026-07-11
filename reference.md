# Reference — ASCII Wallpaper Projects & Related Implementations

A curated list of existing projects, plugins, and approaches for using ASCII art as desktop wallpapers, terminal backgrounds, or screen decoration. Covers KDE Plasma plugins, standalone tools, hacky approaches, and conceptual groundwork.

---

## KDE Plasma Wallpaper Plugins

### ASCII Wallpapers (static image → ASCII)

- **Author**: Korvexx
- **Source**: https://gitlab.com/Korvexx/ascii-wallpaper
- **Store**: https://store.kde.org/p/2348111
- **License**: AGPLv3+
- **Status**: Active (updated May 2026)
- **Approach**: Static image-to-ASCII shader. Takes any image or slideshow and converts it to ASCII art in real-time via a GLSL fragment shader. Uses a Canvas-rendered character atlas + ShaderEffect.
- **Chars**: 24 chars from `#` to `.` with density mapping
- **Features**: Detail slider, grayscale toggle, font family selection, slideshow mode with crossfade, custom character set
- **Limitation**: Static only — no animation or reactivity. Relies on an image source, no procedural generation.
- **Relevance**: Same architecture we're using (Canvas atlas + ShaderEffect). Good reference for QML/GLSL patterns.

### Smart Video Wallpaper Reborn

- **Author**: Multiple (community fork)
- **Source**: KDE Store (original listing 404'd, forks exist on GitHub)
- **License**: GPL
- **Status**: Maintenance
- **Approach**: Plays video/GIF files as desktop background using QML VideoOutput + ShaderEffect
- **Features**: Playback speed, volume, multiple monitors
- **Limitation**: Requires video files — no procedural or ASCII rendering
- **Relevance**: Can be used to play pre-rendered ASCII animation videos as wallpaper

---

## Terminal-Based Animated Backgrounds (Desktop Wallpaper via hacks)

### terminal-bg (Python/GTK)

- **Author**: DaarcyDev
- **Source**: https://github.com/DaarcyDev/terminal-bg
- **License**: MIT
- **Stars**: 48
- **Status**: Stable (last updated ~2025)
- **Approach**: Python script using GTK3 + VTE + GtkLayerShell. Creates a transparent terminal that sits as a desktop wallpaper layer. Any CLI program (cava, cmatrix, asciiquarium) renders as wallpaper.
- **Features**: Configurable opacity, floating mode, multi-monitor, auto-start
- **Limitation**: Not a proper wallpaper plugin — it's a window hack using layer-shell. Heavy dependency (GTK, VTE).
- **Relevance**: Direct precedent for "ASCII animation as desktop wallpaper" using xwinwrap-style embedding.

### xwinwrap + mpv / terminal

- **Source**: Various (archwiki, /r/unixporn)
- **Approach**: Uses `xwinwrap` to embed any X11 window as the desktop background layer. Pair with `mpv` (video), a terminal running `cmatrix`, or any program.
- **Classic commands**:
  ```bash
  xwinwrap -ni -s -fs -st -sp -b -nf -- mpv -wid WID --loop file.mp4
  xwinwrap -ni -s -fs -st -sp -b -nf -- urxvt -e cmatrix
  ```
- **Limitation**: X11 only, compositor-dependent, no Wayland support without XWayland. Window management hacks.
- **Relevance**: The OG approach. Still works on X11 sessions.

---

## Terminal ASCII Animation Tools (candidates for wallpaper embedding)

| Tool | Description | Source |
|------|-------------|--------|
| **cmatrix** | Matrix rain with katakana | https://github.com/abishekvashok/cmatrix |
| **asciiquarium** | Animated ASCII aquarium | https://github.com/cmatsuoka/asciiquarium |
| **aafire** | ASCII fire effect | Part of `aalib` / `cacalib` |
| **pipes.sh** | Animated pipes in terminal | https://github.com/lvkv/pipes.sh |
| **asciimation** | Frame-based ASCII animation playback | https://github.com/octobanana/asciimation |
| **terminal-parrot** | Animated parrot in terminal | https://github.com/jmhobbs/terminal-parrot |
| **bonsai.sh** | Growing ASCII bonsai tree | https://gitlab.com/jallbrit/bonsai.sh |
| **bb** | ASCII banner animation (demo/party mode) | https://github.com/daniel-e/bb |
| **cacaview / cacademo** | libcaca-based ASCII art and animations | http://caca.zoy.org/ |
| **cava** | Audio spectrum visualizer in terminal | https://github.com/karlstav/cava |

All of these can be repurposed as desktop wallpaper via xwinwrap or terminal-bg on X11, or rendered to a video file for use with KDE's video wallpaper plugin.

---

## Related Terminal Composition Tools

### termflux (Rust)

- **Author**: tndoan
- **Source**: https://github.com/tndoan/termflux
- **License**: MIT
- **Stars**: 7
- **Status**: Active (updated Feb 2026)
- **Approach**: Runs your shell inside a composited terminal window with animated effects overlaid behind your text. Built-in starfield, matrix rain, and fire animations. Supports piping any external CLI program as the animation layer.
- **Features**: Hotkeys (Alt+J/K opacity, Alt+N cycle animation, Alt+A toggle), auto-detect terminal background color via OSC 11, external program backdrop support
- **Limitation**: Terminal compositor, not a desktop wallpaper. Pixel-based animations, not ASCII characters.
- **Relevance**: Same visual concept (animated background while working) but for terminal, not desktop. Good inspiration for animation modes.

### sigye (Rust TUI clock)

- **Author**: am2rican5
- **Source**: https://github.com/am2rican5/sigye
- **License**: MIT
- **Stars**: 113
- **Status**: Active (updated June 2026, 122 commits)
- **Approach**: Full-screen TUI clock with 21 animated backgrounds (starfield, matrix rain, weather effects, cherry blossoms, aurora, twilight) and system-reactive backgrounds (CPU, memory, network). Supports FIGlet fonts, color themes, screensaver mode.
- **Features**: 6 display modes, 40+ fonts, 18 color themes, 5 animation styles, world clock, Pomodoro, `--screensaver` flag, `--bg` flag
- **Limitation**: Takes over the terminal — not a background layer. TUI clock first, animations second.
- **Relevance**: Best reference for ASCII animation variety. 21 different background types shows the design space. System-reactive modes (CPU/mem → visual effect) is exactly what "reactive" means for our plugin.

### Asciiville

- **Author**: doctorfree
- **Source**: https://github.com/doctorfree/Asciiville
- **License**: MIT
- **Status**: Active
- **Approach**: Comprehensive collection of ASCII art, animations, and terminal utilities. Includes display servers, animation players, and integration with other tools.
- **Features**: Ascii display server, art viewer, animation player, integration with neofetch, pipes.sh, cmatrix
- **Relevance**: Large collection of pre-made ASCII art assets and animations. Good source of content.

---

## Desktop Live Wallpaper Tools (Linux)

| Tool | Description | Source |
|------|-------------|--------|
| **Smart Video Wallpaper Reborn** | KDE video wallpaper plugin | KDE Store |
| **linux-wallpaperengine** | Steam Wallpaper Engine scenes on Linux | https://github.com/ati123/linux-wallpaperengine |
| **Komorebi** | Animated wallpaper manager (discontinued) | https://github.com/cheesecakeufo/komorebi |
| **mpvpaper** | Wayland wallpaper via mpv | https://github.com/GhostNaN/mpvpaper |
| **plasma-wallpaper-mpvpapers** | KDE wallpaper plugin for mpv | Various forks |

---

## Technical References

### Qt 6 ShaderEffect Documentation

- https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html
- Uniforms mapped from QML properties by name
- `.qsb` compiled shaders required (no inline GLSL in Qt 6)
- `buf` block at binding=0 reserved for `qt_Matrix` and `qt_Opacity`
- Sampler binding must be declared with `layout(binding=N) uniform sampler2D`

### qsb (Qt Shader Baker)

- Ships with `qt6-shader-baker` package
- Path: `/usr/lib/qt6/bin/qsb`
- Compiles GLSL → SPIR-V → .qsb with embedded reflection data
- Usage: `qsb input.frag -o output.frag.qsb`
- Inspect reflection: `qsb --dump shader.frag.qsb`

### KDE Wallpaper Plugin Structure

- Install path: `~/.local/share/plasma/wallpapers/<plugin-id>/`
- Manifest: `metadata.json` with `"KPackageStructure": "Plasma/Wallpaper"`
- Root QML: `contents/ui/main.qml` extending `WallpaperItem`
- Config: `contents/config/main.xml` (KConfigXT format)
- Shaders: `contents/shaders/` (any .qsb files referenced from QML)

### KDE Developer Docs

- https://develop.kde.org/docs/plasma/ (Plasma themes & plugins section)
- Wallpaper plugins listed under "Plasma themes and plugins" > "Wallpaper Plugin"
- Install paths: `/usr/share/plasma/wallpapers/` (system) / `~/.local/share/plasma/wallpapers/` (user)
