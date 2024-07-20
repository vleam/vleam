# Changelog

## v0.3.1

### Vite Plugin

- Fix path of generated Gleam files

## v0.3.0

### Vite Plugin

- Transform `.gleam` in house. Solves `vite-gleam` race conditions

## v0.2.0

### General

- Add a `prepare` lifecycle script to `package.json`

### FFI

- **BREAKING**: split `next_tick` to with/without callback for better ergonomics
- **BREAKING**: make props reactive using `computed`
- Add `inject` and `provide`
- Fix `nullable_value`
- Add `NullableComputed`
- Add labels to `define_component`'s arguments
- Add initial `vue-router` FFI

### Vite Plugin

- Add note to the readme about ignoring `vleam_generated`
- Upgrade dependencies
- Generate gleam files synchronously
- Do not add comments to generated file, for more predictable LSP usage

## v0.1.0

- Initial Release
