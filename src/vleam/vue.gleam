import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option, None, Some}

pub type VueError {
  ComponentNotFound
}

/// A Vue App
pub type App

/// A Vue Component
pub type Component

/// A vue directive
pub type Directive

/// Returns components that were registered using `app.component`
@external(javascript, "../ffi.mjs", "getRegisteredComponent")
pub fn get_component(
  vue_app: App,
  component_name: String,
) -> Result(Component, VueError)

/// Registers components using `app.component`
@external(javascript, "../ffi.mjs", "registerComponent")
pub fn register_component(
  vue_app: App,
  component_name: String,
  component: Component,
) -> App

// General

/// vue.nextTick()
/// https://vuejs.org/api/general.html#nexttick
@external(javascript, "vue", "nextTick")
pub fn next_tick() -> Promise(Nil)

@external(javascript, "vue", "nextTick")
pub fn next_tick_action(callback: fn() -> Nil) -> Promise(Nil)

// Setup

/// An incomplete component representation piped during component definition.
/// See `define_component` for a full example.
pub type ComponentBase(required_props, nullable_props, emits)

/// Convenience function to make `Prop` definitions more readable
///
/// ```gleam
/// Prop("name", with_default("John Sumisu"))
/// ```
pub fn with_default(default: default) -> Option(default) {
  Some(default)
}

/// Convenience function to make `Prop` definitions more readable
///
/// ```gleam
/// Prop("name", required())
/// ```
pub fn required() -> Option(default) {
  None
}

/// Prop record to be used on component definition.
/// See `define_component` for a full example.
pub type Prop(value) {
  Prop(name: String, default: Option(value))
}

/// NullableProp record to be used on component definition.
/// See `define_component` for a full example.
pub type NullableProp(value) {
  NullableProp(name: String)
}

/// Entrypoint for component definition. optionally piped to a
/// `with_n_props` and/or `with_n_nullable_props` and/or `with_emits`
/// functions, and must be finally piped to `setup`.
///
/// `components` is a list of #(component_name, fn() -> Component) tuples. There
/// are three possible ways to gain access to components:
///
/// 1. Using `@external` to refer to a component defined in Javascript
/// 2. Importing a component defined in Gleam using this library
/// 3. Using them without the need to refer them in `define_component`, either
///    by gloabl definition with `vue.component` or by an auto-import mechanism
///    similar to Nuxt's
///
/// `directives` is a list of #(directive_name, fn() -> Directive) tuples.
///
/// `inherit_attrs` is a boolean, identical to Vue's javascript configuration.
///
/// ## Example
///
/// ```gleam
/// import gleam/option.{None, Some}
/// import gleam/string
/// import vleam/vue.{
///   type Component, NullableProp, Prop, define_component, setup,
///   with_1_nullable_prop, with_1_prop,
/// }
/// 
/// import vleam_todo/models.{type Todo, type TodoError}
/// 
/// type InputEvent
/// 
/// // Import the default export from HelloWorld.vue
/// // This is technically an incorrect type, but it'll work. C'est la vie.
/// @external(javascript, "/src/components/HelloWorld.vue", "default")
/// fn hello_world_component() -> Component
/// 
/// // Also works for external packages, although @ sign has to be aliased
/// @external(javascript, "heroicons/vue/24/solid", "UserIcon")
/// fn user_icon() -> Component
/// 
/// // or you can predefine in TS/JS
/// @external(javascript, "/src/ffi.ts", "CheckIcon")
/// fn check_icon() -> #(String, fn() -> Component)
/// 
/// pub fn default_export() -> Component {
///   define_component(
///     [
///       #("HelloWorld", hello_world_component),
///       #("UserIcon", user_icon),
///       check_icon(),
///     ],
///     [],
///     False,
///   )
///   |> with_1_prop(
///     Prop("initialName", vue.required()),
///   )
///   |> with_1_nullable_prop(
///     Prop("greeting", vue.with_default("Hello, ")),
///   )
///   // Props are handed as Computed for reactivity. It's best practice to
///   // always type them, as types aren't always inferred.
///   |> setup(fn(
///     required_props: #(Computed(String)),
///     nullable_props: #(Computed(String)),
///     _
///   ) {
///     let initial_name = props.0
///     let greeting = props.1
///
///     // Errors return from `setup` are thrown. This is just a demo, don't
///     // throw on bad input, only on irrecoverable errors (which generally
///     // should never occur in `setup` function)
///     use <- bool.guard(
///       {
///         greeting
///         |> vue.computed_value
///         |> string.length
///       }
///       > 0,
///       Error("Empty greeting"),
///     )
///
///     let change_count = vue.shallow_ref(0)
///     let increment_count = fn() {
///       change_count
///       |> vue.shallow_ref_set(vue.shallow_ref_value(change_count) + 1)
///     }
///
///     let name =
///       initial_name
///       |> vue.computed_value
///       |> vue.shallow_ref
///
///     let change_name = fn(new_name) {
///       name
///       |> vue.shallow_ref_set(new_name)
///     }
///     let full_greeting =
///       vue.computed(fn() {
///         name
///         |> vue.shallow_ref_value
///         |> string.append(
///           greeting
///           |> vue.computed_value
///         )
/// 
///         increment_count()
///       })
///
///     // To return values to the template, the FFI expects an Ok() with a
///     // tuple of object entries. The following is identical to Vue's:
///     //
///     // return {
///     //   fullGreeting: full_greeting,
///     //   changeName: change_name,
///     //   changeCount: change_count,
///     // };
///     Ok(#(
///       #("fullGreeting", full_greeting),
///       #("changeName", change_name),
///       #("changeCount", change_count),
///     ))
///   })
/// }
/// ```
@external(javascript, "../ffi.mjs", "defineComponent")
pub fn define_component(
  components components: List(#(String, fn() -> Component)),
  directives directives: List(#(String, fn() -> Directive)),
  inherit_attrs inherit_attrs: Bool,
) -> ComponentBase(Nil, Nil, Nil)

/// Define 1 prop on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_1_prop(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: Prop(p1),
) -> ComponentBase(#(Computed(p1)), nullable_props, emits)

/// Define 1 nullable prop on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_1_nullable_prop(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: NullableProp(p1),
) -> ComponentBase(required_props, #(Computed(Option(p1))), emits)

/// Define 2 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_2_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: Prop(p1),
  prop_2: Prop(p2),
) -> ComponentBase(#(Computed(p1), Computed(p2)), nullable_props, emits)

/// Define 2 nullable props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_2_nullable_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: NullableProp(p1),
  prop_2: NullableProp(p2),
) -> ComponentBase(
  required_props,
  #(Computed(Option(p1)), Computed(Option(p2))),
  emits,
)

/// Define 3 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_3_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: Prop(p1),
  prop_2: Prop(p2),
  prop_3: Prop(p3),
) -> ComponentBase(
  #(Computed(p1), Computed(p2), Computed(p3)),
  nullable_props,
  emits,
)

