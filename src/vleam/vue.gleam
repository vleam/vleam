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
pub fn next_tick(callback: Option(fn() -> Nil)) -> Promise(Nil)

// Setup

/// An incomplete component representation piped during component definition.
/// See `define_component` for a full example.
pub type ComponentBase(props, emits)

/// Prop record to be used on component definition.
/// See `define_component` for a full example.
pub type Prop(value) {
  Prop(name: String, default: Option(value))
}

/// Entrypoint for component definition. optionally piped to a `with_n_props`
/// and/or `with_emits` functions, and must be finally piped to `setup`.
///
/// `components` is a list of #(component_name, fn() -> Component) tuples. There
/// are three possible ways to gain access to components:
///
/// 1. Using `@external` to refer to a component defined in Javascript
/// 2. Importing a component defined in Gleam using this library
/// 3. Using them without the need to refer them in `define_component`, either
///    by defining them globally `vue.component` or by an auto-import mechanism
///    similar to Nuxt's
///
/// `directives` is a list of #(directive_name, fn() -> Directive) tuples.
///
/// `inherit_attrs` is a boolean the same as Vue's javascript configuration.
///
/// ## Example
///
/// ```gleam
/// import gleam/option.{None, Some}
/// import gleam/string
/// import vleam/vue.{
///   type Component, Prop, define_component, setup, with_2_props,
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
///   |> with_2_props(#(
///     // No default value, therefore mandatory
///     Prop("initialName", None),
///     // Default value, therefore optional
///     Prop("greeting", Some("Hello, ")),
///   ))
///   // It's best practice to always type the props, as types are only inferred if
///   // there's a default value.
///   |> setup(fn(props: #(String, String), _) {
///     let initial_name = props.0
///     let greeting = props.1
///     case string.length(greeting) > 0 {
///       True -> {
///         let change_count = vue.shallow_ref(0)
///         let increment_count = fn() {
///           change_count
///           |> vue.shallow_ref_set(vue.shallow_ref_value(change_count) + 1)
///         }
///         let name = vue.shallow_ref(initial_name)
///         let change_name = fn(new_name) {
///           name
///           |> vue.shallow_ref_set(new_name)
///         }
///         let full_greeting =
///           vue.computed(fn() {
///             name
///             |> vue.shallow_ref_value
///             |> string.append(greeting)
/// 
///             increment_count()
///           })
/// 
///         // To return values to the template, the FFI expects an Ok() with a
///         // tuple of object entires tuples. The following is identical to Vue's:
///         //
///         // return {
///         //   fullGreeting: full_greeting,
///         //   changeName: change_name,
///         // };
///         Ok(
///           #(#("fullGreeting", full_greeting), #("changeName", change_name), #(
///             "changeCount",
///             change_count,
///           )),
///         )
///       }
///       False -> {
///         // Errors are thrown. This is just a demo, don't throw on bad input,
///         // only on irrecoverable errors.
///         Error("Empty greeting")
///       }
///     }
///   })
/// }
/// ```
@external(javascript, "../ffi.mjs", "defineComponent")
pub fn define_component(
  components: List(#(String, fn() -> Component)),
  directives: List(#(String, fn() -> Directive)),
  inherit_attrs: Bool,
) -> ComponentBase(Nil, Nil)

/// Define 1 prop on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_1_prop(
  component: ComponentBase(props, emits),
  props: #(Prop(p1)),
) -> ComponentBase(#(p1), emits)

/// Define 2 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_2_props(
  component: ComponentBase(props, emits),
  props: #(Prop(p1), Prop(p2)),
) -> ComponentBase(#(p1, p2), emits)

/// Define 3 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_3_props(
  component: ComponentBase(props, emits),
  props: #(Prop(p1), Prop(p2), Prop(p3)),
) -> ComponentBase(#(p1, p2, p3), emits)

/// Define 4 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_4_props(
  component: ComponentBase(props, emits),
  props: #(Prop(p1), Prop(p2), Prop(p3), Prop(p4)),
) -> ComponentBase(#(p1, p2, p3, p4), emits)

/// Define 5 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_5_props(
  component: ComponentBase(props, emits),
  props: #(Prop(p1), Prop(p2), Prop(p3), Prop(p4), Prop(p5)),
) -> ComponentBase(#(p1, p2, p3, p4, p5), emits)

/// Define 6 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_6_props(
  component: ComponentBase(props, emits),
  props: #(Prop(p1), Prop(p2), Prop(p3), Prop(p4), Prop(p5), Prop(p6)),
) -> ComponentBase(#(p1, p2, p3, p4, p5, p6), emits)

/// Define 7 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_7_props(
  component: ComponentBase(props, emits),
  props: #(Prop(p1), Prop(p2), Prop(p3), Prop(p4), Prop(p5), Prop(p6), Prop(p7)),
) -> ComponentBase(#(p1, p2, p3, p4, p5, p6, p7), emits)

/// Define 8 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_8_props(
  component: ComponentBase(props, emits),
  props: #(
    Prop(p1),
    Prop(p2),
    Prop(p3),
    Prop(p4),
    Prop(p5),
    Prop(p6),
    Prop(p7),
    Prop(p8),
  ),
) -> ComponentBase(#(p1, p2, p3, p4, p5, p6, p7, p8), emits)

/// Define 9 props on a component
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addProps")
pub fn with_9_props(
  component: ComponentBase(props, emits),
  props: #(
    Prop(p1),
    Prop(p2),
    Prop(p3),
    Prop(p4),
    Prop(p5),
    Prop(p6),
    Prop(p7),
    Prop(p8),
    Prop(p9),
  ),
) -> ComponentBase(#(p1, p2, p3, p4, p5, p6, p7, p8, p9), emits)

// TODO: docs
/// Define emits on a component
@external(javascript, "../ffi.mjs", "addEmits")
pub fn with_emits(
  base: ComponentBase(props, emits),
  emits: List(String),
) -> ComponentBase(props, new_emits)

/// Component setup function 
/// See `define_component` for a full example.
@external(javascript, "../ffi.mjs", "addSetup")
pub fn setup(
  base: ComponentBase(props, emits),
  setup: fn(props, emits) -> a,
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
  NullableRef(watchable: NullableRef(value))
  NullableShallowRef(watchable: NullableShallowRef(value))
  Computed(watchable: Computed(value))
  Function(watchable: fn() -> value)
  Plain(watchable: value)
}

@external(javascript, "../ffi.mjs", "watch")
pub fn watch1_with_options(
  reflikes: #(Watchable(a)),
  callback: fn(a, a, Option(fn(fn() -> Nil) -> Nil)) -> Nil,
  immediate: Option(Bool),
  deep: Option(Bool),
  flush: Option(String),
  on_track: Option(fn(DebuggerEvent) -> Nil),
  on_trigger: Option(fn(DebuggerEvent) -> Nil),
  once: Option(Bool),
) -> Nil

@external(javascript, "../ffi.mjs", "watch")
pub fn watch2_with_options(
  reflikes: #(Watchable(a), Watchable(b)),
  callback: fn(
    #(Watchable(a), Watchable(b)),
    #(Watchable(a), Watchable(b)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
  immediate: Option(Bool),
  deep: Option(Bool),
  flush: Option(String),
  on_track: Option(fn(DebuggerEvent) -> Nil),
  on_trigger: Option(fn(DebuggerEvent) -> Nil),
  once: Option(Bool),
) -> Nil

@external(javascript, "../ffi.mjs", "watch")
pub fn watch3_with_options(
  reflikes: #(Watchable(a), Watchable(b), Watchable(c)),
  callback: fn(
    #(Watchable(a), Watchable(b), Watchable(c)),
    #(Watchable(a), Watchable(b), Watchable(c)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
  immediate: Option(Bool),
  deep: Option(Bool),
  flush: Option(String),
  on_track: Option(fn(DebuggerEvent) -> Nil),
  on_trigger: Option(fn(DebuggerEvent) -> Nil),
  once: Option(Bool),
) -> Nil

@external(javascript, "../ffi.mjs", "watch")
pub fn watch4_with_options(
  reflikes: #(Watchable(a), Watchable(b), Watchable(c), Watchable(d)),
  callback: fn(
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d)),
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
  immediate: Option(Bool),
  deep: Option(Bool),
  flush: Option(String),
  on_track: Option(fn(DebuggerEvent) -> Nil),
  on_trigger: Option(fn(DebuggerEvent) -> Nil),
  once: Option(Bool),
) -> Nil

@external(javascript, "../ffi.mjs", "watch")
pub fn watch5_with_options(
  reflikes: #(
    Watchable(a),
    Watchable(b),
    Watchable(c),
    Watchable(d),
    Watchable(e),
  ),
  callback: fn(
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d), Watchable(e)),
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d), Watchable(e)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
  immediate: Option(Bool),
  deep: Option(Bool),
  flush: Option(String),
  on_track: Option(fn(DebuggerEvent) -> Nil),
  on_trigger: Option(fn(DebuggerEvent) -> Nil),
  once: Option(Bool),
) -> Nil

