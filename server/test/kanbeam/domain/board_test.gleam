import kanbeam/domain/board

pub fn new_with_valid_data_test() {
  let assert Ok(created) = board.new("board-1", "Projeto")

  assert board.name(created) == "Projeto"
}

pub fn new_with_empty_id_test() {
  let assert Error(board.EmptyId) = board.new("", "Projeto")
}

pub fn new_with_whitespace_only_id_test() {
  let assert Error(board.EmptyId) = board.new("   ", "Projeto")
}

pub fn new_with_empty_name_test() {
  let assert Error(board.EmptyName) = board.new("board-1", "")
}

pub fn new_with_whitespace_only_name_test() {
  let assert Error(board.EmptyName) = board.new("board-1", "   ")
}

pub fn new_prioritizes_invalid_id_test() {
  let assert Error(board.EmptyId) = board.new("", "")
}

pub fn new_trims_name_test() {
  let assert Ok(created) = board.new("board-1", "  Projeto  ")

  assert board.name(created) == "Projeto"
}

pub fn rename_with_valid_name_test() {
  let assert Ok(original) = board.new("board-1", "Projeto")
  let assert Ok(renamed) = board.rename(original, "Novo nome")

  assert board.name(renamed) == "Novo nome"
}

pub fn rename_trims_name_test() {
  let assert Ok(original) = board.new("board-1", "Projeto")
  let assert Ok(renamed) = board.rename(original, "  Novo nome  ")

  assert board.name(renamed) == "Novo nome"
}

pub fn rename_with_empty_name_test() {
  let assert Ok(original) = board.new("board-1", "Projeto")

  let assert Error(board.EmptyName) = board.rename(original, "")
}

pub fn rename_with_whitespace_only_name_test() {
  let assert Ok(original) = board.new("board-1", "Projeto")

  let assert Error(board.EmptyName) = board.rename(original, "   ")
}

pub fn rename_preserves_id_and_original_board_test() {
  let assert Ok(original) = board.new("board-1", "Projeto")
  let assert Ok(renamed) = board.rename(original, "Novo nome")

  assert board.id(original) == board.id(renamed)
  assert board.name(original) == "Projeto"
  assert board.name(renamed) == "Novo nome"
}