/// Define 3 nullable props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_3_nullable_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: NullableProp(p1),
  prop_2: NullableProp(p2),
  prop_3: NullableProp(p3),
) -> ComponentBase(
  required_props,
  #(Computed(Option(p1)), Computed(Option(p2)), Computed(Option(p3))),
  emits,
)

/// Define 4 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_4_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: Prop(p1),
  prop_2: Prop(p2),
  prop_3: Prop(p3),
  prop_4: Prop(p4),
) -> ComponentBase(
  #(Computed(p1), Computed(p2), Computed(p3), Computed(p4)),
  nullable_props,
  emits,
)

/// Define 4 nullable props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_4_nullable_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: NullableProp(p1),
  prop_2: NullableProp(p2),
  prop_3: NullableProp(p3),
  prop_4: NullableProp(p4),
) -> ComponentBase(
  required_props,
  #(
    Computed(Option(p1)),
    Computed(Option(p2)),
    Computed(Option(p3)),
    Computed(Option(p4)),
  ),
  emits,
)

/// Define 5 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_5_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: Prop(p1),
  prop_2: Prop(p2),
  prop_3: Prop(p3),
  prop_4: Prop(p4),
  prop_5: Prop(p5),
) -> ComponentBase(
  #(Computed(p1), Computed(p2), Computed(p3), Computed(p4), Computed(p5)),
  nullable_props,
  emits,
)

/// Define 5 nullable props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_5_nullable_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: NullableProp(p1),
  prop_2: NullableProp(p2),
  prop_3: NullableProp(p3),
  prop_4: NullableProp(p4),
  prop_5: NullableProp(p5),
) -> ComponentBase(
  required_props,
  #(
    Computed(Option(p1)),
    Computed(Option(p2)),
    Computed(Option(p3)),
    Computed(Option(p4)),
    Computed(Option(p5)),
  ),
  emits,
)

/// Define 6 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_6_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: Prop(p1),
  prop_2: Prop(p2),
  prop_3: Prop(p3),
  prop_4: Prop(p4),
  prop_5: Prop(p5),
  prop_6: Prop(p6),
) -> ComponentBase(
  #(
    Computed(p1),
    Computed(p2),
    Computed(p3),
    Computed(p4),
    Computed(p5),
    Computed(p6),
  ),
  nullable_props,
  emits,
)

/// Define 6 nullable props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_6_nullable_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: NullableProp(p1),
  prop_2: NullableProp(p2),
  prop_3: NullableProp(p3),
  prop_4: NullableProp(p4),
  prop_5: NullableProp(p5),
  prop_6: NullableProp(p6),
) -> ComponentBase(
  required_props,
  #(
    Computed(Option(p1)),
    Computed(Option(p2)),
    Computed(Option(p3)),
    Computed(Option(p4)),
    Computed(Option(p5)),
    Computed(Option(p6)),
  ),
  emits,
)

/// Define 7 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_7_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: Prop(p1),
  prop_2: Prop(p2),
  prop_3: Prop(p3),
  prop_4: Prop(p4),
  prop_5: Prop(p5),
  prop_6: Prop(p6),
  prop_7: Prop(p7),
) -> ComponentBase(
  #(
    Computed(p1),
    Computed(p2),
    Computed(p3),
    Computed(p4),
    Computed(p5),
    Computed(p6),
    Computed(p7),
  ),
  nullable_props,
  emits,
)

