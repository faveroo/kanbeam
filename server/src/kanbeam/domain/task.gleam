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

pub fn priority(task: Task) -> Priority {
  task.priority
}

pub fn title(task: Task) -> String {
  task.title
}

pub fn description(task: Task) -> String {
  task.description
}

pub fn id(task: Task) -> TaskId {
  task.id
}

pub fn position(task: Task) -> Int {
  task.position
}

pub fn column_id(task: Task) -> column.ColumnId {
  task.column_id
}

pub fn rename(task: Task, new_title: String) -> Result(Task, TaskError) {
  let new_title = string.trim(new_title)

  case string.is_empty(new_title) {
    True -> Error(EmptyTitle)
    _ -> Ok(Task(..task, title: new_title))
  }
}

pub fn change_priority(task: Task, new_priority: Priority) -> Task {
  Task(..task, priority: new_priority)
}

pub fn move(
  task: Task,
  to: column.ColumnId,
  position: Int,
) -> Result(Task, TaskError) {
  case position < 0 {
    True -> Error(InvalidPosition)
    _ -> Ok(Task(..task, column_id: to, position:))
  }
}
