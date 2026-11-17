import kanbeam/domain/column

pub opaque type TaskId {
  TaskId(id: String)
}

pub type Priority {
  High
  Medium
  Low
}

pub opaque type Task {
  Task(
    id: TaskId,
    column_id: column.ColumnId,
    title: String,
    description: String,
    priority: Priority,
    position: String,
  )
}