/// Define 7 nullable props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_7_nullable_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: NullableProp(p1),
  prop_2: NullableProp(p2),
  prop_3: NullableProp(p3),
  prop_4: NullableProp(p4),
  prop_5: NullableProp(p5),
  prop_6: NullableProp(p6),
  prop_7: NullableProp(p7),
) -> ComponentBase(
  required_props,
  #(
    Computed(Option(p1)),
    Computed(Option(p2)),
    Computed(Option(p3)),
    Computed(Option(p4)),
    Computed(Option(p5)),
    Computed(Option(p6)),
    Computed(Option(p7)),
  ),
  emits,
)

/// Define 8 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_8_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: Prop(p1),
  prop_2: Prop(p2),
  prop_3: Prop(p3),
  prop_4: Prop(p4),
  prop_5: Prop(p5),
  prop_6: Prop(p6),
  prop_7: Prop(p7),
  prop_8: Prop(p8),
) -> ComponentBase(
  #(
    Computed(p1),
    Computed(p2),
    Computed(p3),
    Computed(p4),
    Computed(p5),
    Computed(p6),
    Computed(p7),
    Computed(p8),
  ),
  nullable_props,
  emits,
)

/// Define 8 nullable props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_8_nullable_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: NullableProp(p1),
  prop_2: NullableProp(p2),
  prop_3: NullableProp(p3),
  prop_4: NullableProp(p4),
  prop_5: NullableProp(p5),
  prop_6: NullableProp(p6),
  prop_7: NullableProp(p7),
  prop_8: NullableProp(p8),
) -> ComponentBase(
  required_props,
  #(
    Computed(Option(p1)),
    Computed(Option(p2)),
    Computed(Option(p3)),
    Computed(Option(p4)),
    Computed(Option(p5)),
    Computed(Option(p6)),
    Computed(Option(p7)),
    Computed(Option(p8)),
  ),
  emits,
)

/// Define 9 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_9_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: Prop(p1),
  prop_2: Prop(p2),
  prop_3: Prop(p3),
  prop_4: Prop(p4),
  prop_5: Prop(p5),
  prop_6: Prop(p6),
  prop_7: Prop(p7),
  prop_8: Prop(p8),
  prop_9: Prop(p9),
) -> ComponentBase(
  #(
    Computed(p1),
    Computed(p2),
    Computed(p3),
    Computed(p4),
    Computed(p5),
    Computed(p6),
    Computed(p7),
    Computed(p8),
    Computed(p9),
  ),
  nullable_props,
  emits,
)

/// Define 9 nullable props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_9_nullable_props(
  component: ComponentBase(required_props, nullable_props, emits),
  prop_1: NullableProp(p1),
  prop_2: NullableProp(p2),
  prop_3: NullableProp(p3),
  prop_4: NullableProp(p4),
  prop_5: NullableProp(p5),
  prop_6: NullableProp(p6),
  prop_7: NullableProp(p7),
  prop_8: NullableProp(p8),
  prop_9: NullableProp(p9),
) -> ComponentBase(
  required_props,
  #(
    Computed(Option(p1)),
    Computed(Option(p2)),
    Computed(Option(p3)),
    Computed(Option(p4)),
    Computed(Option(p5)),
    Computed(Option(p6)),
    Computed(Option(p7)),
    Computed(Option(p8)),
    Computed(Option(p9)),
  ),
  emits,
)

// TODO: docs
/// Define emits on a component
@external(javascript, "../ffi.mjs", "addEmits")
pub fn with_emits(
  base: ComponentBase(required_props, nullable_props, emits),
  emits: List(String),
) -> ComponentBase(required_props, props, new_emits)

/// Component setup function 
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addSetup")
pub fn setup(
  base: ComponentBase(required_props, nullable_props, emits),
  setup: fn(required_props, nullable_props, emits) -> a,
) -> Component

// Reactivity: Core

/// A `vue` `ref`
pub type Ref(value)

/// Define a ref
@external(javascript, "vue", "ref")
pub fn ref(initial_value: value) -> Ref(value)

/// Get ref value
@external(javascript, "../ffi.mjs", "reflikeValue")
pub fn ref_value(value: Ref(value)) -> value

/// Set ref value
@external(javascript, "../ffi.mjs", "refSet")
pub fn ref_set(ref: Ref(value), value: value) -> Ref(value)

/// A `vue` `computed`
pub type Computed(value)

/// Define computed
@external(javascript, "vue", "computed")
pub fn computed(value: fn() -> value) -> Computed(value)

/// Get computed value
@external(javascript, "../ffi.mjs", "reflikeValue")
pub fn computed_value(computed: Computed(value)) -> value

/// DebuggerEvent returned from Vue
pub type DebuggerEvent

// Watch

type Watchable(value) {
  Ref(watchable: Ref(value))
  ShallowRef(watchable: ShallowRef(value))
  Computed(watchable: Computed(value))
  Function(watchable: fn() -> value)
  Plain(watchable: value)
}

type Reflikes(values)

pub type WithImmediate

pub type NoImmediate

pub type WithDeep

pub type NoDeep

pub type WithFlush

pub type NoFlush

pub type WithOnTrack

pub type NoOnTrack

pub type WithOnTrigger

pub type NoOnTrigger

pub type WithOnce

pub type NoOnce

