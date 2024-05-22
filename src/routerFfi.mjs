import Dict from "../gleam_stdlib/dict.mjs";

import { Some, None } from "../gleam_stdlib/gleam/option.mjs";

export function getFullPath(route) {
  return route.fullPath;
}

export function getHash(route) {
  return route.hash;
}

export function getParams(route) {
  return Dict.fromObject(route.params);
}

export function getPath(route) {
  return route.path;
}

export function getQuery(route) {
  return Dict.fromObject(
    Object.fromEntries(
      Object.entries(route.query).map(([k, v]) => [k, v ? Some(v) : None]),
    ),
  );
}

export function getCurrentRoute(router) {
  return router.currentRoute;
}

export function getListening(router) {
  return router.listening;
}

export function back(router) {
  router.back();
}

export function forward(router) {
  router.forward();
}

export function go(router, delta) {
  router.go(delta);
}

export function push(router, to) {
  router.push(to);
}

export function replace(router, to) {
  router.replace(to);
}
