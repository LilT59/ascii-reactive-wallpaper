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
- **Detail** — ASCII resolution (low/medium/high = char size 4/8/16px)
- **Color** — Primary color / palette
- **Speed** — Animation speed multiplier

These are exposed as `wallpaper.configuration.*` properties in QML.

Current configuration uses an explicit numeric character height (8-48 px) and adaptive
source color depth (4-64 colors). Procedural animations keep curated mode colors by
default; users can override them with the selected primary color. Source media can use
its adaptive palette independently. The configuration page includes a reset-to-defaults
button, and defaults must remain synchronized with `contents/config/main.xml`.
Animation rate is configurable from 5-60 FPS with a 24 FPS default. Displacement physics
is capped at 30 FPS, and static images do not rebuild merely because the clock advances.

### contents/ui/main.qml
Root component extending `WallpaperItem`:
- Creates the `AsciiShader` child
- Runs a `Timer` at configurable FPS (~30fps) that advances the animation time
- Handles configuration changes (mode, detail, color)
- Cleans up on destruction

### native/asciirenderer.cpp
The active rendering core. Procedural generation, image downsampling, displacement,
and character mapping run in C++. Glyphs are cached in a small atlas and emitted as
textured quads in batches below backend vertex limits. Never add one QML item per cell.

### native/pointertracker.cpp
An in-process singleton that polls the global cursor and observes mouse presses through
a `plasmashell` application event filter. QML maps global coordinates to each wallpaper.

### contents/shaders/ascii.vert
Standard pass-through vertex shader. Only receives `qt_Matrix` and `qt_Opacity` in the std140 `buf` block.

### contents/shaders/ascii.frag
The procedural animation engine. Standalone uniforms (mapped from QML properties by name):
- `iTime` — animation time in seconds (float)
- `iResolution` — viewport size (vec2)
- `iCharSize` — character cell size `(charWidth, charHeight)` (vec2)
- `iNumChars` — number of characters in atlas (float)
- `iMode` — animation mode selector (float, 0=starfield, 1=matrix)
- `uAtlas` — character atlas texture (sampler2D, binding=1)

#### Modes