pub type WatchFlush {
  FlushPost
  FlushSync
}

pub opaque type WatchConfig(
  values,
  has_immediate,
  has_deep,
  has_flush,
  has_on_track,
  has_on_trigger,
  has_once,
) {
  WatchConfig(
    reflikes: Reflikes(values),
    immediate: Option(Bool),
    deep: Option(Bool),
    flush: Option(WatchFlush),
    on_track: Option(fn(DebuggerEvent) -> Nil),
    on_trigger: Option(fn(DebuggerEvent) -> Nil),
    once: Option(Bool),
  )
}

type WatchCleanFunction =
  fn(fn() -> Nil) -> Nil

type WatchCallback(values) =
  fn(values, values, WatchCleanFunction) -> Nil

@external(javascript, "../ffi.mjs", "newReflikes")
fn new_reflikes(watchable: Watchable(value)) -> Reflikes(values)

@external(javascript, "../ffi.mjs", "addWatchableToReflikes")
fn add_watchable(
  reflikes: Reflikes(from_values),
  watchable: Watchable(value),
) -> Reflikes(to_values)

@external(javascript, "../ffi.mjs", "mergeReflikes")
fn merge_reflikes(
  reflikes_1: Reflikes(values_1),
  reflikes_2: Reflikes(values_2),
) -> Reflikes(to_values)

fn default_watch_config(reflikes: Reflikes(values)) {
  WatchConfig(
    reflikes: reflikes,
    immediate: None,
    deep: None,
    flush: None,
    on_track: None,
    on_trigger: None,
    once: None,
  )
}

type InitialWatchConfig(value) =
  WatchConfig(
    #(value),
    NoImmediate,
    NoDeep,
    NoFlush,
    NoOnTrack,
    NoOnTrigger,
    NoOnce,
  )

/// Define a watcher for a vue `computed`. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch_computed(first_name)
///  |> vue.and_ref(last_name)
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // old, new values are unavailable
///  })
/// ```
///
/// If you need the `new` and `old` values when more than a single value is
/// watched, use the quantity-aware `watchX` functions.
pub fn watch_computed(computed: Computed(value)) -> InitialWatchConfig(unknown) {
  default_watch_config(new_reflikes(Computed(computed)))
}

/// Define a watcher for a vue `ref`. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_computed(last_name)
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // old, new values are unavailable
///  })
/// ```
///
/// If you need the `new` and `old` values when more than a single value is
/// watched, use the quantity-aware `watchX` functions.
pub fn watch_ref(ref: Ref(value)) -> InitialWatchConfig(unknown) {
  default_watch_config(new_reflikes(Ref(ref)))
}

/// Define a watcher for a vue `shallow_ref`. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch_shallow_ref(first_name)
///  |> vue.and_computed(last_name)
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // old, new values are unavailable
///  })
/// ```
///
/// If you need the `new` and `old` values when more than a single value is
/// watched, use the quantity-aware `watchX` functions.
pub fn watch_shallow_ref(
  shallow_ref: ShallowRef(value),
) -> InitialWatchConfig(unknown) {
  default_watch_config(new_reflikes(ShallowRef(shallow_ref)))
}

/// Define a watcher for a function. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch_function(get_first_name)
///  |> vue.and_computed(last_name)
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // old, new values are unavailable
///  })
/// ```
///
/// If you need the `new` and `old` values when more than a single value is
/// watched, use the quantity-aware `watchX` functions.
pub fn watch_function(function: fn() -> value) -> InitialWatchConfig(unknown) {
  default_watch_config(new_reflikes(Function(function)))
}

/// Define a watcher for a plain value. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch_plain(first_name)
///  |> vue.and_shallow_ref(last_name)
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // old, new values are unavailable
///  })
/// ```
///
/// If you need the `new` and `old` values when more than a single value is
/// watched, use the quantity-aware `watchX` functions.
pub fn watch_plain(plain: value) -> InitialWatchConfig(unknown) {
  default_watch_config(new_reflikes(Plain(plain)))
}

type RefsOnlyWatchConfig(any) =
  WatchConfig(any, NoImmediate, NoDeep, NoFlush, NoOnTrack, NoOnTrigger, NoOnce)

/// Add a `computed` value to a watch
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_computed(last_name)
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // ...
///  })
/// ```
pub fn and_computed(
  watch_config: RefsOnlyWatchConfig(unknown),
  computed: Computed(value),
) -> RefsOnlyWatchConfig(unknown) {
  WatchConfig(
    ..watch_config,
    reflikes: watch_config.reflikes
      |> add_watchable(Computed(computed)),
  )
}

/// Add a `ref` value to a watch
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_ref(last_name)
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // ...
///  })
/// ```
pub fn and_ref(
  watch_config: RefsOnlyWatchConfig(unknown),
  ref: Ref(value),
) -> RefsOnlyWatchConfig(unknown) {
  WatchConfig(
    ..watch_config,
    reflikes: watch_config.reflikes
      |> add_watchable(Ref(ref)),
  )
}

/// Add a `shallow_ref` value to a watch
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_shallow_ref(last_name)
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // ...
///  })
/// ```
pub fn and_shallow_ref(
  watch_config: RefsOnlyWatchConfig(unknown),
  shallow_ref: ShallowRef(value),
) -> RefsOnlyWatchConfig(unknown) {
  WatchConfig(
    ..watch_config,
    reflikes: watch_config.reflikes
      |> add_watchable(ShallowRef(shallow_ref)),
  )
}

