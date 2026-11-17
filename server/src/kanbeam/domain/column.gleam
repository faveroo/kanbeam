import gleam/string
import kanbeam/domain/board

pub opaque type ColumnId {
  ColumnId(id: String)
}

pub opaque type Column {
  Column(id: ColumnId, board_id: board.BoardId, name: String, position: Int)
}

pub type ColumnError {
  EmptyId
  EmptyName
  InvalidPosition
}

fn column_id_from_string(id: String) -> ColumnId {
  id |> ColumnId
}

pub fn new(
  id: String,
  board_id: board.BoardId,
  name: String,
  position: Int,
) -> Result(Column, ColumnError) {
  let trim_name = string.trim(name)
  let trim_id = string.trim(id)

  case string.is_empty(trim_id), string.is_empty(trim_name), position < 0 {
    True, _, _ -> Error(EmptyId)
    _, True, _ -> Error(EmptyName)
    _, _, True -> Error(InvalidPosition)
    False, False, False ->
      Ok(Column(column_id_from_string(trim_id), board_id, trim_name, position))
  }
}

pub fn id(column: Column) -> ColumnId {
  column.id
}

pub fn board_id(column: Column) -> board.BoardId {
  column.board_id
}

pub fn name(column: Column) -> String {
  column.name
}

pub fn position(column: Column) -> Int {
  column.position
}
