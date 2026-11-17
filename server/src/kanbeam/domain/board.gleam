import gleam/string

pub opaque type Board {
  Board(id: BoardId, name: String)
}

pub type BoardError {
  EmptyId
  EmptyName
}

pub type BoardId {
  BoardId(id: String)
}

pub fn new(id: String, name: String) -> Result(Board, BoardError) {
  let trim_name = string.trim(name)
  let trim_id = string.trim(id)
  case string.is_empty(trim_id), string.is_empty(trim_name) {
    True, _ -> Error(EmptyId)
    _, True -> Error(EmptyName)
    False, False -> Ok(Board(board_id_from_string(trim_id), trim_name))
  }
}

pub fn id(board: Board) -> BoardId {
  board.id
}

fn board_id_from_string(id: String) -> BoardId {
  id |> BoardId
}

pub fn name(board: Board) -> String {
  board.name
}

pub fn rename(board: Board, new_name: String) -> Result(Board, BoardError) {
  let trim_name = string.trim(new_name)
  case string.is_empty(trim_name) {
    True -> Error(EmptyName)
    _ -> Ok(Board(..board, name: trim_name))
  }
}
