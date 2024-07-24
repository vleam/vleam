import {
  watch as vueWatch,
  inject as vueInject,
  computed as vueComputed,
  isRef,
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

export function addProps(componentBase, ...props) {
  componentBase.props = {
    ...componentBase.props,
    ...Object.fromEntries(
      props.map((prop, position) => {
        const nullable = prop.default === undefined || prop.default === null;
        const maybeDefault = unwrapOption(prop.default, undefined);
        const required = !nullable && maybeDefault === undefined;
        return [
          prop.name,
          {
            default: maybeDefault,
            required,
            position,
            nullable,
          },
        ];
      }),
    ),
  };
  return componentBase;
}

export function addEmits(componentBase, emits) {
  componentBase.emits = emits.toArray();
  return componentBase;
}

function isOption(maybeOption) {
  return maybeOption instanceof Some || maybeOption instanceof None;
}

function isResult(maybeResult) {
  return maybeResult instanceof Result;
}

function makeTemplateFriendly(value, isNestedProxy) {
  if (value === null) {
    return value;
  } else if (isOption(value)) {
    return unwrapOption(value, null);
  } else if (typeof value === "object" && !isNestedProxy) {
    return new Proxy(value, {
      get(target, key, receiver) {
        const val = Reflect.get(target, key, receiver);
        return makeTemplateFriendly(val, true);
      },
    });
  } else if (typeof value === "function") {
    return (...args) => makeTemplateFriendly(value(...args));
  } else {
    return value;
  }
}

export function addSetup(componentBase, setup) {
  componentBase.setup = (props, { emits }) => {
    const computedNonNullableProps =
      componentBase.props &&
      Object.entries(componentBase.props)
        .filter(([, prop]) => !prop.nullable)
        .sort((a, b) => a[1].position - b[1].position)
        .map(([name]) => vueComputed(() => props[name]));

    const computedNullabledProps =
      componentBase.props &&
      Object.entries(componentBase.props)
        .filter(([, prop]) => prop.nullable)
        .sort((a, b) => a[1].position - b[1].position)
        .map(([name]) =>
          vueComputed(() =>
            isOption(props[name])
              ? props[name]
              : props[name]
                ? new Some(props[name])
                : new None(),
          ),
        );

    const result = setup(
      computedNonNullableProps,
      computedNullabledProps,
      componentBase.emits?.map((name) => (data) => emits(name, data)),
    );

    if (isResult(result) && isOk(result)) {
      const resultObject = Object.fromEntries(
        unwrapOk(result, []).map(([name, value]) => [
          name,
          makeTemplateFriendly(value),
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
