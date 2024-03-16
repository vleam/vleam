import gleam/javascript/promise.{type Promise}
import gleam/javascript/array
import gleam/javascript.{ObjectType}

pub fn new_promise_test() {
  promise.new(fn(resolve) { resolve(1) })
  |> promise.tap(fn(value) {
    let assert 1 = value
  })
}

pub fn new_does_not_collapse_nested_promise_test() {
  promise.new(fn(resolve) { resolve(promise.new(fn(resolve) { resolve(1) })) })
  |> promise.tap(fn(value) {
    // If the `Promise(Promise(Int))` collapsed into `Promise(Int)` (as they
    // do for normal JS promises) then this would fail as the value would be the
    // int value `1`.
    let assert ObjectType = javascript.type_of(value)
  })
}

pub fn map_does_not_collapse_nested_promise_test() -> Promise(Promise(Int)) {
  promise.resolve(1)
  |> promise.map(promise.resolve)
  |> promise.tap(fn(value) {
    // If the `Promise(Promise(Int))` collapsed into `Promise(Int)` (as they
    // do for normal JS promises) then this would fail as the value would be the
    // int value `1`.
    let assert ObjectType = javascript.type_of(value)
  })
}

pub fn await_test() -> Promise(Int) {
  promise.resolve(1)
  |> promise.await(fn(a) { promise.resolve(a + 1) })
  |> promise.tap(fn(a) {
    let assert 2 = a
  })
}

pub fn await_does_not_collapse_nested_promise_test() -> Promise(Int) {
  promise.resolve(1)
  |> promise.await(promise.resolve)
  |> promise.tap(fn(value) {
    let assert 1 = value
  })
}

pub fn map_test() -> Promise(Int) {
  promise.resolve(1)
  |> promise.map(fn(a) { a + 1 })
  |> promise.tap(fn(a) {
    let assert 2 = a
  })
}

pub fn tap_test() -> Promise(Int) {
  promise.resolve(1)
  |> promise.tap(fn(a) { a + 1 })
  |> promise.tap(fn(a) {
    let assert 1 = a
  })
}

pub fn map_try_ok_ok_test() -> Promise(Result(Int, Int)) {
  promise.resolve(Ok(1))
  |> promise.map_try(fn(a) { Ok(a + 1) })
  |> promise.tap(fn(a) {
    let assert Ok(2) = a
  })
}

pub fn map_try_ok_error_test() -> Promise(Result(Int, Int)) {
  promise.resolve(Ok(1))
  |> promise.map_try(fn(a) { Error(a + 1) })
  |> promise.tap(fn(a) {
    let assert Error(2) = a
  })
}

pub fn map_try_error_test() -> Promise(Result(Int, Int)) {
  promise.resolve(Error(1))
  |> promise.map_try(fn(a) { Ok(a + 1) })
  |> promise.tap(fn(a) {
    let assert Error(1) = a
  })
}

pub fn try_await_ok_ok_test() -> Promise(Result(Int, Int)) {
  promise.resolve(Ok(1))
  |> promise.try_await(fn(a) { promise.resolve(Ok(a + 1)) })
  |> promise.tap(fn(a) {
    let assert Ok(2) = a
  })
}

pub fn try_await_ok_error_test() -> Promise(Result(Int, Int)) {
  promise.resolve(Ok(1))
  |> promise.try_await(fn(a) { promise.resolve(Error(a + 1)) })
  |> promise.tap(fn(a) {
    let assert Error(2) = a
  })
}

pub fn try_await_error_test() -> Promise(Result(Int, Int)) {
  promise.resolve(Error(1))
  |> promise.try_await(fn(a) { promise.resolve(Ok(a + 1)) })
  |> promise.tap(fn(a) {
    let assert Error(1) = a
  })
}

pub fn rescue_healthy_test() {
  promise.resolve(1)
  |> promise.rescue(fn(_) { 100 })
  |> promise.tap(fn(a) {
    let assert 1 = a
  })
}

pub fn rescue_poisoned_test() {
  promise.resolve(1)
  |> promise.map(fn(_) {
    let assert 1 = 2
  })
  |> promise.rescue(fn(_) { 100 })
  |> promise.tap(fn(a) {
    let assert 100 = a
  })
}

pub fn await2_test() {
  promise.await2(promise.resolve(1), promise.resolve(3))
  |> promise.tap(fn(x) {
    let assert #(1, 3) = x
  })
}

pub fn await3_test() {
  promise.await3(promise.resolve(1), promise.resolve(3), promise.resolve(4))
  |> promise.tap(fn(x) {
    let assert #(1, 3, 4) = x
  })
}

pub fn await4_test() {
  promise.await4(
    promise.resolve(1),
    promise.resolve(3),
    promise.resolve(4),
    promise.resolve(6),
  )
  |> promise.tap(fn(x) {
    let assert #(1, 3, 4, 6) = x
  })
}

pub fn await5_test() {
  promise.await5(
    promise.resolve(1),
    promise.resolve(3),
    promise.resolve(4),
    promise.resolve(6),
    promise.resolve(10),
  )
  |> promise.tap(fn(x) {
    let assert #(1, 3, 4, 6, 10) = x
  })
}

pub fn await6_test() {
  promise.await6(
    promise.resolve(1),
    promise.resolve(3),
    promise.resolve(4),
    promise.resolve(6),
    promise.resolve(10),
    promise.resolve(13),
  )
  |> promise.tap(fn(x) {
    let assert #(1, 3, 4, 6, 10, 13) = x
  })
}

pub fn await_array_test() {
  promise.await_array(
    array.from_list([
      promise.resolve(1),
      promise.resolve(3),
      promise.resolve(4),
      promise.resolve(6),
      promise.resolve(10),
      promise.resolve(13),
    ]),
  )
  |> promise.tap(fn(x) {
    let assert [1, 3, 4, 6, 10, 13] = array.to_list(x)
  })
}

pub fn await_list_test() {
  promise.await_list([
    promise.resolve(1),
    promise.resolve(3),
    promise.resolve(4),
    promise.resolve(6),
    promise.resolve(10),
    promise.resolve(13),
  ])
  |> promise.tap(fn(x) {
    let assert [1, 3, 4, 6, 10, 13] = x
  })
}
