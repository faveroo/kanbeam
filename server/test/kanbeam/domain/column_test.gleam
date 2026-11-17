import kanbeam/domain/board
import kanbeam/domain/column

fn parent_board_id() -> board.BoardId {
  let assert Ok(parent) = board.new("board-1", "Projeto")
  board.id(parent)
}

pub fn new_with_valid_data_test() {
  let assert Ok(created) =
    column.new("column-1", parent_board_id(), "A fazer", 1)

  assert column.name(created) == "A fazer"
  assert column.position(created) == 1
}

pub fn new_with_empty_id_test() {
  let assert Error(column.EmptyId) =
    column.new("", parent_board_id(), "A fazer", 0)
}

pub fn new_with_whitespace_only_id_test() {
  let assert Error(column.EmptyId) =
    column.new("   ", parent_board_id(), "A fazer", 0)
}

pub fn new_with_empty_name_test() {
  let assert Error(column.EmptyName) =
    column.new("column-1", parent_board_id(), "", 0)
}

pub fn new_with_whitespace_only_name_test() {
  let assert Error(column.EmptyName) =
    column.new("column-1", parent_board_id(), "   ", 0)
}

pub fn new_with_negative_position_test() {
  let assert Error(column.InvalidPosition) =
    column.new("column-1", parent_board_id(), "A fazer", -1)
}

pub fn new_with_zero_position_test() {
  let assert Ok(created) =
    column.new("column-1", parent_board_id(), "A fazer", 0)

  assert column.position(created) == 0
}

pub fn new_trims_id_test() {
  let parent_id = parent_board_id()
  let assert Ok(with_spaces) =
    column.new("  column-1  ", parent_id, "A fazer", 0)
  let assert Ok(without_spaces) =
    column.new("column-1", parent_id, "A fazer", 0)

  assert column.id(with_spaces) == column.id(without_spaces)
}

pub fn new_trims_name_test() {
  let assert Ok(created) =
    column.new("column-1", parent_board_id(), "  A fazer  ", 0)

  assert column.name(created) == "A fazer"
}

pub fn new_preserves_board_id_test() {
  let parent_id = parent_board_id()
  let assert Ok(created) =
    column.new("column-1", parent_id, "A fazer", 0)

  assert column.board_id(created) == parent_id
}

pub fn new_prioritizes_empty_id_test() {
  let assert Error(column.EmptyId) =
    column.new("", parent_board_id(), "", -1)
}

pub fn new_prioritizes_empty_name_over_invalid_position_test() {
  let assert Error(column.EmptyName) =
    column.new("column-1", parent_board_id(), "", -1)
}
