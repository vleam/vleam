<p align="center">
  <img height="200" src="logo.png">
</p>

What's nicer, this TypeScript...

```typescript
BaseProps = {
  title: string;
}

SuccessProps = BaseProps & {
  variant: 'success';
  message: string;
  errorCode?: never;
}

ErrorProps = BaseProps & {
  variant: 'error';
  errorCode: string;
  message?: never;
}

type Props = SuccessProps | ErrorProps;
```

...or this Gleam?

```gleam
type NotificationProps {
  SuccessProps(title: String, message: String)
  ErrorProps(title: String, error_code: String)
}
```

# Vleam

**Incrementally incorporate Gleam in Vue projects to enjoy an enjoyable language**

Vleam (Vue + Gleam) is a set of tools allowing developers to _incrementally_
incorporate the Gleam programming language into their Vue projects.

Similarly to how Typescript helped with the large codebases of 2016, Gleam can
help with the large codebases of today. Most apps aren't going to be rewritten.
No reason why they shouldn't benefit from a better language, especially when
introduced slowly and incrementally, and particularly if it means less Typescript.

To learn more about how Gleam can do those things, visit [Gleam's language tour](https://tour.gleam.run)
if you haven't already.

Vleam consists of three parts:

1. A Vite plugin that:

- Allows the use of `<script lang="gleam">` in Vue SFCs
- Allows importing `.gleam` files in Javascript/Typescript.

2. A set of bindings to Vue's APIs.

3. An LSP that proxies messages between Gleam's LSP for functionality in SFCs.
   Plugins are availble for Neovim and VSCode.

## Prerequisites

1. A Vue 3 project using Vite
2. Working installation of [Gleam's CLI](https://gleam.run/getting-started/installing/)

## Setup

The following uses `pnpm` but `yarn` or `npm` should work as well.

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

```vue
<template>
  <div>{{ count }}</div>
  <button @click="() => increment()">Increment</button>
</template>

<script lang="gleam">
import gleam/option.{Some}
import vleam/vue.{type Component, Prop, define_component, setup, with_1_prop}

// THIS FUNCTION MUST EXIST
pub fn default_export() -> Component {
  define_component([], [], False)
  |> with_1_prop(#(Prop("initialCount", Some(0))))
  // Props are handed as Computed to stay reactive
  |> setup(fn(props: #(Computed(Int)), _, _) {
    let initial_count = props.0

    let count = initial_count |> vue.computed_value |> vue.ref

    let increment = fn() -> Int {
      let current_count = count |> vue.ref_value

      count |> vue.ref_set(current_count)

      current_count
    }

    // returning an Error will cause `setup` to throw it (don't do that)
    Ok(#(
      #("count", count),
      #("increment", increment),
    ))
  })
}
</script>
```

Note that a Gleam script block inside a Vue SFC, without exception, MUST declare
a public `default_export` function that returns a `Component`. The Vite plugin
assumes it exists and the build will fail without it.

For more information on Vue bindings in Gleam, see the reference at Hexdocs:

https://hexdocs.pm/vleam

### Automatic Unwrapping: Vleam's only "Gotcha"

Vleam takes inspiration from Gleam in its magic avoidance, only introducing it
when the alternative is too poor of a developer experience. The only such case
at the moment is null handling in templates.

Gleam doesn't have null. Therefore, every time a setup function returns an `Option`,
it will be unwrapped to the contained value if `Some`, or to `null` if `None`.

This unwrapping happens for:

1. A literal `Option`
2. Functions returning an `Option`, recursively
3. Records' fields which are an `Option`, non-recursively

Recursing records for the unwrapping of fields in arbitrary depths is not supported
due to performance considerations.

ALL THREE AFFECT ONLY VALUES RETURNED BY `setup`. If you have acquired an `Option`
through other means (e.g a global vue value or an event), it will not be unwrapped.
This is an unfortunate limitation of Vue.

Nullable values going from the template into Gleam code (via a function call) will
need to be converted into an `Option`. This can be done ergonomically with
`globalProperties`:

```ts
// define once in main.ts
import {
  Some,
  None,
} from "/build/dev/javascript/gleam_stdlib/gleam/option.mjs";

app.config.globalProperties.toOption = (nullable) =>
  nullable == null ? new None() : new Some(nullable);
```

Then, use in templates:

```vue
<button @click="signup(email, password, toOption(phoneNumber))">Sign Up</button>
```

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

- If the LSP glitches `<script lang="gleam">`, resave the file. Also try
  formatting the gleam code then save.

- If something doesn't work and you're not sure why, check the browser console
  for errors, and scroll up the terminal to see if any error slipped by.

### Limitations

#### HMR

Due to the way HMR works, `instanceof` may break if a new version of the class
is reloaded after objects were instantiated with its previous version. A full
refresh is required in such cases.

Due to Gleam's heavy reliance on `instanceof`, please make sure you refresh on
any dependency change. If this arises frequently with your own code, it's best
to configure Vite to refresh on every change.

HMR will otherwise work as expected, enjoy!

#### `toRefs`, `reactive` support

`toRefs` and `reactive` are not easy to translate into Gleam. Research required.

#### TypeScript type checks

In some configurations, TypeScript may try to analyze `Vue` files with a `gleam`
block. This should be solved as part of [vuejs/language-tools#4433](https://github.com/vuejs/language-tools/issues/4433).

### Sponsored by Nestful

<a href="https://nestful.app">
  <p align="center">
    <img src="nestful.png">
  </p>
</a>

Vleam is developed for and sponsored by [Nestful](https://nestful.app), the best
app there is to manage your own time.

### Thanks & Acknowledgements

- [Enderchief/gleam-tools](gleam-tools/vite-gleam)
