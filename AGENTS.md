# ASCII Reactive Wallpaper — KDE Plasma Plugin

## Goal

A KDE Plasma 6 wallpaper plugin that renders animated, reactive ASCII art as your desktop background. It uses a native Qt Quick scene-graph renderer for predictable performance inside `plasmashell`.

## Architecture

```
ascii-reactive-wallpaper/
├── AGENTS.md                  # This file — project blueprint & conventions
├── metadata.json              # KPackage manifest (Plasma/Wallpaper)
├── contents/
│   ├── config/
│   │   └── main.xml           # KConfigXT settings UI
│   ├── ui/
│   │   ├── main.qml           # WallpaperItem root, config, pointer mapping
│   │   └── native/            # Compiled QML renderer/pointer module
│   └── shaders/
│       ├── ascii.vert         # GLSL vertex shader (source)
│       ├── ascii.frag         # GLSL fragment shader (source)
│       ├── ascii.vert.qsb     # Compiled vertex shader
│       └── ascii.frag.qsb     # Compiled fragment shader
```

## Rendering Pipeline (Native Scene Graph)

```
Timer tick ──→ native AsciiRenderer
                    ├── C++ source sampling and luminance
                    ├── C++ low-resolution displacement simulation
                    ├── brightness → character index
                    ├── cached glyph atlas texture
                    └── bounded QSG geometry batches → GPU
```

## Component Details

### metadata.json
Standard KDE Plasma wallpaper manifest. `KPackageStructure: "Plasma/Wallpaper"`.

### contents/config/main.xml
KConfigXT definition for user-configurable settings:
- **Mode** — Animation type (0=starfield, 1=matrix, etc.)
- **CharacterSize** — Numeric character height in pixels (8-48)
- **ColorDepth** — Adaptive media palette size (4-64)
- **Color** — Primary color / palette
- **Speed** — Animation speed multiplier
- **FrameRate** — Maximum animation rate (5-60 FPS)
- **WaveSpeed** — Reactive wave propagation multiplier (0.5-2.0)
- **RampPreset** — Built-in character-ramp selection (custom plus eight presets)
- **BackgroundColor**, **Brightness**, **Contrast**, **Gamma** — Tone and background controls
- **CharacterSpacing**, **ReverseRamp** — Glyph layout and ordering controls

These are exposed as `wallpaper.configuration.*` properties in QML.

Current configuration uses an explicit numeric character height (8-48 px) and adaptive
source color depth (4-64 colors). Procedural animations keep curated mode colors by
default; users can override them with the selected primary color. Source media can use
its adaptive palette independently. The configuration page includes a reset-to-defaults
button, and defaults must remain synchronized with `contents/config/main.xml`.
Animation rate is configurable from 5-60 FPS with a 24 FPS default. Displacement physics
runs independently at 15-60 Hz based on WaveSpeed, and static images do not rebuild merely
because the clock advances.

### contents/ui/main.qml
Root component extending `WallpaperItem`:
- Creates one native `AsciiRenderer` child
- Runs a configurable timer that advances procedural animation time
- Maps global pointer coordinates from `PointerTracker` into wallpaper-local coordinates
- Displays media decoding errors without blocking the renderer
- Cleans up on destruction

### native/asciirenderer.cpp
The active rendering core. Procedural generation, image downsampling, displacement,
and character mapping run in C++. Glyphs are cached in a small atlas and emitted as
textured quads in batches below backend vertex limits. Never add one QML item per cell.

### native/pointertracker.cpp
An in-process singleton that polls the global cursor and observes mouse presses through
a `plasmashell` application event filter. QML maps global coordinates to each wallpaper.

### contents/shaders
Historical ShaderEffect experiments. They are retained as references but are not loaded
by the active wallpaper. Runtime rendering is implemented by `native/asciirenderer.cpp`.

#### Modes