pub fn watch1(
  reflikes: #(Watchable(a)),
  callback: fn(a, a, Option(fn(fn() -> Nil) -> Nil)) -> Nil,
) -> Nil {
  watch1_with_options(reflikes, callback, None, None, None, None, None, None)
}

pub fn watch2(
  reflikes: #(Watchable(a), Watchable(b)),
  callback: fn(
    #(Watchable(a), Watchable(b)),
    #(Watchable(a), Watchable(b)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
) -> Nil {
  watch2_with_options(reflikes, callback, None, None, None, None, None, None)
}

pub fn watch3(
  reflikes: #(Watchable(a), Watchable(b), Watchable(c)),
  callback: fn(
    #(Watchable(a), Watchable(b), Watchable(c)),
    #(Watchable(a), Watchable(b), Watchable(c)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
) -> Nil {
  watch3_with_options(reflikes, callback, None, None, None, None, None, None)
}

pub fn watch4(
  reflikes: #(Watchable(a), Watchable(b), Watchable(c), Watchable(d)),
  callback: fn(
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d)),
    #(Watchable(a), Watchable(b), Watchable(c), Watchable(d)),
    Option(fn(fn() -> Nil) -> Nil),
  ) ->
    Nil,
) -> Nil {
  watch4_with_options(reflikes, callback, None, None, None, None, None, None)
}

