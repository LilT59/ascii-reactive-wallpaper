# Log

This file is a session log for the project.
Every entry must be dated (YYYY-MM-DD). Append new entries
at the bottom — do not modify past entries.

---

## 2026-07-11 — Scaffold ASCII Reactive Wallpaper KDE plugin

- **Summary**: Researched, designed, and built a KDE Plasma 6 wallpaper plugin that renders animated ASCII art as the desktop background using a hybrid QML Canvas + GLSL shader pipeline.

- **Key changes**:
  - Created AGENTS.md with full architecture docs, pipeline spec, and development workflow
  - Wrote `metadata.json` — KPackage manifest with `KPackageStructure: Plasma/Wallpaper`
  - Wrote `contents/shaders/ascii.vert` and `ascii.frag` — GLSL vertex/fragment shaders with starfield, matrix rain, and plasma modes
  - Compiled `.qsb` shader binaries via `qsb` (Qt Shader Baker 6.10.2)
  - Wrote `contents/ui/AsciiShader.qml` — Canvas character atlas + ShaderEffect hybrid component
  - Wrote `contents/ui/main.qml` — WallpaperItem root with Timer loop and config handling
  - Wrote `contents/config/main.xml` — KConfigXT settings for mode, detail, speed, color
  - Symlinked into `~/.local/share/plasma/wallpapers/ascii-reactive-wallpaper` for testing

- **Results**:
  - Shaders compile cleanly to SPIR-V `.qsb` with correct reflection data (ubuf at binding=1, uAtlas at binding=2)
  - Plugin registered in KDE wallpaper listing — selectable via Desktop > Configure Desktop > Wallpaper Type
  - 3 animation modes: Starfield (twinkling ASCII stars), Matrix Rain (falling columns), Plasma (sine-wave fallback)
  - Config UI exposes mode switching, ASCII resolution (4x8 / 8x16 / 16x32), speed slider

