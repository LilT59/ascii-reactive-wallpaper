# Changelog

## Unreleased

### Added

- Matrix 3D mode with converging perspective lanes, four depth planes, curved parallax drift, depth-scaled glyph geometry, depth-dependent speed, and bright foreground heads.
- Matrix 3D heads now deposit persistent stationary glyphs that independently cycle and fade by age, preserving classic Matrix rain behavior at substantially lower CPU cost than per-cell projection.

### Fixed

- Matrix 3D no longer upscales glyphs beyond their atlas resolution or duplicates foreground glyphs into adjacent columns; distant layers shrink while foreground symbols remain at crisp native size.
- Matrix 3D immediately seeds complete trails after character-grid rebuilds, preventing blank output after horizontal spacing changes.

## 2.0.0 - 2026-07-12

### Added

- Transactional saved profiles for complete wallpaper configurations.
- Curated monospace font selection, foreground opacity, and a dedicated second-pass glow.
- Ordered image dithering and adjustable edge enhancement.
- Procedural pattern scale and intensity controls.
- Optional animation and reactivity pausing while running on battery power.
- Responsive inline procedural previews and low-power, balanced, and high-detail presets.
- Per-section reset actions and 250 ms source/appearance crossfades.
- Opt-in renderer timing diagnostics through `ASCII_WALLPAPER_PROFILE=1`.

### Changed

- Scene-graph batches and geometry buffers are reused between frames.
- Ripple simulation scratch grids are allocated only when grid dimensions change.
- Hidden, minimized, detached, and zero-sized renderers stop simulation work.
- Image paths can be cleared directly, custom ramps show validation feedback, and settings include performance guidance.
- Applying a saved profile now commits it immediately and restores the last active profile selection.

### Fixed

- Continuous slider changes no longer create temporary crossfade renderers.
- Preview glow no longer uses expensive per-glyph Canvas blur.
- Configuration controls respect narrow Plasma settings windows without breaking temporary component inspection.

## 1.1.0 - 2026-07-12

### Added

- Ocean waves procedural animation.
- Character-ramp presets for classic, blocks, compact, detailed, vertical blocks, Braille density, circles, and binary styles.
- Background color, brightness, contrast, gamma, horizontal spacing, character-order reversal, and color presets.
- Configurable wave speed and perceptual wave persistence controls.
- Clear Source, Appearance, Animation, Reactivity, and Defaults settings sections.

### Changed

- Ripple impulses, propagation, and displacement are aspect-correct for non-square character cells.
- Reactive simulation runs independently from the visual animation frame rate.
- Static-image brightness defaults to +0.05 for improved glyph density.
- Irrelevant source-specific controls are hidden, and sliders display their current values.

### Fixed

- Ramp presets now persist and apply reliably.
- Matrix and starfield zero-brightness backgrounds remain empty when tone adjustments are active.
- Finished ripples clear residual displacement so static images return to their undistorted mapping.
- Resetting defaults no longer slows reactive animation to the visual frame rate.

## 1.0.0 - 2026-07-11

- Initial release with six procedural modes, static image conversion, adaptive source colors, and pointer-reactive displacement.