/// Add a function to a watch
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_function(last_name)
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // ...
///  })
/// ```
pub fn and_function(
  watch_config: RefsOnlyWatchConfig(unknown),
  function: fn() -> value,
) -> RefsOnlyWatchConfig(unknown) {
  WatchConfig(
    ..watch_config,
    reflikes: watch_config.reflikes
      |> add_watchable(Function(function)),
  )
}

/// Add a plain value to a watch
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_plain(last_name)
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // ...
///  })
/// ```
pub fn and_plain(
  watch_config: RefsOnlyWatchConfig(unknown),
  plain: value,
) -> RefsOnlyWatchConfig(unknown) {
  WatchConfig(
    ..watch_config,
    reflikes: watch_config.reflikes
      |> add_watchable(Plain(plain)),
  )
}

/// Set the `immediate` option on a watch
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_computed(last_name)
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // ...
///  })
/// ```
pub fn with_immediate(
  watch_config: WatchConfig(
    values,
    NoImmediate,
    has_deep,
    has_flush,
    has_on_track,
    has_on_trigger,
    has_once,
  ),
  immediate: Bool,
) -> WatchConfig(
  values,
  WithImmediate,
  has_deep,
  has_flush,
  has_on_track,
  has_on_trigger,
  has_once,
) {
  WatchConfig(
    reflikes: watch_config.reflikes,
    immediate: Some(immediate),
    deep: watch_config.deep,
    flush: watch_config.flush,
    on_track: watch_config.on_track,
    on_trigger: watch_config.on_trigger,
    once: watch_config.once,
  )
}

/// Set the `deep` option on a watch
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_computed(last_name)
///  |> vue.with_deep(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // ...
///  })
/// ```
pub fn with_deep(
  watch_config: WatchConfig(
    values,
    has_immediate,
    NoDeep,
    has_flush,
    has_on_track,
    has_on_trigger,
    has_once,
  ),
  deep: Bool,
) -> WatchConfig(
  values,
  has_immediate,
  WithDeep,
  has_flush,
  has_on_track,
  has_on_trigger,
  has_once,
) {
  WatchConfig(
    reflikes: watch_config.reflikes,
    immediate: watch_config.immediate,
    deep: Some(deep),
    flush: watch_config.flush,
    on_track: watch_config.on_track,
    on_trigger: watch_config.on_trigger,
    once: watch_config.once,
  )
}

/// Set the `flush` option on a watch
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_computed(last_name)
///  |> vue.with_flush(vue.FlushPost)
///  |> vue.with_listener(fn(_, _, _) {
///    // ...
///  })
/// ```
pub fn with_flush(
  watch_config: WatchConfig(
    values,
    has_immediate,
    has_deep,
    NoFlush,
    has_on_track,
    has_on_trigger,
    has_once,
  ),
  flush: WatchFlush,
) -> WatchConfig(
  values,
  has_immediate,
  has_deep,
  WithFlush,
  has_on_track,
  has_on_trigger,
  has_once,
) {
  WatchConfig(
    reflikes: watch_config.reflikes,
    immediate: watch_config.immediate,
    deep: watch_config.deep,
    flush: option.Some(flush),
    on_track: watch_config.on_track,
    on_trigger: watch_config.on_trigger,
    once: watch_config.once,
  )
}

/// Set the `on_track` callback on a watch
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_computed(last_name)
///  |> vue.on_track(fn(_) {
///    // ...
///  })
///  |> vue.with_listener(fn(_, _, _) {
///    // ...
///  })
/// ```
pub fn on_track(
  watch_config: WatchConfig(
    values,
    has_immediate,
    has_deep,
    has_flush,
    NoOnTrack,
    has_on_trigger,
    has_once,
  ),
  on_track,
) -> WatchConfig(
  values,
  has_immediate,
  has_deep,
  has_flush,
  WithOnTrack,
  has_on_trigger,
  has_once,
) {
  WatchConfig(
    reflikes: watch_config.reflikes,
    immediate: watch_config.immediate,
    deep: watch_config.deep,
    flush: watch_config.flush,
    on_track: on_track,
    on_trigger: watch_config.on_trigger,
    once: watch_config.once,
  )
}

/// Set the `on_trigger` callback on a watch
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_computed(last_name)
///  |> vue.on_trigger(fn(_) {
///    // ...
///  })
///  |> vue.with_listener(fn(_, _, _) {
///    // ...
///  })
/// ```
pub fn on_trigger(
  watch_config: WatchConfig(
    values,
    has_immediate,
    has_deep,
    has_flush,
    has_on_track,
    NoOnTrigger,
    has_once,
  ),
  on_trigger,
) -> WatchConfig(
  values,
  has_immediate,
  has_deep,
  has_flush,
  has_on_track,
  WithOnTrigger,
  has_once,
) {
  WatchConfig(
    reflikes: watch_config.reflikes,
    immediate: watch_config.immediate,
    deep: watch_config.deep,
    flush: watch_config.flush,
    on_track: watch_config.on_track,
    on_trigger: on_trigger,
    once: watch_config.once,
  )
}

