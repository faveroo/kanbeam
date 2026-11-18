import gleam/list
import kanbeam/domain/task

pub type ReorderError {
  TaskNotFound
  InvalidPosition
}

pub fn reorder(
  tasks: List(task.Task),
  task_id: task.TaskId,
  new_position: Int,
) -> Result(List(task.Task), ReorderError) {
  let total = list.length(tasks)
  case new_position < 0 || new_position >= total {
    True -> Error(InvalidPosition)
    False -> {
      case list.find(tasks, fn(current) { task.id(current) == task_id }) {
        Error(_) -> Error(TaskNotFound)

        Ok(selected) -> {
          let remaining =
            list.filter(tasks, fn(task) { task.id(task) != task_id })
          let before = list.take(remaining, new_position)
          let after = list.drop(remaining, new_position)
          let reordered = list.append(before, [selected, ..after])

          case reindex(reordered) {
            Ok(updated) -> Ok(updated)
            Error(_) -> Error(InvalidPosition)
          }
        }
      }
    }
  }
}

pub fn reindex(
  tasks: List(task.Task),
) -> Result(List(task.Task), task.TaskError) {
  tasks
  |> list.index_map(fn(current, index) {
    task.move(current, task.column_id(current), index)
  })
  |> list.try_map(fn(result) { result })
}
