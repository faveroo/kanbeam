import kanbeam/domain/board
import kanbeam/domain/column
import kanbeam/domain/task

fn parent_column_id() -> column.ColumnId {
  let assert Ok(parent) = board.new("board-1", "Projeto")
  let assert Ok(target) = column.new("column-1", board.id(parent), "A fazer", 0)
  column.id(target)
}

pub fn new_with_valid_data_test() {
  let parent_id = parent_column_id()
  let assert Ok(created) =
    task.new("task-1", parent_id, "Implementar API", "Criar endpoints", task.High, 2)

  assert task.column_id(created) == parent_id
  assert task.title(created) == "Implementar API"
  assert task.description(created) == "Criar endpoints"
  assert task.priority(created) == task.High
  assert task.position(created) == 2
}

pub fn new_with_empty_id_test() {
  let assert Error(task.EmptyId) =
    task.new("", parent_column_id(), "Tarefa", "", task.Low, 0)
}

pub fn new_with_whitespace_only_id_test() {
  let assert Error(task.EmptyId) =
    task.new("   ", parent_column_id(), "Tarefa", "", task.Low, 0)
}

pub fn new_with_empty_title_test() {
  let assert Error(task.EmptyTitle) =
    task.new("task-1", parent_column_id(), "", "", task.Low, 0)
}

pub fn new_with_whitespace_only_title_test() {
  let assert Error(task.EmptyTitle) =
    task.new("task-1", parent_column_id(), "   ", "", task.Low, 0)
}

pub fn new_with_negative_position_test() {
  let assert Error(task.InvalidPosition) =
    task.new("task-1", parent_column_id(), "Tarefa", "", task.Low, -1)
}

pub fn new_with_zero_position_test() {
  let assert Ok(created) =
    task.new("task-1", parent_column_id(), "Tarefa", "", task.Low, 0)

  assert task.position(created) == 0
}

pub fn new_trims_id_test() {
  let parent_id = parent_column_id()
  let assert Ok(with_spaces) =
    task.new("  task-1  ", parent_id, "Tarefa", "", task.Low, 0)
  let assert Ok(without_spaces) =
    task.new("task-1", parent_id, "Tarefa", "", task.Low, 0)

  assert task.id(with_spaces) == task.id(without_spaces)
}

pub fn new_trims_title_test() {
  let assert Ok(created) =
    task.new("task-1", parent_column_id(), "  Tarefa  ", "", task.Low, 0)

  assert task.title(created) == "Tarefa"
}

pub fn new_accepts_empty_description_test() {
  let assert Ok(created) =
    task.new("task-1", parent_column_id(), "Tarefa", "", task.Low, 0)

  assert task.description(created) == ""
}

pub fn new_preserves_description_test() {
  let assert Ok(created) =
    task.new("task-1", parent_column_id(), "Tarefa", "  Detalhes  ", task.Low, 0)

  assert task.description(created) == "  Detalhes  "
}

pub fn new_preserves_priority_test() {
  let parent_id = parent_column_id()
  let assert Ok(high) = task.new("high", parent_id, "Alta", "", task.High, 0)
  let assert Ok(medium) = task.new("medium", parent_id, "Média", "", task.Medium, 0)
  let assert Ok(low) = task.new("low", parent_id, "Baixa", "", task.Low, 0)

  assert task.priority(high) == task.High
  assert task.priority(medium) == task.Medium
  assert task.priority(low) == task.Low
}

pub fn new_prioritizes_empty_id_test() {
  let assert Error(task.EmptyId) =
    task.new("", parent_column_id(), "", "", task.Low, -1)
}

pub fn new_prioritizes_empty_title_over_position_test() {
  let assert Error(task.EmptyTitle) =
    task.new("task-1", parent_column_id(), "", "", task.Low, -1)
}
