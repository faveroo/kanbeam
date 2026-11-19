import gleam/list
import kanbeam/domain/board
import kanbeam/domain/column
import kanbeam/domain/task
import kanbeam/domain/task_transfer

fn create_task(
  id: String,
  column_id: column.ColumnId,
  title: String,
  position: Int,
) -> task.Task {
  let assert Ok(created) =
    task.new(id, column_id, title, "Description: " <> title, task.High, position)
  created
}

fn fixture() -> #(
  List(task.Task),
  List(task.Task),
  column.ColumnId,
  column.ColumnId,
) {
  let assert Ok(parent) = board.new("board-1", "Projeto")
  let assert Ok(origin) = column.new("origin", board.id(parent), "A fazer", 0)
  let assert Ok(target) = column.new("destination", board.id(parent), "Em andamento", 1)
  let origin_id = column.id(origin)
  let destination_id = column.id(target)

  let source = [
    create_task("task-a", origin_id, "A", 0),
    create_task("task-b", origin_id, "B", 1),
    create_task("task-c", origin_id, "C", 2),
  ]
  let destination = [
    create_task("task-d", destination_id, "D", 0),
    create_task("task-e", destination_id, "E", 1),
  ]
  #(source, destination, origin_id, destination_id)
}

fn find_task_id(tasks: List(task.Task), title: String) -> task.TaskId {
  let assert Ok(found) =
    list.find(tasks, fn(current) { task.title(current) == title })
  task.id(found)
}

