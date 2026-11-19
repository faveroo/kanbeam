import gleam/list
import kanbeam/domain/board
import kanbeam/domain/column
import kanbeam/domain/task

pub opaque type BoardState {
  BoardState(
    board: board.Board,
    columns: List(column.Column),
    tasks: List(task.Task),
  )
}

pub type BoardStateError {
  InvalidColumn
  InvalidTask
}

pub fn new(
  board: board.Board,
  columns: List(column.Column),
  tasks: List(task.Task),
) -> Result(BoardState, BoardStateError) {
  case
    list.all(columns, fn(current_column) {
      column.board_id(current_column) == board.id(board)
    })
  {
    False -> Error(InvalidColumn)
    True -> {
      let valid_tasks =
        list.all(tasks, fn(current_task) {
          list.any(columns, fn(current_column) {
            task.column_id(current_task) == column.id(current_column)
          })
        })

      case valid_tasks {
        False -> Error(InvalidTask)
        True -> Ok(BoardState(board:, columns:, tasks:))
      }
    }
  }
}

pub fn board(state: BoardState) -> board.Board {
  state.board
}

pub fn columns(state: BoardState) -> List(column.Column) {
  state.columns
}

pub fn tasks(state: BoardState) -> List(task.Task) {
  state.tasks
}
