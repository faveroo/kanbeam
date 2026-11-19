import gleam/list
import gleam/result
import kanbeam/domain/column
import kanbeam/domain/task
import kanbeam/domain/task_order

pub type TransferError {
  TaskNotFound
  InvalidPosition
  InvalidDestination
}

pub fn transfer(
  source: List(task.Task),
  destination: List(task.Task),
  task_id: task.TaskId,
  destination_column_id: column.ColumnId,
  position: Int,
) -> Result(#(List(task.Task), List(task.Task)), TransferError) {
  case position >= 0 && position <= list.length(destination) {
    False -> Error(InvalidPosition)
    _ -> {
      case list.find(source, fn(task) { task.id(task) == task_id }) {
        Error(_) -> Error(TaskNotFound)

        Ok(selected) -> {
          case task.column_id(selected) == destination_column_id {
            True -> Error(InvalidDestination)

            _ -> {
              let remaining =
                list.filter(source, fn(task) { task.id(task) != task_id })

              use moved_task <- result.try(
                task.move(selected, destination_column_id, position)
                |> result.map_error(fn(_) { InvalidPosition }),
              )

              let before = list.take(destination, position)
              let after = list.drop(destination, position)

              let updated = list.append(before, [moved_task, ..after])

              use new_source <- result.try(
                task_order.reindex(remaining)
                |> result.map_error(fn(_) { InvalidPosition }),
              )

              use new_destination <- result.try(
                task_order.reindex(updated)
                |> result.map_error(fn(_) { InvalidPosition }),
              )

              Ok(#(new_source, new_destination))
            }
          }
        }
      }
    }
  }
}
