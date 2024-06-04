<p align="center">
  <img src="logo.png">
</p>

### **THIS IS EXPERIMENTAL SOFTWARE**.

It can be used in production, but may cause headaches to the developer.

# Vleam

**Incrementally incorporate Gleam in Vue projects**

Vleam (Vue + gLEAM) is a set of tools allowing developers to _incrementally_
incorporate the Gleam programming language into their Vue projects.

Similarly to how Typescript helped Javascript handle what considered a large
application in 2016, Gleam can help with what's considered large today. Many
apps already exists that are not going to be rewritten. No reason why they
shouldn't benefit from useful innovations, especially when they can be
introduced slowly and incrementally, and particularly if it means less Typescript.

Vleam consists of the following parts:

1. A Vite plugin that:

- Allows the use of `<script lang="gleam">` in Vue's SFC
- Allows improting `.gleam` files in Javascript/Typescript.

2. A set of bindings to Vue's APIs.

3. An LSP that proxies messages between Gleam's LSP for functionality in SFCs.
   Plugins are availble for Neovim and VSCode.

## Prerequisites

1. A Vue 3 project using Vite
2. Working installation of [Gleam's CLI](https://gleam.run/getting-started/installing/)

## Setup

The following examples use `pnpm` but `yarn` or `npm` should work as well.

First, setup a Gleam project in your Vue project's root by using `gleam new` or
by manually creating a `gleam.toml` file. Make sure you set `target = "javascript"`.

Then, install Vleam:

```shell
pnpm add -D vleam
gleam add vleam
```

And add it as the **first** plugin in `vite.config.ts`:

```ts
import { vitePluginVueVleam } from "vleam";

export default defineConfig({
  // ... rest of your config ...
  plugins: [
    // Vleam first
    vitePluginVueVleam(),
    // Then the rest
    vue(),
    // ... rest of your plugins ...
  ],
});
```

Add `src/vleam_generated` to `.gitignore`.

For Neovim support, install [vleam.nvim](https://github.com/vleam/vleam.nvim).

For VSCode support, install the [vleam plugin](https://github.com/vleam/vscode-vleam).

If you'd like to get type information for Gleam code imported in Typescript,
install `ts-gleam` as well:

```shell
pnpm add -D ts-gleam
```

and make sure `gleam.toml` has Typescript declarations configured:

```toml
[javascript]
typescript_declarations = true
```

That's it!

### Usage

To use Gleam code in TS or JS files, simply import as usual:

```ts
// this imports the function `new_todo` from `models.gleam`
import { new_todo } from "../vleam_todo/models.gleam";
```

In Vue SFCs, you can use Gleam like so:

```gleam
// this code is inside <script lang="gleam"> </script>
import gleam/option.{Some}
import vleam/vue.{type Component, Prop, define_component, setup, with_1_prop}

// THIS FUNCTION MUST EXIST
pub fn default_export() -> Component {
  define_component([], [], False)
  |> with_1_prop(#(Prop("initialCount", Some(0))))
  // Props are handed as Computed to stay reactive
  |> setup(fn(props: #(Computed(Int)), _) {
    let initial_count = props.0

    let counter =
      initial_count
      |> vue.computed_value
      |> vue.ref

    let increment = fn() -> Int {
      let current_count =
        counter
        |> vue.ref_value

      counter
      |> vue.ref_set(current_count)

      current_count
    }

    // returning an Error will cause `setup` to throw it
    Ok(#(
      #("counter", counter),
      #("increment", increment),
    ))
  })
}
```

Note that a Gleam script block inside a Vue SFC, without exception, MUST declare
a public `default_export` function that returns a `Component`. The Vite plugin
assumes it exists and the build will fail without it.

For more information on Vue bindings in Gleam, see the reference at Hexdocs:

https://hexdocs.pm/vleam

### Tips

- Use absolute paths with Gleam `@external`. Vite will resolve them relative
  to its root:

```gleam
// Easy
@external(javascript, "/src/composables/useTodoInputEvent", "useTodoInputEvent")
fn use_todo_input_event(event: InputEvent) -> Result(Todo, TodoError)

// Pain
@external(javascript, "../../../../composables/useTodoInputEvent", "useTodoInputEvent")
fn use_todo_input_event(event: InputEvent) -> Result(Todo, TodoError)
```

- If the LSP glitches inside `<script lang="gleam">`, resave the file. Also try
  formatting the gleam code then save.

- Vleam is experimental. Vite may output errors even when things are fine. Try
  navigating to your Vue app in development mode and read the errors in the
  browser console for more information.

### Limitations

#### HMR

HMR will trigger a full refresh until [gleam-lang/gleam#3178](https://github.com/gleam-lang/gleam/issues/3178) is fixed.

#### `toRefs`, `reactive` support

`toRefs` and `reactive` are not easy to translate into Gleam. Research required.

### Sponsored by Nestful

<p align="center">
  <img src="nestful.png">
</p>

Vleam is developed for and sponsored by Nestful.

### Thanks & Acknowledgements

- [Enderchief/gleam-tools](gleam-tools/vite-gleam)