pub fn transfer_middle_task_into_middle_test() {
  let #(source, destination, origin_id, destination_id) = fixture()
  let selected_id = find_task_id(source, "B")
  let assert Ok(#(new_source, new_destination)) =
    task_transfer.transfer(source, destination, selected_id, destination_id, 1)

  assert list.map(new_source, task.title) == ["A", "C"]
  assert list.map(new_source, task.position) == [0, 1]
  assert list.map(new_destination, task.title) == ["D", "B", "E"]
  assert list.map(new_destination, task.position) == [0, 1, 2]
  assert list.all(new_source, fn(current) { task.column_id(current) == origin_id })
  assert list.all(new_destination, fn(current) { task.column_id(current) == destination_id })
}

pub fn transfer_into_first_position_test() {
  let #(source, destination, _, destination_id) = fixture()
  let assert Ok(#(_, updated)) =
    task_transfer.transfer(source, destination, find_task_id(source, "B"), destination_id, 0)

  assert list.map(updated, task.title) == ["B", "D", "E"]
  assert list.map(updated, task.position) == [0, 1, 2]
}

pub fn transfer_into_last_position_test() {
  let #(source, destination, _, destination_id) = fixture()
  let assert Ok(#(_, updated)) =
    task_transfer.transfer(source, destination, find_task_id(source, "B"), destination_id, 2)

  assert list.map(updated, task.title) == ["D", "E", "B"]
  assert list.map(updated, task.position) == [0, 1, 2]
}

pub fn transfer_into_empty_destination_test() {
  let #(source, _, _, destination_id) = fixture()
  let assert Ok(#(new_source, new_destination)) =
    task_transfer.transfer(source, [], find_task_id(source, "B"), destination_id, 0)

  assert list.map(new_source, task.title) == ["A", "C"]
  assert list.map(new_source, task.position) == [0, 1]
  assert list.map(new_destination, task.title) == ["B"]
  assert list.map(new_destination, task.position) == [0]
}

pub fn transfer_only_source_task_test() {
  let #(source, destination, _, destination_id) = fixture()
  let assert Ok(selected) =
    list.find(source, fn(current) { task.title(current) == "B" })
  let assert Ok(#(new_source, new_destination)) =
    task_transfer.transfer([selected], destination, task.id(selected), destination_id, 1)

  assert new_source == []
  assert list.map(new_destination, task.title) == ["D", "B", "E"]
  assert list.map(new_destination, task.position) == [0, 1, 2]
}

pub fn transfer_last_source_task_test() {
  let #(source, destination, _, destination_id) = fixture()
  let assert Ok(#(new_source, new_destination)) =
    task_transfer.transfer(source, destination, find_task_id(source, "C"), destination_id, 0)

  assert list.map(new_source, task.title) == ["A", "B"]
  assert list.map(new_source, task.position) == [0, 1]
  assert list.map(new_destination, task.title) == ["C", "D", "E"]
}

pub fn transfer_preserves_task_identity_and_fields_test() {
  let #(source, destination, _, destination_id) = fixture()
  let selected_id = find_task_id(source, "B")
  let assert Ok(#(_, new_destination)) =
    task_transfer.transfer(source, destination, selected_id, destination_id, 1)
  let assert Ok(moved) =
    list.find(new_destination, fn(current) { task.id(current) == selected_id })

  assert task.id(moved) == selected_id
  assert task.title(moved) == "B"
  assert task.description(moved) == "Description: B"
  assert task.priority(moved) == task.High
  assert task.column_id(moved) == destination_id
  assert task.position(moved) == 1
}

pub fn transfer_keeps_original_lists_unchanged_test() {
  let #(source, destination, origin_id, destination_id) = fixture()
  let assert Ok(#(new_source, new_destination)) =
    task_transfer.transfer(source, destination, find_task_id(source, "B"), destination_id, 1)

  assert list.map(source, task.title) == ["A", "B", "C"]
  assert list.map(source, task.position) == [0, 1, 2]
  assert list.map(destination, task.title) == ["D", "E"]
  assert list.map(destination, task.position) == [0, 1]
  assert list.all(source, fn(current) { task.column_id(current) == origin_id })
  assert list.map(new_source, task.title) == ["A", "C"]
  assert list.map(new_destination, task.title) == ["D", "B", "E"]
}

pub fn transfer_rejects_negative_position_test() {
  let #(source, destination, _, destination_id) = fixture()
  let assert Error(task_transfer.InvalidPosition) =
    task_transfer.transfer(source, destination, find_task_id(source, "B"), destination_id, -1)
}

pub fn transfer_rejects_position_beyond_destination_length_test() {
  let #(source, destination, _, destination_id) = fixture()
  let assert Error(task_transfer.InvalidPosition) =
    task_transfer.transfer(source, destination, find_task_id(source, "B"), destination_id, 3)
}

pub fn transfer_rejects_positive_position_for_empty_destination_test() {
  let #(source, _, _, destination_id) = fixture()
  let assert Error(task_transfer.InvalidPosition) =
    task_transfer.transfer(source, [], find_task_id(source, "B"), destination_id, 1)
}

pub fn transfer_rejects_missing_task_test() {
  let #(source, destination, origin_id, destination_id) = fixture()
  let missing = create_task("missing", origin_id, "X", 0)
  let assert Error(task_transfer.TaskNotFound) =
    task_transfer.transfer(source, destination, task.id(missing), destination_id, 0)
}

pub fn transfer_rejects_empty_source_test() {
  let #(_, destination, origin_id, destination_id) = fixture()
  let missing = create_task("missing", origin_id, "X", 0)
  let assert Error(task_transfer.TaskNotFound) =
    task_transfer.transfer([], destination, task.id(missing), destination_id, 0)
}

pub fn transfer_rejects_same_column_test() {
  let #(source, destination, origin_id, _) = fixture()
  let assert Error(task_transfer.InvalidDestination) =
    task_transfer.transfer(source, destination, find_task_id(source, "B"), origin_id, 0)
}

pub fn transfer_rejects_same_column_with_empty_destination_test() {
  let #(source, _, origin_id, _) = fixture()
  let assert Error(task_transfer.InvalidDestination) =
    task_transfer.transfer(source, [], find_task_id(source, "B"), origin_id, 0)
}

pub fn transfer_prioritizes_invalid_position_test() {
  let #(source, destination, origin_id, destination_id) = fixture()
  let missing = create_task("missing", origin_id, "X", 0)
  let assert Error(task_transfer.InvalidPosition) =
    task_transfer.transfer(source, destination, task.id(missing), destination_id, -1)
}