**Mode 0 — Starfield (default)**
- Each character cell has a ~3% probability of containing a star
- Stars twinkle using cell-hash-seeded sine wave offset by time
- Brightness determines character density (space → . → : → r → # → @)
- Color: cyan-white stars on near-black background
- Hash-based seeding means stars are deterministic per position but pseudo-random

**Mode 1 — Matrix Rain**
- Each column has an independent falling head with pseudo-random speed and offset
- Heads deposit characters into persistent per-cell state
- Deposited characters remain stationary, independently cycle, fade by age, and clear
- Brightness selects multiple green atlas rows while glyph identity is independent
- Color: classic matrix green on black

**Implemented additional modes**:
- Plasma, fire, aurora, nebula, and ocean waves

**Future modes** (design space):
- Audio-reactive — needs pipewire/pulse audio hook via D-Bus → shader uniform
- System-reactive — CPU/mem/network via KDE system monitor daemon → shader uniform

#### Scene-Graph Pipeline
```
source frame/procedural state -> displaced cell sample
brightness -> character index
source color -> cached adaptive palette index
character + palette row -> atlas UV
visible cells -> textured quads in <=10,000-glyph batches
```

## Native Compilation

Run `./build-native.sh` to build `contents/ui/native/libasciireactivepointerplugin.so`.
The generated library is architecture- and Qt-ABI-specific and is excluded from Git.

## Configuration Flow

1. User picks "ASCII Reactive Wallpaper" in System Settings → Desktop Effects → Wallpaper Type
2. KConfig reads saved settings (or defaults)
3. `main.qml` receives config via `wallpaper.configuration.*`
4. Changes propagate to the native `AsciiRenderer` immediately
5. Ramp, detail, or palette changes rebuild the small glyph atlas
6. Source frames and procedural ticks update bounded scene-graph geometry batches

## Development Commands

```bash
# Install locally for testing
./install.sh

# Uninstall
./uninstall.sh

# Rebuild the native QML module
./build-native.sh

# Check for Qt Quick errors (after switching wallpaper)
journalctl -f -o cat | grep -i --line-buffered "qml\|shader\|wallpaper\|ascii"
```

## Pitfalls / Known Issues

- **Native ABI** — rebuild after Qt upgrades and for every target architecture.
- **Geometry limits** — keep batches below 60,000 vertices; the current limit is 10,000 glyphs (60,000 vertices).
- **Atlas ownership** — textures are created on the scene-graph synchronization path and owned by the render root.
- **First ramp character** — keep it as a space so zero brightness emits no geometry.
- **Static media** — never rebuild static image geometry because procedural time advanced.
- **Adaptive colors** — cache per-cell palette indices; do not run nearest-color searches during ripple steps.
- **Plasma reloads** — switch wallpaper types to reload; routine `plasmashell` restarts have crashed on this setup.
- **KConfigXT `Url` type** — `ImagePath` must use `type="String"`, not `type="Url"`. An empty default `Url` crashes systemsettings (SIGABRT) because it tries to construct `QUrl("")`. All built-in KDE wallpapers use `String` for file paths.
- **QPointF metatype** — `PointerTracker`'s QML singleton registration requires `qRegisterMetaType<QPointF>()` before `qmlRegisterSingletonType` in `registerTypes()`. Without it, the QML engine can't resolve `Q_PROPERTY(QPointF globalPosition ...)` in contexts where QPointF isn't pre-registered.
- **Null window in updatePaintNode** — guard with `if (!window()) return nullptr;` before accessing `window()->createTextureFromImage()`. systemsettings preview windows may not have a fully initialized scene graph.
- **Qt Multimedia** — removed from build (was linked but unused after video/GIF stripped). If re-added later, use `QLibrary` runtime loading to avoid pulling the multimedia backend into systemsettings.

## Quality Checklist

- [x] Plugin shows up in Wallpaper Type dropdown after install
- [x] Starfield mode renders animated twinkling stars as ASCII characters
- [x] Matrix rain mode renders falling character columns
- [x] Mode switching works without visual artifacts
- [x] Detail setting correctly changes character resolution
- [x] Atlas regenerates when detail changes
- [ ] No QML warnings in journalctl
- [x] No performance stutter (stable ~30fps on integrated GPU)
- [x] Clean uninstall removes all plugin files

## Current Rendering Status

The working renderer is the native `AsciiRenderer` QML extension. The former text-row
backend was removed from the active path because JavaScript string generation and text
shaping stalled the entire Plasma UI at small character sizes. The older ShaderEffect
sources remain historical experiments and are not used at runtime.

## Planned Source Pipeline

All rendering modes should feed a shared character-grid pipeline:

```
Source brightness/color
        |
        v
Displacement field
        |
        v
Sample displaced source
        |
        v
Brightness -> ASCII character
        |
        v
Render bounded glyph batches
```

Supported sources:

- Static images with stretch, fit, and crop modes
- Starfield
- Matrix rain
- Plasma/noise
- Future audio or system-monitor sources

Note: Animated GIF and video playback were removed due to Qt Multimedia linkage causing systemsettings crashes. Static image-to-ASCII conversion via `QImage` still works.

Each logical cell may contain brightness, a quantized foreground color, and scalar
height/velocity values. Rendering derives X/Y displacement from the height gradient.

## Image-to-ASCII Mode

Image rendering should follow these steps:

1. Select a local image with the configuration file dialog.
2. Decode still images with Qt image APIs.
3. Downsample each new source frame to the current character-grid resolution.
4. Calculate luminance with `0.2126R + 0.7152G + 0.0722B`.
5. Map luminance to a configurable character ramp such as ` .:-=+*#%@`.
6. Regenerate the grid when the image, viewport, detail, or character ramp changes.

Source-colored ASCII is quantized to a compact palette stored as rows in the glyph
atlas. Cells select a palette row through texture coordinates, preserving one material
per bounded geometry batch.

## Reactive Input

Reactivity is optional and controlled through configuration toggles. The native
`PointerTracker` polls global cursor position and observes mouse presses through a
`plasmashell` application event filter because desktop containment consumes events
before a wallpaper-local `MouseArea` can receive them.

```qml
MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.AllButtons

    onPositionChanged: renderer.movePointer(mouseX, mouseY)
    onPressed: renderer.clickPointer(mouseX, mouseY)
}
```

Plasma containment and desktop icons may consume pointer events before they
reach the wallpaper. Verify wallpaper-local hover and click delivery before
building the simulation around it. If events are unavailable, use a small native
helper or an appropriate KDE/global-pointer API instead of polling from QML.

## Displacement Simulation

Use a low-resolution simulation grid matching the ASCII grid. Start with a
scalar height field and derive visual displacement from its spatial gradient.
For each simulation step:

```
acceleration = left + right + up + down - 4 * current
velocity = (velocity + acceleration * tension) * damping
displacement += velocity
```

Mouse movement applies force based on pointer direction and speed within a
configurable radius. Clicks apply an outward radial impulse with distance-based
falloff. Rendering samples the source from displaced coordinates:

```
sampleX = cellX - displacementX
sampleY = cellY - displacementY
```

Pause simulation updates once total displacement energy falls below a small
threshold. Recompute only affected rows where practical.

## Configuration

- Source type: procedural or image
- Procedural mode
- Media file URL and stretch/fit/crop mode
- Reactive enabled
- Pointer movement enabled
- Click ripple enabled
- Effect radius
- Effect strength
- Tension and damping
- Character ramp
- Monochrome or source color
- Animation speed
- Numeric character size and adaptive color depth
- Maximum update rate
- Optional source colors and optional custom procedural color
- Reset-to-defaults action

## Performance Rules

- Preserve one native renderer item; never create one QML item per character or row.
- Downsample source images only when their input or grid dimensions change.
- Do not sample full-resolution images on every animation frame.
- Use a scalar displacement field before considering separate X/Y fields.
- Pause inactive simulations and stop updates while the wallpaper is hidden.
- Cache adaptive palette assignments outside displacement updates.
- Do not regenerate static media on procedural timer ticks.
- Keep geometry batches below 60,000 vertices for graphics-backend compatibility.
- Rebuild the native module with `./build-native.sh` after Qt ABI upgrades.

## Remaining Work

### Iteration Backlog

1. [x] Correct ripple geometry with a stable, cell-aspect-aware wave solver so effects remain circular with non-square glyph cells.
2. Profile CPU, memory, frame pacing, geometry rebuild time, and glyph counts across character sizes, color depths, frame rates, source types, and active/dormant displacement. Use the results to guide optimization rather than adding speculative complexity.
3. [x] Improve configuration UX by grouping source, appearance, animation, and reactivity settings; hide irrelevant controls; show numeric slider values; and validate user-entered paths and ramps.
4. [x] Expand visual customization with background color, ramp presets, tone controls, character spacing, color presets, and character-order reversal. Preserve the leading-space invariant and bounded atlas size.
5. Add reactive inputs such as PipeWire audio, CPU/memory/network activity, time-of-day transitions, and desktop activity only after profiling the existing renderer.
6. Verify lifecycle behavior across multiple monitors, hot-plugging, scale factors, lock/unlock, sleep/resume, hidden wallpapers, configuration previews, and Qt upgrades.
7. Add repeatable automated validation for native compilation, unresolved symbols, QML, XML, metadata, shell scripts, source sampling, and simulation math.
8. Improve distribution with screenshots, demos, tagged releases, KDE Store metadata, CI builds, and distribution-specific packages that respect the native Qt ABI.
