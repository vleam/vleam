import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option, None}

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
///     Prop("initialName", None),
///   )
///   |> with_1_nullable_prop(
///     Prop("greeting", Some("Hello, ")),
///   )
///   // Props are handed as Computed for reactivity. It's best practice to
///   // always type them, as types are only inferred if there's a default value.
///   |> setup(fn(
///     required_props: #(Computed(String)),
///     nullable_props: #(Computed(String)),
///     _
///   ) {
///     let initial_name = props.0
///     let greeting = props.1
///
///     // Errors are thrown. This is just a demo, don't throw on bad input,
///     // only on irrecoverable errors.
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
///     // tuple of object entires tuples. The following is identical to Vue's:
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

/// Define 1 prop on a component
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

/// Define 2 props on a component
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

/// Define 3 props on a component
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

/// Define 4 props on a component
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

/// Define 5 props on a component
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

/// Define 6 props on a component
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

/// Define 7 props on a component
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

/// Define 8 props on a component
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

/// Define 9 props on a component
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

/// Watchable types
pub type Watchable(value) {
  Ref(watchable: Ref(value))
  ShallowRef(watchable: ShallowRef(value))
  Computed(watchable: Computed(value))
  Function(watchable: fn() -> value)
  Plain(watchable: value)
}

@external(javascript, "../ffi.mjs", "watch")
pub fn watch1_with_options(
  reflikes reflikes: #(Watchable(a)),
  callback callback: fn(a, a, Option(fn(fn() -> Nil) -> Nil)) -> Nil,
  immediate immediate: Option(Bool),
  deep deep: Option(Bool),
  flush flush: Option(String),
  on_track on_track: Option(fn(DebuggerEvent) -> Nil),
  on_trigger on_trigger: Option(fn(DebuggerEvent) -> Nil),
  once once: Option(Bool),
) -> Nil

@external(javascript, "../ffi.mjs", "watch")
pub fn watch2_with_options(
  reflikes reflikes: #(Watchable(a), Watchable(b)),
  callback callback: fn(
    #(Watchable(a), Watchable(b)),
    #(Watchable(a), Watchable(b)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
  immediate immediate: Option(Bool),
  deep deep: Option(Bool),
  flush flush: Option(String),
  on_track on_track: Option(fn(DebuggerEvent) -> Nil),
  on_trigger on_trigger: Option(fn(DebuggerEvent) -> Nil),
  once once: Option(Bool),
) -> Nil

@external(javascript, "../ffi.mjs", "watch")
pub fn watch3_with_options(
  reflikes reflikes: #(Watchable(a), Watchable(b), Watchable(c)),
  callback callback: fn(
    #(Watchable(a), Watchable(b), Watchable(c)),
    #(Watchable(a), Watchable(b), Watchable(c)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
  immediate immediate: Option(Bool),
  deep deep: Option(Bool),
  flush flush: Option(String),
  on_track on_track: Option(fn(DebuggerEvent) -> Nil),
  on_trigger on_trigger: Option(fn(DebuggerEvent) -> Nil),
  once once: Option(Bool),
) -> Nil

@external(javascript, "../ffi.mjs", "watch")
pub fn watch4_with_options(
  reflikes reflikes: #(Watchable(a), Watchable(b), Watchable(c), Watchable(d)),
  callback callback: fn(
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d)),
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
  immediate immediate: Option(Bool),
  deep deep: Option(Bool),
  flush flush: Option(String),
  on_track on_track: Option(fn(DebuggerEvent) -> Nil),
  on_trigger on_trigger: Option(fn(DebuggerEvent) -> Nil),
  once once: Option(Bool),
) -> Nil

@external(javascript, "../ffi.mjs", "watch")
pub fn watch5_with_options(
  reflikes reflikes: #(
    Watchable(a),
    Watchable(b),
    Watchable(c),
    Watchable(d),
    Watchable(e),
  ),
  callback callback: fn(
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d), Watchable(e)),
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d), Watchable(e)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
  immediate immediate: Option(Bool),
  deep deep: Option(Bool),
  flush flush: Option(String),
  on_track on_track: Option(fn(DebuggerEvent) -> Nil),
  on_trigger on_trigger: Option(fn(DebuggerEvent) -> Nil),
  once once: Option(Bool),
) -> Nil

pub fn watch1(
  reflikes reflikes: #(Watchable(a)),
  callback callback: fn(a, a, Option(fn(fn() -> Nil) -> Nil)) -> Nil,
) -> Nil {
  watch1_with_options(reflikes, callback, None, None, None, None, None, None)
}

pub fn watch2(
  reflikes reflikes: #(Watchable(a), Watchable(b)),
  callback callback: fn(
    #(Watchable(a), Watchable(b)),
    #(Watchable(a), Watchable(b)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
) -> Nil {
  watch2_with_options(reflikes, callback, None, None, None, None, None, None)
}

pub fn watch3(
  reflikes reflikes: #(Watchable(a), Watchable(b), Watchable(c)),
  callback callback: fn(
    #(Watchable(a), Watchable(b), Watchable(c)),
    #(Watchable(a), Watchable(b), Watchable(c)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
) -> Nil {
  watch3_with_options(reflikes, callback, None, None, None, None, None, None)
}

pub fn watch4(
  reflikes reflikes: #(Watchable(a), Watchable(b), Watchable(c), Watchable(d)),
  callback callback: fn(
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d)),
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
) -> Nil {
  watch4_with_options(reflikes, callback, None, None, None, None, None, None)
}

pub fn watch5(
  reflikes reflikes: #(
    Watchable(a),
    Watchable(b),
    Watchable(c),
    Watchable(d),
    Watchable(e),
  ),
  callback callback: fn(
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d), Watchable(e)),
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d), Watchable(e)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
) -> Nil {
  watch5_with_options(reflikes, callback, None, None, None, None, None, None)
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