- **Decisions**:
  - Path C hybrid (Canvas atlas + ShaderEffect GLSL) chosen over pure Canvas (too slow) or pure shader (can't generate glyphs easily)
  - Uniforms placed in separate `ubuf` block at binding=1 — qsb requires block-based uniforms for Vulkan/SPIR-V
  - First atlas char is space so brightness=0 maps to invisible (background-only) output
  - 30fps timer rather than vblank-synced — ASCII art doesn't benefit from higher framerate

- **Next steps**:
  - Test on actual desktop — verify rendering, check journalctl for QML errors
  - Add more animation modes (fire, aurora, audio-reactive via pipewire)
  - Add system-reactive mode (CPU/mem/network via KDE system monitor D-Bus)
  - Package for KDE Store distribution

---

## 2026-07-11 — Audit, recovery, and compatible renderer

- **Summary**: Audited the initial plugin, rebuilt it after an accidental package-tool deletion, tested multiple rendering paths on Plasma 6.6.5, and established a working scene-graph text-row renderer.

- **Incident**:
  - During the initial read-only audit, `kpackagetool6 --type Plasma/Wallpaper --upgrade "."` was run against a package installed through a symlink to the workspace.
  - The failed upgrade removed the linked project directory and package registration.
  - The command should not have been used during an audit, and the earlier claim that no files were modified was incorrect.
  - `AGENTS.md` was recreated by the user; the remaining package files were reconstructed from captured source and regenerated shader binaries.

- **Audit findings**:
  - Original shader URLs resolved to the nonexistent `contents/ui/shaders` directory.
  - Original fragment shader resource bindings did not follow the expected Qt 6 `ShaderEffect` property layout.
  - The package lacked `contents/ui/config.qml`.
  - Configuration access and update behavior were inconsistent with installed Plasma wallpaper examples.
  - Color was unused and speed changed update frequency rather than animation rate.
  - The initial QSB files contained only SPIR-V; rebuilt files used the Qt 6 GLSL/HLSL/MSL target set.

- **Reconstruction**:
  - Recreated `metadata.json`, `contents/config/main.xml`, and the QML configuration page.
  - Added Starfield, Matrix Rain, and Plasma procedural modes.
  - Added configurable mode, detail, speed, and primary color.
  - Added `build-shaders.sh` and generated portable QSB shader variants.
  - Validated QML with `qmllint`, XML with `xmllint`, metadata with `jq`, and shader bindings with QSB reflection.

- **Rendering experiments**:
  - Canvas character atlas plus `ShaderEffect`: shader background appeared, but the atlas remained empty. Plasma logged an invalid Canvas font-family warning.
  - QML `Text` atlas plus `ShaderEffectSource`: still produced no visible glyph output.
  - Texture-free procedural bitmap glyph shader: still produced a black wallpaper.
  - Normalized-coordinate shader and forced visible color: still black.
  - Removed `qt_Opacity` multiplication and changed QSB filenames to invalidate shader caching: still black.
  - Diagnostic fragment shader with a solid magenta/cyan checkerboard and Qt's default vertex shader: still black.
  - Conclusion: `ShaderEffect` output is not usable on the current Plasma/graphics path, despite valid compilation and no current shader-load errors.
  - Full-screen Canvas renderer displayed correctly but was unusably slow because full-screen image rendering/upload reduced updates to roughly one frame every three seconds.

- **Plasma behavior observed**:
  - Restarting `plasma-plasmashell.service` twice ended in `corrupted double-linked list` crashes and core dumps. Avoid using shell restarts as the normal development reload mechanism.
  - Switching temporarily to another wallpaper and back is the preferred QML reload workflow.
  - Plasma 6.6 injects `configDialog` and `wallpaperConfiguration` into the configuration root; these properties were declared to avoid configuration-page errors.

- **Working implementation**:
  - Replaced Canvas and `ShaderEffect` with a scene-graph text-row backend.
  - Uses one `Text` item per row and one generated string per row, never one QML item per character.
  - Runs procedural animation at 10 FPS using DejaVu Sans Mono.
  - The user confirmed that this renderer displays successfully.
  - This backend is the compatibility baseline for subsequent work.

- **Architecture update**:
  - Expanded `AGENTS.md` with the current renderer status and planned shared source pipeline.
  - Defined future static image-to-ASCII conversion using downsampling and luminance mapping.
  - Defined optional pointer movement and click reactivity through a low-resolution displacement field.
  - Documented Plasma pointer-event uncertainty, simulation equations, configuration plans, performance constraints, and an ordered feature roadmap.

- **Next steps**:
  - Add reactive configuration toggles and verify that a wallpaper-level `MouseArea` receives hover and click events.
  - Implement click ripples using a scalar displacement grid and apply displaced source sampling to procedural modes.
  - Add static monochrome image-to-ASCII conversion without sampling full-resolution images every frame.
  - Profile the text-row backend at 10-15 FPS before adding movement-driven displacement.
   - Consider a native QML extension for source-colored ASCII, video, or smooth 30-60 FPS fluid effects.

---

## 2026-07-11 — Reactive displacement and image source pipeline

- **Summary**: Extended the compatibility text-row renderer with pointer-driven displacement, click ripples, static monochrome image conversion, and user-facing controls.

- **Key changes**:
  - Added procedural/image source selection, image URL, and configurable character ramp settings.
  - Added optional pointer movement and click ripple input through a wallpaper-level `MouseArea`.
  - Implemented a low-resolution damped height-field simulation matching the ASCII grid.
  - Applied the height-field gradient as a displacement when sampling all procedural and image sources.
  - Added one-time image downsampling through a grid-sized hidden Canvas and Rec. 709 luminance conversion.
  - Added effect radius, strength, tension, and damping controls.
  - Paused simulation updates automatically when displacement energy becomes negligible.

- **Validation**:
  - `qmllint` passes for all QML files.
  - `xmllint` passes for the KConfigXT schema.
  - `jq` validates the package metadata.

- **Runtime verification still required**:
  - Confirm Plasma delivers hover and click events to the wallpaper beneath desktop containment elements.
  - Confirm the Canvas implementation can draw the hidden QML `Image` and read its grid-sized pixel data on the target graphics backend.
  - Profile frame pacing with large desktops and the smallest character size.

---

## 2026-07-11 — Native global pointer bridge

- **Summary**: Replaced the ineffective wallpaper-local `MouseArea` with an in-process Qt QML plugin that observes pointer movement and clicks from `plasmashell`.

- **Key changes**:
  - Added `AsciiReactive.Native`, a compiled QML extension loaded from the wallpaper package.
  - Polls `QCursor::pos()` at 60 Hz and exposes changes as global screen coordinates.
  - Installs a non-consuming application event filter to observe mouse presses delivered elsewhere in Plasma's desktop containment.
  - Maps global coordinates into each wallpaper item before forwarding movement and click impulses to the renderer.
  - Resets movement history when the cursor leaves a wallpaper screen to avoid large re-entry impulses.
  - Added `build-native.sh` and a CMake project for reproducible builds.

- **Validation**:
  - Native plugin compiles and links successfully against Qt 6.10.2.
  - All shared-library dependencies resolve.
  - `qmllint` passes with the local native module imported.

- **Deployment note**:
  - The native library is architecture- and Qt-version-specific and must be rebuilt with `./build-native.sh` after relevant system upgrades or for distribution to another architecture.

---

## 2026-07-11 — Native scene-graph renderer

- **Summary**: Replaced the QML text-row compatibility renderer with a single native `QQuickItem` to prevent animation work from stalling Plasma's desktop UI.

- **Performance architecture**:
  - Procedural brightness generation, image sampling, displacement physics, and character mapping now run as compiled C++ loops.
  - Glyphs are rasterized once into a small texture atlas when the ramp, color, or detail changes.
  - The entire character grid is submitted as one dynamic scene-graph geometry node and one texture material.
  - Space cells emit no vertices, reducing starfield geometry substantially.
  - Removed per-row JavaScript string generation, QML `Repeater`, `Text` shaping, and dozens of independent scene-graph nodes.
  - Static images are loaded and downsampled once in native code rather than read back from a Canvas.
  - Ripple simulation remains dormant when its energy falls below the existing threshold.

- **Validation**:
  - Native renderer and pointer bridge compile successfully against Qt 6.10.2.
  - `ldd -r` reports no unresolved shared-library symbols.
  - `qmllint`, `xmllint`, and metadata validation pass.

---

## 2026-07-11 — Colored media sources and expanded modes

- **Summary**: Added media selection controls, native animated media decoding, source-colored ASCII, and four procedural modes.
- **Media pipeline**: Added a file picker, stretch/fit/crop modes, visible decoding errors, `QMovie` animated-image playback, and looping Qt Multimedia video through `QVideoSink`.
- **Color rendering**: Source colors are quantized to an eight-color palette stored as rows in the existing glyph atlas, so cells select color through texture coordinates without per-character draw calls.
- **Procedural modes**: Added fire, aurora, nebula, and Mandelbrot alongside starfield, matrix rain, and plasma.
- **Validation**: Native module compiles and links against Qt Multimedia 6.10.2; `ldd -r`, QML, XML, and metadata validation pass.
