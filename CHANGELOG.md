# Changelog

## Unreleased

### FFI

- **BREAKING:** `watch` now employes the builder pattern:

  If you only watch a single value or don't need to use the `old` and `new`
  values in the watch callback, you can now use quantity-agnostic functions:

  ```gleam
  vue.watch_computed(first_name)
  |> vue.and_ref(last_name)
  |> vue.with_immediate(True)
  |> vue.with_listener(fn(_, _, _) {
    // this will fire on a change in `first_name` or `last_name`
    // old, new values are unavailable
  })

  // When watching a single value, new/old will be available
  vue.watch_computed(first_name)
  |> vue.with_immediate(True)
  |> vue.with_listener(fn(value, old_value, _) {
    // this will fire on a change in `first_name` or `last_name`
    // value, old_value, is a single-item tuple corresponding to the input
  })
  ```

  If you do need new/old and watch more than one, use a quantity-aware function:

  ```gleam
  vue.watch2(#(
    watch_computed(last_name),
    watch_ref(last_name),
  ))
  |> vue.with_immediate(True)
  |> vue.with_listener(fn(values, old_values, _) {
    // this will fire on a change in `first_name` or `last_name`
    // values, old_values, is a tuple corresponding to the input
  })
  ```

- Upgrade dependencies

### LSP

- Upgrade dependencies

### Vite Plugin

- Fix a bug where Gleam imports in a JavaScript file will use a different source
  than Gleam imports in Gleam code.
- Upgrade dependencies

## v0.6.1

### FFI

- Upgrade dependencies

### LSP

- Upgrade dependencies

### Vite Plugin

- Upgrade dependencies

## v0.6.0

### FFI

- Add `vue_router` Navigation Guards bindings

## v0.5.1

### LSP

- Fix incorrect line offset for some messages

### Vite Plugin

- Show Gleam build errors in the error overlay

## v0.5.0

### FFI

- Fix template unwrapping breaking for class methods

### LSP

- Enable go to definition
- Enable code actions
- Fix auto-completions
- Fix hover
- Fix incorrect line offset

### Vite Plugin

- Fix HMR

## v0.4.0

### FFI

- **BREAKING**: Refactor `with_n_props` to take the `Prop`s directly, rather than
  using a tuple.

  To migrate, simply remove the tuple:

  ```gleam
  // Before
  |> with_2_props(#(
    Prop("name", None),
    Prop("greeting", Some("Hello"))
  ))

  // After
  |> with_2_props(
    Prop("name", None),
    Prop("greeting", Some("Hello"))
  )
  ```

- **BREAKING**: Remove `NullableRef`, `NullableShallowRef` and `NullableComputed`
  in favor of unwrapping regular refs/computed for template usage.

  To migrate, convert to an option wrapped value. For example:

  ```gleam
    // Before
    let greeting = nullable_ref("Hello")
    let greet = fn(greeting: NullableRef(String)) {
      greeting
      |> vue.nullable_ref_value
      |> option.unwrap("Heya")
      |> io.debug
    }

    // After
    let greeting = ref(Some("Hello"))
    let greet = fn(greeting: Ref(Option(String))) {
      greeting
      |> vue.ref_value
      |> option.unwrap("Heya")
      |> io.debug
    }
  ```

  Also, make sure that nullable values crossing from Javascript are now wrapped
  in an `Option`.

- **BREAKING**: As part of the previous change, `Option` is now automatically
  unwrapped for templates even if nested in an object (1 level deep) Or returned
  by a function (recursively). If you've previosly handled `Option`s in the
  template, those will now be unwrapped.

- **BREAKING**: Add `with_n_nullable_props`. These functions allow you to define props that
  can be left intentionally `null` in the template, unlike current `with_n_props`
  that guarntees a either an entered value or a default.

  This caused the signature of the `setup` function to changed, please add `_`
  after your props argument to fix compilation.

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
