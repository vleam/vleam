# Changelog

## Unreleased

### FFI

- **BREAKING**: split `next_tick` to with/without callback for better ergonomics
- **BREAKING**: make props reactive using `computed`
- Add `inject` and `provide`
- Fix `nullable_value`
- Add `NullableComputed`

### Vite Plugin

- Add note to the readme about ignoring `vleam_generated`
- Upgrade dependencies
- Generate gleam files synchronously
- Do not add comments to generated file, for more predictable LSP usage

## v0.1.0

- Initial Release
