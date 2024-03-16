import gleam/javascript.{
  BooleanType, FunctionType, NumberType, ObjectType, StringType, SymbolType,
  UndefinedType,
}
import gleeunit/should

pub fn type_of_test() {
  let assert UndefinedType = javascript.type_of(Nil)
  let assert NumberType = javascript.type_of(1)
  let assert NumberType = javascript.type_of(1.1)
  let assert BooleanType = javascript.type_of(True)
  let assert BooleanType = javascript.type_of(False)
  let assert StringType = javascript.type_of("ok")
  let assert StringType = javascript.type_of("")
  let assert FunctionType = javascript.type_of(fn() { 1 })
  let assert FunctionType = javascript.type_of(fn(x) { x })
  let assert FunctionType = javascript.type_of(type_of_test)
  let assert FunctionType = javascript.type_of(Ok)
  let assert ObjectType = javascript.type_of(Ok(1))
  let assert ObjectType = javascript.type_of(Error("ok"))
  let assert SymbolType = javascript.type_of(javascript.get_symbol("Gleam"))
}

pub fn find_symbol_test() {
  let assert True =
    javascript.get_symbol("Gleam") == javascript.get_symbol("Gleam")
  let assert False =
    javascript.get_symbol("Gleam") == javascript.get_symbol("Lua")
}

pub fn reference_test() {
  let ref = javascript.make_reference(1)
  let assert 1 = javascript.update_reference(ref, fn(a) { a + 1 })
  let assert 2 = javascript.dereference(ref)
  let assert 2 = javascript.set_reference(ref, 3)
  let assert 3 = javascript.dereference(ref)
}

pub fn reference_equality_test() {
  javascript.make_reference(0)
  |> javascript.reference_equal(javascript.make_reference(0))
  |> should.equal(False)

  let ref = javascript.make_reference(0)
  javascript.reference_equal(ref, ref)
  |> should.equal(True)
}
