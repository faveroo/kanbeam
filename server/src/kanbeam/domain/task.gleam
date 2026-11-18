import gleam/string
import kanbeam/domain/column

pub opaque type TaskId {
  TaskId(id: String)
}

pub type Priority {
  High
  Medium
  Low
}

pub type TaskError {
  EmptyId
  EmptyTitle
  InvalidPosition
}

pub opaque type Task {
  Task(
    id: TaskId,
    column_id: column.ColumnId,
    title: String,
    description: String,
    priority: Priority,
    position: Int,
  )
}

pub fn new(
  id: String,
  column_id: column.ColumnId,
  title: String,
  description: String,
  priority: Priority,
  position: Int,
) -> Result(Task, TaskError) {
  let id = string.trim(id) |> TaskId
  let title = string.trim(title)

  case string.is_empty(id.id), string.is_empty(title), position < 0 {
    True, _, _ -> Error(EmptyId)
    _, True, _ -> Error(EmptyTitle)
    _, _, True -> Error(InvalidPosition)
    False, False, False ->
      Ok(Task(id, column_id, title, description, priority, position))
  }
}
