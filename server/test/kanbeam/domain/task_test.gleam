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

fn example_task() -> task.Task {
  let assert Ok(created) =
    task.new("task-1", parent_column_id(), "Implementar API", "Criar endpoints", task.High, 2)
  created
}

fn destination_column_id() -> column.ColumnId {
  let assert Ok(parent) = board.new("board-1", "Projeto")
  let assert Ok(destination) =
    column.new("column-2", board.id(parent), "Em andamento", 1)
  column.id(destination)
}

pub fn rename_changes_title_test() {
  let original = example_task()
  let assert Ok(renamed) = task.rename(original, "Implementar autenticação")

  assert task.title(renamed) == "Implementar autenticação"
}

pub fn rename_trims_title_test() {
  let assert Ok(renamed) = task.rename(example_task(), "  Novo título  ")

  assert task.title(renamed) == "Novo título"
}

pub fn rename_rejects_empty_title_test() {
  let assert Error(task.EmptyTitle) = task.rename(example_task(), "")
}

pub fn rename_rejects_whitespace_only_title_test() {
  let assert Error(task.EmptyTitle) = task.rename(example_task(), "   ")
}

pub fn rename_preserves_other_fields_test() {
  let original = example_task()
  let assert Ok(renamed) = task.rename(original, "Novo título")

  assert task.id(renamed) == task.id(original)
  assert task.column_id(renamed) == task.column_id(original)
  assert task.description(renamed) == task.description(original)
  assert task.priority(renamed) == task.priority(original)
  assert task.position(renamed) == task.position(original)
}

pub fn rename_keeps_original_unchanged_test() {
  let original = example_task()
  let assert Ok(renamed) = task.rename(original, "Novo título")

  assert task.title(original) == "Implementar API"
  assert task.title(renamed) == "Novo título"
}

pub fn change_priority_to_low_test() {
  let changed = task.change_priority(example_task(), task.Low)

  assert task.priority(changed) == task.Low
}

pub fn change_priority_to_medium_test() {
  let changed = task.change_priority(example_task(), task.Medium)

  assert task.priority(changed) == task.Medium
}

pub fn change_priority_preserves_other_fields_test() {
  let original = example_task()
  let changed = task.change_priority(original, task.Low)

  assert task.id(changed) == task.id(original)
  assert task.column_id(changed) == task.column_id(original)
  assert task.title(changed) == task.title(original)
  assert task.description(changed) == task.description(original)
  assert task.position(changed) == task.position(original)
}

pub fn change_priority_keeps_original_unchanged_test() {
  let original = example_task()
  let changed = task.change_priority(original, task.Low)

  assert task.priority(original) == task.High
  assert task.priority(changed) == task.Low
}

pub fn move_to_another_column_test() {
  let destination = destination_column_id()
  let assert Ok(moved) = task.move(example_task(), destination, 3)

  assert task.column_id(moved) == destination
  assert task.position(moved) == 3
}

pub fn move_within_same_column_test() {
  let original = example_task()
  let assert Ok(moved) = task.move(original, task.column_id(original), 4)

  assert task.column_id(moved) == task.column_id(original)
  assert task.position(moved) == 4
}

pub fn move_accepts_zero_position_test() {
  let assert Ok(moved) =
    task.move(example_task(), destination_column_id(), 0)

  assert task.position(moved) == 0
}

pub fn move_rejects_negative_position_test() {
  let assert Error(task.InvalidPosition) =
    task.move(example_task(), destination_column_id(), -1)
}

pub fn move_preserves_other_fields_test() {
  let original = example_task()
  let assert Ok(moved) = task.move(original, destination_column_id(), 0)

  assert task.id(moved) == task.id(original)
  assert task.title(moved) == task.title(original)
  assert task.description(moved) == task.description(original)
  assert task.priority(moved) == task.priority(original)
}

pub fn move_keeps_original_unchanged_test() {
  let original = example_task()
  let destination = destination_column_id()
  let assert Ok(moved) = task.move(original, destination, 0)

  assert task.column_id(original) == parent_column_id()
  assert task.position(original) == 2
  assert task.column_id(moved) == destination
  assert task.position(moved) == 0
}
