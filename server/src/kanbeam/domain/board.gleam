import gleam/string

pub opaque type Board {
  Board(id: BoardId, name: String)
}

pub type BoardError {
  EmptyId
  EmptyName
}

pub opaque type BoardId {
  BoardId(id: String)
}

pub fn new(id: String, name: String) -> Result(Board, BoardError) {
  let name = string.trim(name)
  let id = string.trim(id) |> BoardId
  case string.is_empty(id.id), string.is_empty(name) {
    True, _ -> Error(EmptyId)
    _, True -> Error(EmptyName)
    False, False -> Ok(Board(id, name))
  }
}

pub fn id(board: Board) -> BoardId {
  board.id
}

pub fn name(board: Board) -> String {
  board.name
}

pub fn rename(board: Board, new_name: String) -> Result(Board, BoardError) {
  let new_name = string.trim(new_name)
  case string.is_empty(new_name) {
    True -> Error(EmptyName)
    _ -> Ok(Board(..board, name: new_name))
  }
}