**Mode 0 — Starfield (default)**
- Each character cell has a ~3% probability of containing a star
- Stars twinkle using cell-hash-seeded sine wave offset by time
- Brightness determines character density (space → . → : → r → # → @)
- Color: cyan-white stars on near-black background
- Hash-based seeding means stars are deterministic per position but pseudo-random

**Mode 1 — Matrix Rain**
- Each column is an independent "rain drop" with pseudo-random speed and offset
- Lead character is bright, trail fades out
- Characters cycle (though we approximate by brightness mapping)
- Color: classic matrix green on black

**Implemented additional modes**:
- Plasma, fire, aurora, and nebula

**Future modes** (design space):
- Audio-reactive — needs pipewire/pulse audio hook via D-Bus → shader uniform
- System-reactive — CPU/mem/network via KDE system monitor daemon → shader uniform

#### Shader Pipeline (per-fragment)
```
fragCoord = uv * iResolution
cell = floor(fragCoord / iCharSize)
offset = fract(fragCoord / iCharSize)
brightness = proceduralFunction(cell, iTime, iMode, ...)
charIdx = floor(brightness * (iNumChars - 1))
atlasU = (charIdx + offset.x) / iNumChars
atlasV = offset.y
charTexel = texture(uAtlas, vec2(atlasU, atlasV))
finalColor = mix(bgColor, fgColor, charTexel.r)
```

## Shader Compilation

Shaders are written as GLSL source files and compiled to SPIR-V `.qsb` format using `qsb` (Qt Shader Baker):

```bash
/usr/lib/qt6/bin/qsb ascii.vert -o ascii.vert.qsb
/usr/lib/qt6/bin/qsb ascii.frag -o ascii.frag.qsb
```

The `.qsb` files are shipped with the plugin. Source GLSL is also included for maintainability.

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
ln -sf $PWD ~/.local/share/plasma/wallpapers/ascii-reactive-wallpaper

# Uninstall
rm ~/.local/share/plasma/wallpapers/ascii-reactive-wallpaper

# Rebuild shaders after editing
/usr/lib/qt6/bin/qsb contents/shaders/ascii.vert -o contents/shaders/ascii.vert.qsb
/usr/lib/qt6/bin/qsb contents/shaders/ascii.frag -o contents/shaders/ascii.frag.qsb

# Check for Qt Quick errors (after switching wallpaper)
journalctl -f -o cat | grep -i --line-buffered "qml\|shader\|wallpaper\|ascii"
```

## Pitfalls / Known Issues

- **ShaderEffect in Qt 6 uses `.qsb` compiled shaders only** — no inline GLSL strings. Every shader change needs recompilation with `qsb`.
- **Uniforms must be declared outside the `buf` block** in the fragment shader. The `buf` block (binding=0) only contains `qt_Matrix` and `qt_Opacity`. Qt 6 ShaderEffect maps QML properties to standalone uniforms by name.
- **Canvas atlas dimensions depend on `charWidth * 2` per slot**, not `charWidth`. This gives enough room for wide characters like `@` and `W` in monospace fonts.
- **Timer vs vblank** — QML Timer is not synced to display vsync. For smooth animation we use ~30fps (33ms). Going above 60fps is wasteful for ASCII art.
- **The first character in `asciiChars` should be a space** — this ensures brightness=0 maps to an invisible character (background only).
- **std140 layout** — when adding new uniforms to the shader, remember float→vec2 has 8-byte alignment. Use padding fields if needed.

## Quality Checklist

- [ ] Plugin shows up in Wallpaper Type dropdown after install
- [ ] Starfield mode renders animated twinkling stars as ASCII characters
- [ ] Matrix rain mode renders falling character columns
- [ ] Mode switching works without visual artifacts
- [ ] Detail setting correctly changes character resolution
- [ ] Atlas regenerates when detail changes
- [ ] No QML warnings in journalctl
- [ ] No performance stutter (stable ~30fps on integrated GPU)
- [ ] Clean uninstall removes all plugin files

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
Render text rows
```

Supported sources:

- Static images with stretch, fit, and crop modes
- Animated images through `QMovie`
- Looping video through Qt Multimedia and `QVideoSink`
- Starfield
- Matrix rain
- Plasma/noise
- Future audio or system-monitor sources

Each logical cell may contain brightness, a quantized foreground color, and scalar
height/velocity values. Rendering derives X/Y displacement from the height gradient.

## Image-to-ASCII Mode

Image rendering should follow these steps:

1. Select a local image or video with the configuration file dialog.
2. Decode still/animated images with Qt image APIs or video with Qt Multimedia.
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

## Planned Configuration

- Source type: procedural or image
- Procedural mode
- Image file URL
- Reactive enabled
- Pointer movement enabled
- Click ripple enabled
- Effect radius
- Effect strength
- Tension and damping
- Character ramp
- Monochrome or source color
- Animation speed
- Grid detail
- Maximum update rate

## Performance Rules

- Keep the text-row compatibility renderer around 10-15 FPS.
- Preserve one native renderer item; never create one QML item per character or row.
- Downsample source images only when their input or grid dimensions change.
- Do not sample full-resolution images on every animation frame.
- Use a scalar displacement field before considering separate X/Y fields.
- Pause inactive simulations and stop updates while the wallpaper is hidden.
- Profile before adding source-colored text or video.
- Keep geometry batches below 60,000 vertices for graphics-backend compatibility.
- Rebuild the native module with `./build-native.sh` after Qt ABI upgrades.

## Reactive Feature Roadmap

1. Add reactive configuration toggles and pointer tracking.
2. Verify hover and click events reach the wallpaper on Plasma.
3. Implement click ripples with a scalar displacement grid.
4. Apply displacement to procedural source sampling.
5. Add static monochrome image-to-ASCII conversion.
6. Add movement-driven directional displacement.
7. Profile CPU, memory, and frame pacing on integrated graphics.
8. Decide whether simulation or image sampling needs a native helper.
9. Add source-colored ASCII only after the monochrome path is stable.
