import { useLocalStorage } from '@vueuse/core'

// Use Gleam types in TS/JS
import { List } from '/build/dev/javascript/vue_gleam_example/gleam.mjs'
import { unwrap as unwrapResult } from '/build/dev/javascript/gleam_stdlib/gleam/result.mjs'

// Use your Gleam code in TS/JS
import {
  to_json_string as toJsonString,
  from_json_string as fromJsonString,
  Todo
} from '../vleam_todo/models.gleam'

const STORAGE_KEY = 'vleam-todo'

export function useStoredTodos() {
  return useLocalStorage(STORAGE_KEY, List.fromArray([]), {
    serializer: {
      read: (str?: string) => {
        const arr = str
          ? JSON.parse(str)
              .map((v: string) => unwrapResult(fromJsonString(v), null))
              .filter((t: any) => !!t)
          : []
        return List.fromArray(arr)
      },
      write: (list: List<Todo>) => {
        return JSON.stringify(list.toArray().map((v: Todo) => toJsonString(v)))
      }
    }
  })
}
