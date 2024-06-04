<script lang="gleam">
import gleam/bool
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import vleam/vue.{
  type Component, define_component, ref_set, ref_value, setup, shallow_ref_set,
  shallow_ref_value, watch1,
}

import vleam_todo/models.{type Todo, Todo, new_todo}

@external(javascript, "/src/composables/useStoredTodos", "useStoredTodos")
fn use_local_todos() -> vue.Ref(List(Todo))

// Sample external component
@external(javascript, "/src/components/Title.vue", "default")
fn title_component() -> Component

pub fn default_export() -> Component {
  define_component([#("Title", title_component)], [], False)
  |> setup(fn(_, _) {
    let todos_list: vue.Ref(List(Todo)) = use_local_todos()
    let todos_dict: vue.ShallowRef(dict.Dict(Int, Todo)) =
      todos_list
      |> vue.ref_value
      |> list.map(fn(t) { #(t.id, t) })
      |> dict.from_list
      |> vue.shallow_ref

    watch1(#(vue.ShallowRef(todos_dict)), fn(_, _, _) {
      todos_list
      |> ref_set(
        todos_dict
        |> vue.shallow_ref_value
        |> dict.values,
      )

      Nil
    })

    let remaining =
      vue.computed(fn() {
        todos_list
        |> vue.ref_value
        |> list.map(fn(todo_item) {
          !todo_item.completed
          |> bool.to_int
        })
        |> int.sum
      })

    let toggle_all = fn() {
      let toggle_to =
        remaining
        |> vue.computed_value
        != 0

      let toggled_todos =
        todos_dict
        |> shallow_ref_value
        |> dict.map_values(fn(_, t) { Todo(..t, completed: toggle_to) })

      todos_dict
      |> shallow_ref_set(toggled_todos)
    }

    let new_title_draft = vue.ref("")

    let add_todo = fn(new_title: String) {
      let new_todo = models.new_todo(new_title)

      let new_todos =
        todos_dict
        |> shallow_ref_value
        |> dict.insert(new_todo.id, new_todo)

      todos_dict
      |> shallow_ref_set(new_todos)

      new_title_draft
      |> ref_set("")
    }

    let remove_todo = fn(target: Todo) {
      let new_todos =
        todos_dict
        |> shallow_ref_value
        |> dict.delete(target.id)

      todos_dict
      |> shallow_ref_set(new_todos)
    }

    let todo_id_to_edit = vue.ref(-1)
    let edited_title_draft = vue.ref("")

    let edit_todo = fn(todo_to_edit: Todo) {
      edited_title_draft
      |> ref_set(todo_to_edit.title)

      todo_id_to_edit
      |> ref_set(todo_to_edit.id)
    }

    let reset_edit = fn() {
      todo_id_to_edit
      |> ref_set(-1)

      edited_title_draft
      |> ref_set("")
    }

    let done_edit = fn() {
      let new_todos = case
        edited_title_draft
        |> ref_value
        |> string.length
        > 0
      {
        True -> {
          todos_dict
          |> shallow_ref_value
          |> dict.update(
            todo_id_to_edit
              |> ref_value,
            fn(maybe_t) {
              case maybe_t {
                Some(t) -> Todo(..t, title: ref_value(edited_title_draft))
                None -> new_todo(ref_value(edited_title_draft))
              }
            },
          )
        }
        False -> {
          todos_dict
          |> shallow_ref_value
          |> dict.delete(
            todo_id_to_edit
            |> ref_value,
          )
        }
      }

      todos_dict
      |> shallow_ref_set(new_todos)

      reset_edit()
    }

    let remove_completed = fn() {
      let new_todos =
        todos_dict
        |> shallow_ref_value
        |> dict.filter(fn(_, t) { !t.completed })

      todos_dict
      |> shallow_ref_set(new_todos)
    }

    let visibility = vue.ref("all")

    Ok(#(
      #("removeCompleted", remove_completed),
      #("toggleAll", toggle_all),
      #("addTodo", add_todo),
      #("removeTodo", remove_todo),
      #("idToEdit", todo_id_to_edit),
      #("editedTitleDraft", edited_title_draft),
      #("editTodo", edit_todo),
      #("cancelEdit", reset_edit),
      #("doneEdit", done_edit),
      #("todos", todos_list),
      // TODO: implement filters
      #("filteredTodos", todos_list),
      #("visibility", visibility),
      #("remaining", remaining),
      #("newTitleDraft", new_title_draft),
    ))
  })
}
</script>

<!-- 

This TodoMVP Template from the Vue website simulates using Gleam with a 
minimally changed template in an existing codebase

-->
<template>
  <section class="todoapp">
    <header class="header">
      <h1><Title /></h1>
      <input
        v-model="newTitleDraft"
        class="new-todo"
        autofocus
        placeholder="What needs to be done?"
        @keyup.enter="
          () => {
            addTodo(newTitleDraft)
          }
        "
      />
    </header>
    <section class="main" v-show="todos.toArray().length">
      <input
        id="toggle-all"
        class="toggle-all"
        type="checkbox"
        :checked="remaining === 0"
        @change="() => toggleAll()"
      />
      <label for="toggle-all">Mark all as complete</label>
      <ul class="todo-list">
        <li
          v-for="todo in filteredTodos.toArray()"
          class="todo"
          :key="todo.id"
          :class="{ completed: todo.completed, editing: todo.id === idToEdit }"
        >
          <div class="view">
            <input class="toggle" type="checkbox" v-model="todo.completed" />
            <label @dblclick="editTodo(todo)">{{ todo.title }}</label>
            <button class="destroy" @click="removeTodo(todo)"></button>
          </div>
          <input
            v-if="todo.id === idToEdit"
            class="edit"
            type="text"
            v-model="editedTitleDraft"
            @vue:mounted="({ el }) => el.focus()"
            @blur="doneEdit(todo)"
            @keyup.enter="doneEdit(todo)"
            @keyup.escape="cancelEdit(todo)"
          />
        </li>
      </ul>
    </section>
    <footer class="footer" v-show="todos.length">
      <span class="todo-count">
        <strong>{{ remaining }}</strong>
        <span>{{ remaining === 1 ? ' item' : ' items' }} left</span>
      </span>
      <ul class="filters">
        <li>
          <a href="#/all" :class="{ selected: visibility === 'all' }">All</a>
        </li>
        <li>
          <a href="#/active" :class="{ selected: visibility === 'active' }">Active</a>
        </li>
        <li>
          <a href="#/completed" :class="{ selected: visibility === 'completed' }">Completed</a>
        </li>
      </ul>
      <button class="clear-completed" @click="removeCompleted" v-show="todos.length > remaining">
        Clear completed
      </button>
    </footer>
  </section>
</template>

<style>
@import 'https://unpkg.com/todomvc-app-css@2.4.1/index.css';
</style>