pub fn watch5(
  reflikes: #(
    Watchable(a),
    Watchable(b),
    Watchable(c),
    Watchable(d),
    Watchable(e),
  ),
  callback: fn(
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
pub fn shallow_ref_set(ref: ShallowRef(value), value: value) -> Ref(value)

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

// Nullable Refs

/// NullableRef auto (un)wraps Option
/// This is a convenience to use with refs used in templates
pub type NullableRef(value)

@external(javascript, "../ffi.mjs", "nullableRef")
pub fn nullable_ref(value: Option(value)) -> NullableRef(value)

@external(javascript, "../ffi.mjs", "nullableValueGet")
pub fn nullable_ref_value(ref: NullableRef(value)) -> Option(value)

@external(javascript, "../ffi.mjs", "nullableValueSet")
pub fn nullable_ref_set(
  ref: NullableRef(value),
  new_value: Option(value),
) -> NullableRef(value)

/// Shallow version of NullableRef
pub type NullableShallowRef(value)

@external(javascript, "../ffi.mjs", "nullableShallowRef")
pub fn nullable_shallow(value: Option(value)) -> NullableShallowRef(value)

@external(javascript, "vue", "triggerRef")
pub fn trigger_nullable_shallow(ref: NullableShallowRef(value)) -> Nil

@external(javascript, "../ffi.mjs", "nullableValueGet")
pub fn nullable_shallow_value(ref: NullableShallowRef(value)) -> Option(value)

@external(javascript, "../ffi.mjs", "nullableValueSet")
pub fn nullable_shallow_set(
  ref: NullableShallowRef(value),
  new_value: Option(value),
) -> NullableShallowRef(value)
