import gleam/javascript/array

pub fn to_and_from_list_test() {
  let assert [] =
    []
    |> array.from_list
    |> array.to_list

  let assert [1, 2, 3] =
    [1, 2, 3]
    |> array.from_list
    |> array.to_list
}

pub fn size_test() {
  let assert 0 =
    array.from_list([])
    |> array.size

  let assert 2 =
    array.from_list([1, 2])
    |> array.size
}

pub fn map_test() {
  let assert [] =
    []
    |> array.from_list
    |> array.map(fn(a) { a + 1 })
    |> array.to_list

  let assert [2, 3, 4] =
    [1, 2, 3]
    |> array.from_list
    |> array.map(fn(a) { a + 1 })
    |> array.to_list
}

pub fn fold_test() {
  let assert [] =
    []
    |> array.from_list
    |> array.fold([], fn(a, e) { [e, ..a] })

  let assert [4, 3, 2, 1] =
    [1, 2, 3, 4]
    |> array.from_list
    |> array.fold([], fn(a, e) { [e, ..a] })

  let assert [1, 2, 3, 4] =
    [4, 3, 2, 1]
    |> array.from_list
    |> array.fold([], fn(a, e) { [e, ..a] })
}

pub fn fold_right_test() {
  let assert [] =
    []
    |> array.from_list
    |> array.fold_right([], fn(a, e) { [e, ..a] })

  let assert [1, 2, 3, 4] =
    [1, 2, 3, 4]
    |> array.from_list
    |> array.fold_right([], fn(a, e) { [e, ..a] })

  let assert [4, 3, 2, 1] =
    [4, 3, 2, 1]
    |> array.from_list
    |> array.fold_right([], fn(a, e) { [e, ..a] })
}

pub fn index_test() {
  let assert Ok(1) =
    [1, 2]
    |> array.from_list
    |> array.get(0)

  let assert Ok(2) =
    [1, 2]
    |> array.from_list
    |> array.get(1)

  let assert Error(Nil) =
    [1, 2]
    |> array.from_list
    |> array.get(2)

  let assert Error(Nil) =
    [1, 2]
    |> array.from_list
    |> array.get(-1)
}
