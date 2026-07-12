# Changelog

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