/// Set the `once` option on a watch
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_computed(last_name)
///  |> vue.with_once(True)
///  |> vue.with_listener(fn(_, _, _) {
///    // ...
///  })
/// ```
pub fn with_once(
  watch_config: WatchConfig(
    values,
    has_immediate,
    has_deep,
    has_flush,
    has_on_track,
    has_on_trigger,
    NoOnce,
  ),
  once: Bool,
) -> WatchConfig(
  values,
  has_immediate,
  has_deep,
  has_flush,
  has_on_track,
  has_on_trigger,
  WithOnce,
) {
  WatchConfig(
    reflikes: watch_config.reflikes,
    immediate: watch_config.immediate,
    deep: watch_config.deep,
    flush: watch_config.flush,
    on_track: watch_config.on_track,
    on_trigger: watch_config.on_trigger,
    once: Some(once),
  )
}

@external(javascript, "../ffi.mjs", "do_watch")
fn do_watch(
  reflikes reflikes: Reflikes(any),
  callback callback: callback,
  immediate immediate: Option(Bool),
  deep deep: Option(Bool),
  flush flush: Option(String),
  on_track on_track: Option(fn(DebuggerEvent) -> Nil),
  on_trigger on_trigger: Option(fn(DebuggerEvent) -> Nil),
  once once: Option(Bool),
) -> Nil

/// Set the listener for a watch
///
/// ```gleam
///  vue.watch_ref(first_name)
///  |> vue.and_computed(last_name)
///  |> vue.with_listener(fn(_, _, _) {
///    // ...
///  })
/// ```
///
/// If you need the `new` and `old` values when more than a single value is
/// watched, use the quantity-aware `watchX` functions along with this.
pub fn with_listener(
  watch_config: WatchConfig(
    values,
    has_immediate,
    has_deep,
    has_flush,
    has_on_track,
    has_on_trigger,
    has_once,
  ),
  callback: WatchCallback(values),
) -> Nil {
  do_watch(
    reflikes: watch_config.reflikes,
    callback: callback,
    immediate: watch_config.immediate,
    deep: watch_config.deep,
    flush: watch_config.flush
      |> option.map(fn(flush) {
        case flush {
          FlushPost -> "post"
          FlushSync -> "sync"
        }
      }),
    on_track: watch_config.on_track,
    on_trigger: watch_config.on_trigger,
    once: watch_config.once,
  )
}

