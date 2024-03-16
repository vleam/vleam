import gleam/dynamic
import gleam/json

import birl

pub type TodoError {
  EmptyTitle
}

pub type Todo {
  Todo(id: Int, title: String, completed: Bool)
}

pub fn new_todo(title: String) -> Todo {
  Todo(
    id: 1000
      * {
      birl.now()
      |> birl.to_unix
    },
    title: title,
    completed: False,
  )
}

pub fn from_json_string(source: String) -> Result(Todo, json.DecodeError) {
  source
  |> json.decode(dynamic.decode3(
    Todo,
    dynamic.field("id", dynamic.int),
    dynamic.field("title", dynamic.string),
    dynamic.field("completed", dynamic.bool),
  ))
}

pub fn to_json_string(source: Todo) -> String {
  json.to_string(
    json.object([
      #("id", json.int(source.id)),
      #("title", json.string(source.title)),
      #("completed", json.bool(source.completed)),
    ]),
  )
}
