import {
  watch as vueWatch,
  ref as vueRef,
  shallowRef as vueShallowRef,
  inject as vueInject,
  computed as vueComputed,
} from "vue";

import { Result, Ok, Error } from "./gleam.mjs";
import {
  Some,
  None,
  unwrap as unwrapOption,
} from "../gleam_stdlib/gleam/option.mjs";
import {
  is_ok as isOk,
  unwrap as unwrapOk,
} from "../gleam_stdlib/gleam/result.mjs";

import { ComponentNotFound } from "./vleam/vue.mjs";

export function getRegisteredComponent(vueApp, componentName) {
  const component = vueApp.component(componentName);

  return component ? new Ok(component) : new Error(new ComponentNotFound());
}

export function registerComponent(vueApp, componentName, component) {
  return vueApp.component(componentName, component);
}

export function defineComponent(components, directives, inheritAttrs) {
  return {
    components: Object.fromEntries(components.toArray()),
    directives: Object.fromEntries(directives.toArray()),
    inheritAttrs,
  };
}

export function addProps(componentBase, props) {
  componentBase.props = Object.fromEntries(
    props.map((prop, position) => {
      const maybeDefault = unwrapOption(prop.default, undefined);
      return [
        prop.name,
        {
          default: maybeDefault,
          required: maybeDefault === undefined,
          position,
        },
      ];
    }),
  );
  return componentBase;
}

export function addEmits(componentBase, emits) {
  componentBase.emits = emits.toArray();
  return componentBase;
}

function isOption(maybeOption) {
  return maybeOption instanceof Some || maybeOption instanceof None;
}

export function addSetup(componentBase, setup) {
  componentBase.setup = (props, { emits }) => {
    const computedProps =
      componentBase.props &&
      Object.entries(componentBase.props)
        .sort((a, b) => a[1].position - b[1].position)
        .map(([name]) => vueComputed(() => props[name]));

    const result = setup(
      computedProps,
      componentBase.emits?.map((name) => (data) => emits(name, data)),
    );

    if (result instanceof Result && isOk(result)) {
      const resultObject = Object.fromEntries(
        unwrapOk(result, []).map(([name, value]) => [
          name,
          isOption(value) ? unwrapOption(value, null) : value,
        ]),
      );
      return resultObject;
    } else {
      throw result;
    }
  };
  return componentBase;
}

export function reflikeValue(reflike) {
  return reflike.value;
}

export function refSet(ref, newValue) {
  ref.value = newValue;
  return ref;
}

export function nullableComputed(callback) {
  return vueComputed(() => unwrapOption(callback(), null));
}

export function nullableRef(option) {
  return vueRef(unwrapOption(option, null));
}

export function nullableShallowRef(option) {
  return vueShallowRef(unwrapOption(option, null));
}

export function nullableValueGet(nullableReflike) {
  return nullableReflike.value ? new Some(nullableReflike.value) : new None();
}

export function nullableValueSet(nullableReflike, newOption) {
  nullableReflike.value = unwrapOption(newOption, null);
  return nullableReflike;
}

export function watch(
  reflikes,
  callback,
  immediate,
  deep,
  flush,
  onTrack,
  onTrigger,
  once,
) {
  return vueWatch(
    reflikes.map((w) => w.watchable),
    callback,
    {
      immediate: unwrapOption(immediate, undefined),
      deep: unwrapOption(deep, undefined),
      flush: unwrapOption(flush, undefined),
      onTrack: unwrapOption(onTrack, undefined),
      onTrigger: unwrapOption(onTrigger, undefined),
      once: unwrapOption(once, undefined),
    },
  );
}

export function inject(key) {
  const value = vueInject(key);
  return value ? new Some(value) : new None();
}

export function injectWithDefault(key, defaultValue) {
  return vueInject(key, defaultValue);
}

export function injectWithFactory(key, factory) {
  return vueInject(key, factory, true);
}