/// Define a watcher for 2 "reflike" values. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch2(#(
///    watch_computed(last_name),
///    watch_ref(last_name),
///  ))
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(values, old_values, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // values, old_values, is a tuple corresponding to the input
///  })
/// ```
///
/// If you don't need the `new` and `old` values or only watch a single value,
/// use the quantity-agnostic `watch_` and `and_` functions by themselves.
pub fn watch2(
  watches watches: #(InitialWatchConfig(a), InitialWatchConfig(b)),
) -> WatchConfig(
  #(a, b),
  NoImmediate,
  NoDeep,
  NoFlush,
  NoOnTrack,
  NoOnTrigger,
  NoOnce,
) {
  { watches.0 }.reflikes
  |> merge_reflikes({ watches.1 }.reflikes)
  |> default_watch_config
}

/// Define a watcher for 3 "reflike" values. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch3(#(
///    watch_computed(last_name),
///    watch_ref(last_name),
///    watch_shallow_ref(that_uncle_name),
///  ))
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(values, old_values, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // values, old_values, is a tuple corresponding to the input
///  })
/// ```
///
/// If you don't need the `new` and `old` values or only watch a single value,
/// use the quantity-agnostic `watch_` and `and_` functions by themselves.
pub fn watch3(
  watches watches: #(
    InitialWatchConfig(a),
    InitialWatchConfig(b),
    InitialWatchConfig(c),
  ),
) -> WatchConfig(
  #(a, b, c),
  NoImmediate,
  NoDeep,
  NoFlush,
  NoOnTrack,
  NoOnTrigger,
  NoOnce,
) {
  { watches.0 }.reflikes
  |> merge_reflikes({ watches.1 }.reflikes)
  |> merge_reflikes({ watches.2 }.reflikes)
  |> default_watch_config
}

/// Define a watcher for 4 "reflike" values. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch4(#(
///    watch_computed(last_name),
///    watch_ref(last_name),
///    watch_shallow_ref(that_annoying_guy),
///    watch_shallow_ref(his_annoying_brother),
///  ))
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(values, old_values, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // values, old_values, is a tuple corresponding to the input
///  })
/// ```
///
/// If you don't need the `new` and `old` values or only watch a single value,
/// use the quantity-agnostic `watch_` and `and_` functions by themselves.
pub fn watch4(
  watches watches: #(
    InitialWatchConfig(a),
    InitialWatchConfig(b),
    InitialWatchConfig(c),
    InitialWatchConfig(d),
  ),
) -> WatchConfig(
  #(a, b, c, d),
  NoImmediate,
  NoDeep,
  NoFlush,
  NoOnTrack,
  NoOnTrigger,
  NoOnce,
) {
  { watches.0 }.reflikes
  |> merge_reflikes({ watches.1 }.reflikes)
  |> merge_reflikes({ watches.2 }.reflikes)
  |> merge_reflikes({ watches.3 }.reflikes)
  |> default_watch_config
}

/// Define a watcher for 5 "reflike" values. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch5(#(
///    watch_computed(last_name),
///    watch_ref(last_name),
///    watch_shallow_ref(that_annoying_guy),
///    watch_shallow_ref(his_annoying_brother),
///    watch_computed(grades),
///  ))
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(values, old_values, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // values, old_values, is a tuple corresponding to the input
///  })
/// ```
///
/// If you don't need the `new` and `old` values or only watch a single value,
/// use the quantity-agnostic `watch_` and `and_` functions by themselves.
pub fn watch5(
  watches watches: #(
    InitialWatchConfig(a),
    InitialWatchConfig(b),
    InitialWatchConfig(c),
    InitialWatchConfig(d),
    InitialWatchConfig(e),
  ),
) -> WatchConfig(
  #(a, b, c, d, e),
  NoImmediate,
  NoDeep,
  NoFlush,
  NoOnTrack,
  NoOnTrigger,
  NoOnce,
) {
  { watches.0 }.reflikes
  |> merge_reflikes({ watches.1 }.reflikes)
  |> merge_reflikes({ watches.2 }.reflikes)
  |> merge_reflikes({ watches.3 }.reflikes)
  |> merge_reflikes({ watches.4 }.reflikes)
  |> default_watch_config
}

/// Define a watcher for 6 "reflike" values. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch6(#(
///    watch_computed(last_name),
///    watch_ref(last_name),
///    watch_shallow_ref(that_annoying_guy),
///    watch_shallow_ref(his_annoying_brother),
///    watch_computed(grades),
///    watch_computed(passes),
///  ))
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(values, old_values, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // values, old_values, is a tuple corresponding to the input
///  })
/// ```
///
/// If you don't need the `new` and `old` values or only watch a single value,
/// use the quantity-agnostic `watch_` and `and_` functions by themselves.
pub fn watch6(
  watches watches: #(
    InitialWatchConfig(a),
    InitialWatchConfig(b),
    InitialWatchConfig(c),
    InitialWatchConfig(d),
    InitialWatchConfig(e),
    InitialWatchConfig(f),
  ),
) -> WatchConfig(
  #(a, b, c, d, e, f),
  NoImmediate,
  NoDeep,
  NoFlush,
  NoOnTrack,
  NoOnTrigger,
  NoOnce,
) {
  { watches.0 }.reflikes
  |> merge_reflikes({ watches.1 }.reflikes)
  |> merge_reflikes({ watches.2 }.reflikes)
  |> merge_reflikes({ watches.3 }.reflikes)
  |> merge_reflikes({ watches.4 }.reflikes)
  |> merge_reflikes({ watches.5 }.reflikes)
  |> default_watch_config
}

/// Define a watcher for 7 "reflike" values. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch7(#(
///    watch_computed(last_name),
///    watch_ref(last_name),
///    watch_shallow_ref(that_annoying_guy),
///    watch_shallow_ref(his_annoying_brother),
///    watch_computed(grades),
///    watch_computed(passes),
///    watch_computed(fails),
///  ))
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(values, old_values, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // values, old_values, is a tuple corresponding to the input
///  })
/// ```
///
/// If you don't need the `new` and `old` values or only watch a single value,
/// use the quantity-agnostic `watch_` and `and_` functions by themselves.
pub fn watch7(
  watches watches: #(
    InitialWatchConfig(a),
    InitialWatchConfig(b),
    InitialWatchConfig(c),
    InitialWatchConfig(d),
    InitialWatchConfig(e),
    InitialWatchConfig(f),
    InitialWatchConfig(g),
  ),
) -> WatchConfig(
  #(a, b, c, d, e, f, g),
  NoImmediate,
  NoDeep,
  NoFlush,
  NoOnTrack,
  NoOnTrigger,
  NoOnce,
) {
  { watches.0 }.reflikes
  |> merge_reflikes({ watches.1 }.reflikes)
  |> merge_reflikes({ watches.2 }.reflikes)
  |> merge_reflikes({ watches.3 }.reflikes)
  |> merge_reflikes({ watches.4 }.reflikes)
  |> merge_reflikes({ watches.5 }.reflikes)
  |> merge_reflikes({ watches.6 }.reflikes)
  |> default_watch_config
}

/// Define a watcher for 8 "reflike" values. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch8(#(
///    watch_computed(last_name),
///    watch_ref(last_name),
///    watch_shallow_ref(that_annoying_guy),
///    watch_shallow_ref(his_annoying_brother),
///    watch_computed(grades),
///    watch_computed(passes),
///    watch_computed(fails),
///    watch_computed(average_grade),
///  ))
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(values, old_values, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // values, old_values, is a tuple corresponding to the input
///  })
/// ```
///
/// If you don't need the `new` and `old` values or only watch a single value,
/// use the quantity-agnostic `watch_` and `and_` functions by themselves.
pub fn watch8(
  watches watches: #(
    InitialWatchConfig(a),
    InitialWatchConfig(b),
    InitialWatchConfig(c),
    InitialWatchConfig(d),
    InitialWatchConfig(e),
    InitialWatchConfig(f),
    InitialWatchConfig(g),
    InitialWatchConfig(h),
  ),
) -> WatchConfig(
  #(a, b, c, d, e, f, g, h),
  NoImmediate,
  NoDeep,
  NoFlush,
  NoOnTrack,
  NoOnTrigger,
  NoOnce,
) {
  { watches.0 }.reflikes
  |> merge_reflikes({ watches.1 }.reflikes)
  |> merge_reflikes({ watches.2 }.reflikes)
  |> merge_reflikes({ watches.3 }.reflikes)
  |> merge_reflikes({ watches.4 }.reflikes)
  |> merge_reflikes({ watches.5 }.reflikes)
  |> merge_reflikes({ watches.6 }.reflikes)
  |> merge_reflikes({ watches.7 }.reflikes)
  |> default_watch_config
}

/// Define a watcher for 9 "reflike" values. You can use `and_` modifiers to add
/// values to the watch, `with_` modifiers to set options, and `with_listener`
/// for the listen function.
///
/// ```gleam
///  vue.watch9(#(
///    watch_computed(last_name),
///    watch_ref(last_name),
///    watch_shallow_ref(that_annoying_guy),
///    watch_shallow_ref(his_annoying_brother),
///    watch_computed(grades),
///    watch_computed(passes),
///    watch_computed(fails),
///    watch_computed(average_grade),
///    watch_computed(standard_deviation),
///  ))
///  |> vue.with_immediate(True)
///  |> vue.with_listener(fn(values, old_values, _) {
///    // this will fire on a change in `first_name` or `last_name`
///    // values, old_values, is a tuple corresponding to the input
///  })
/// ```
///
/// If you don't need the `new` and `old` values or only watch a single value,
/// use the quantity-agnostic `watch_` and `and_` functions by themselves.
pub fn watch9(
  watches watches: #(
    InitialWatchConfig(a),
    InitialWatchConfig(b),
    InitialWatchConfig(c),
    InitialWatchConfig(d),
    InitialWatchConfig(e),
    InitialWatchConfig(f),
    InitialWatchConfig(g),
    InitialWatchConfig(h),
    InitialWatchConfig(i),
  ),
) -> WatchConfig(
  #(a, b, c, d, e, f, g, h, i),
  NoImmediate,
  NoDeep,
  NoFlush,
  NoOnTrack,
  NoOnTrigger,
  NoOnce,
) {
  { watches.0 }.reflikes
  |> merge_reflikes({ watches.1 }.reflikes)
  |> merge_reflikes({ watches.2 }.reflikes)
  |> merge_reflikes({ watches.3 }.reflikes)
  |> merge_reflikes({ watches.4 }.reflikes)
  |> merge_reflikes({ watches.5 }.reflikes)
  |> merge_reflikes({ watches.6 }.reflikes)
  |> merge_reflikes({ watches.7 }.reflikes)
  |> merge_reflikes({ watches.8 }.reflikes)
  |> default_watch_config
}

