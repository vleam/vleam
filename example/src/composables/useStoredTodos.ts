import { useLocalStorage } from '@vueuse/core'

import { List } from '@gleam-build/gleam_stdlib/gleam/list.mjs'

import {
  to_json_string as toJsonString,
  from_json_string as fromJsonString,
  Todo
} from '../vleam_todo/models.gleam'

const STORAGE_KEY = 'vleam-todo'

export function useStoredTodos() {
  return useLocalStorage(STORAGE_KEY, [], {
    serializer: {
      read: (str?: string) =>
        str ? List.fromArray(JSON.parse(str).map((v: string) => fromJsonString(v))) : [],
      write: (list: List<Todo>) => JSON.stringify(list.toArray().map((v: Todo) => toJsonString(v)))
    }
  })
}
