# This Example is WIP and not yet functional

Yet it can be helpful to read its code

# Vleam Todo

## The Vue + Gleam Example Todo App

### Brief

This is a small sample application that demonstrates Vleam capabilities in
integrating Gleam into existing Vue 3 projects.

Some choices may seem strange, for example some Gleam code should be in a separate
file, but is put inside a compenent instead. Or a component code should keep
using Typescript, but is written in Gleam.

The code here is meant as a showcase, so it obsessively uses Gleam everywhere,
even if may not make sense.

In reality, use features as need rises.

### Using Vleam in your own Vue projects

For more information on incorporating Gleam into existing Vue project, see:

https://github.com/vleam/vleam

### Running this example

```sh
pnpm install
gleam update
```

### Compile and Hot-Reload for Development

```sh
pnpm dev
```

### Type-Check, Compile and Minify for Production

```sh
pnpm build
```
