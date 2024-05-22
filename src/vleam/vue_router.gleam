import gleam/dict.{type Dict}
import gleam/option.{type Option}

// Route

pub type RouteLocationNormalizedLoaded

@external(javascript, "vue-router", "useRoute")
pub fn use_route() -> RouteLocationNormalizedLoaded

@external(javascript, "../routerFfi.mjs", "getFullPath")
pub fn full_path(route: RouteLocationNormalizedLoaded) -> String

@external(javascript, "../routerFfi.mjs", "getHash")
pub fn hash(route: RouteLocationNormalizedLoaded) -> String

@external(javascript, "../routerFfi.mjs", "getParams")
pub fn params(route: RouteLocationNormalizedLoaded) -> Dict(String, String)

@external(javascript, "../routerFfi.mjs", "getPath")
pub fn path(route: RouteLocationNormalizedLoaded) -> String

@external(javascript, "../routerFfi.mjs", "getQuery")
pub fn query(
  route: RouteLocationNormalizedLoaded,
) -> Dict(String, Option(String))

// Router

pub type Router

@external(javascript, "vue-router", "useRouter")
pub fn use_router() -> Router

@external(javascript, "../routerFfi.mjs", "getCurrentRoute")
pub fn current_route(router: Router) -> RouteLocationNormalizedLoaded

@external(javascript, "../routerFfi.mjs", "getListening")
pub fn listening(router: Router) -> Bool

@external(javascript, "../routerFfi.mjs", "back")
pub fn back(router: Router) -> Nil

@external(javascript, "../routerFfi.mjs", "forward")
pub fn forward(router: Router) -> Nil

@external(javascript, "../routerFfi.mjs", "go")
pub fn go(router: Router, delta: Int) -> Nil

@external(javascript, "../routerFfi.mjs", "push")
pub fn push(router: Router, to: String) -> Nil

@external(javascript, "../routerFfi.mjs", "replace")
pub fn replace(router: Router, to: String) -> Nil