// Reactivity: Advanced

/// A `vue` `shallowRef`
pub type ShallowRef(value)

/// Define a shallow ref
@external(javascript, "vue", "shallowRef")
pub fn shallow_ref(value: value) -> ShallowRef(value)

/// Trigger a shallow ref
@external(javascript, "vue", "triggerRef")
pub fn trigger_ref(ref: ShallowRef(value)) -> Nil

/// Get shallow ref value
@external(javascript, "../ffi.mjs", "reflikeValue")
pub fn shallow_ref_value(a: ShallowRef(value)) -> value

/// Set shallow ref value
@external(javascript, "../ffi.mjs", "refSet")
pub fn shallow_ref_set(
  ref: ShallowRef(value),
  value: value,
) -> ShallowRef(value)

// Lifecycles

@external(javascript, "vue", "onMounted")
pub fn on_mounted(handler: fn() -> Nil) -> Nil

@external(javascript, "vue", "onUpdated")
pub fn on_updated(handler: fn() -> Nil) -> Nil

@external(javascript, "vue", "onUnmounted")
pub fn on_unmounted(handler: fn() -> Nil) -> Nil

@external(javascript, "vue", "onBeforeMount")
pub fn on_before_mount(handler: fn() -> Nil) -> Nil

@external(javascript, "vue", "onBeforeUpdate")
pub fn on_before_update(handler: fn() -> Nil) -> Nil

@external(javascript, "vue", "onBeforeUnmount")
pub fn on_before_unmount(handler: fn() -> Nil) -> Nil

@external(javascript, "vue", "onActivated")
pub fn on_activated(handler: fn() -> Nil) -> Nil

@external(javascript, "vue", "onDeactivated")
pub fn on_deactivated(handler: fn() -> Nil) -> Nil

// Dependency Injection

@external(javascript, "vue", "provide")
pub fn provide(key: String, value: value) -> Nil

@external(javascript, "../ffi.mjs", "inject")
pub fn inject(key: String) -> Option(value)

@external(javascript, "../ffi.mjs", "injectWithDefault")
pub fn inject_with_default(key: String, default: value) -> value

@external(javascript, "../ffi.mjs", "injectWithFactory")
pub fn inject_with_factory(key: String, factory: fn() -> value) -> value
