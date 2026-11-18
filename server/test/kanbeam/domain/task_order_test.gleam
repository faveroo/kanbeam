import gleam/list
import kanbeam/domain/board
import kanbeam/domain/column
import kanbeam/domain/task
import kanbeam/domain/task_order

fn example_column_id() -> column.ColumnId {
  let assert Ok(parent) = board.new("board-1", "Projeto")
  let assert Ok(created) = column.new("column-1", board.id(parent), "A fazer", 0)
  column.id(created)
}

fn make_task(
  id: String,
  column_id: column.ColumnId,
  title: String,
  position: Int,
) -> task.Task {
  let assert Ok(created) =
    task.new(id, column_id, title, "Descrição " <> title, task.Medium, position)
  created
}

fn example_tasks() -> List(task.Task) {
  let parent = example_column_id()
  [
    make_task("task-a", parent, "A", 0),
    make_task("task-b", parent, "B", 1),
    make_task("task-c", parent, "C", 2),
    make_task("task-d", parent, "D", 3),
  ]
}

fn id_by_title(tasks: List(task.Task), title: String) -> task.TaskId {
  let assert Ok(found) =
    list.find(tasks, fn(current) { task.title(current) == title })
  task.id(found)
}

pub fn reindex_empty_list_test() {
  let assert Ok(updated) = task_order.reindex([])

  assert updated == []
}

pub fn reindex_resets_positions_test() {
  let parent = example_column_id()
  let tasks = [
    make_task("task-a", parent, "A", 8),
    make_task("task-b", parent, "B", 3),
    make_task("task-c", parent, "C", 12),
  ]

  let assert Ok(updated) = task_order.reindex(tasks)

  assert list.map(updated, task.position) == [0, 1, 2]
}

pub fn reindex_keeps_list_order_test() {
  let parent = example_column_id()
  let tasks = [
    make_task("task-c", parent, "C", 9),
    make_task("task-a", parent, "A", 0),
    make_task("task-b", parent, "B", 5),
  ]

  let assert Ok(updated) = task_order.reindex(tasks)

  assert list.map(updated, task.title) == ["C", "A", "B"]
}

pub fn reindex_preserves_task_data_test() {
  let parent = example_column_id()
  let original = make_task("task-a", parent, "A", 9)
  let assert Ok(updated) = task_order.reindex([original])
  let assert [first] = updated

  assert task.id(first) == task.id(original)
  assert task.column_id(first) == task.column_id(original)
  assert task.title(first) == task.title(original)
  assert task.description(first) == task.description(original)
  assert task.priority(first) == task.priority(original)
  assert task.position(first) == 0
}

pub fn reindex_keeps_original_unchanged_test() {
  let original = make_task("task-a", example_column_id(), "A", 9)
  let assert Ok(updated) = task_order.reindex([original])
  let assert [first] = updated

  assert task.position(original) == 9
  assert task.position(first) == 0
}

pub fn reorder_middle_to_last_test() {
  let tasks = example_tasks()
  let assert Ok(updated) =
    task_order.reorder(tasks, id_by_title(tasks, "B"), 3)

  assert list.map(updated, task.title) == ["A", "C", "D", "B"]
  assert list.map(updated, task.position) == [0, 1, 2, 3]
}

pub fn reorder_last_to_first_test() {
  let tasks = example_tasks()
  let assert Ok(updated) =
    task_order.reorder(tasks, id_by_title(tasks, "D"), 0)

  assert list.map(updated, task.title) == ["D", "A", "B", "C"]
  assert list.map(updated, task.position) == [0, 1, 2, 3]
}

pub fn reorder_first_to_middle_test() {
  let tasks = example_tasks()
  let assert Ok(updated) =
    task_order.reorder(tasks, id_by_title(tasks, "A"), 2)

  assert list.map(updated, task.title) == ["B", "C", "A", "D"]
  assert list.map(updated, task.position) == [0, 1, 2, 3]
}

pub fn reorder_first_to_last_test() {
  let tasks = example_tasks()
  let assert Ok(updated) =
    task_order.reorder(tasks, id_by_title(tasks, "A"), 3)

  assert list.map(updated, task.title) == ["B", "C", "D", "A"]
  assert list.map(updated, task.position) == [0, 1, 2, 3]
}

pub fn reorder_same_position_test() {
  let tasks = example_tasks()
  let assert Ok(updated) =
    task_order.reorder(tasks, id_by_title(tasks, "B"), 1)

  assert list.map(updated, task.title) == ["A", "B", "C", "D"]
  assert list.map(updated, task.position) == [0, 1, 2, 3]
}

pub fn reorder_single_task_test() {
  let only = make_task("task-a", example_column_id(), "A", 0)
  let assert Ok(updated) = task_order.reorder([only], task.id(only), 0)

  assert list.map(updated, task.title) == ["A"]
  assert list.map(updated, task.position) == [0]
}

pub fn reorder_negative_position_test() {
  let tasks = example_tasks()

  let assert Error(task_order.InvalidPosition) =
    task_order.reorder(tasks, id_by_title(tasks, "B"), -1)
}

pub fn reorder_position_equal_to_length_test() {
  let tasks = example_tasks()

  let assert Error(task_order.InvalidPosition) =
    task_order.reorder(tasks, id_by_title(tasks, "B"), 4)
}

pub fn reorder_position_greater_than_length_test() {
  let tasks = example_tasks()

  let assert Error(task_order.InvalidPosition) =
    task_order.reorder(tasks, id_by_title(tasks, "B"), 99)
}

pub fn reorder_missing_task_test() {
  let tasks = example_tasks()
  let missing = make_task("missing", example_column_id(), "X", 0)

  let assert Error(task_order.TaskNotFound) =
    task_order.reorder(tasks, task.id(missing), 1)
}

pub fn reorder_empty_list_test() {
  let missing = make_task("missing", example_column_id(), "X", 0)

  let assert Error(task_order.InvalidPosition) =
    task_order.reorder([], task.id(missing), 0)
}

pub fn reorder_preserves_moved_task_fields_test() {
  let tasks = example_tasks()
  let moved_id = id_by_title(tasks, "B")
  let assert Ok(updated) = task_order.reorder(tasks, moved_id, 3)
  let assert Ok(moved) =
    list.find(updated, fn(current) { task.id(current) == moved_id })

  assert task.id(moved) == moved_id
  assert task.column_id(moved) == example_column_id()
  assert task.title(moved) == "B"
  assert task.description(moved) == "Descrição B"
  assert task.priority(moved) == task.Medium
  assert task.position(moved) == 3
}

pub fn reorder_keeps_original_list_unchanged_test() {
  let tasks = example_tasks()
  let assert Ok(updated) =
    task_order.reorder(tasks, id_by_title(tasks, "B"), 3)

  assert list.map(tasks, task.title) == ["A", "B", "C", "D"]
  assert list.map(tasks, task.position) == [0, 1, 2, 3]
  assert list.map(updated, task.title) == ["A", "C", "D", "B"]
}

pub fn reorder_invalid_position_precedes_missing_task_test() {
  let tasks = example_tasks()
  let missing = make_task("missing", example_column_id(), "X", 0)

  let assert Error(task_order.InvalidPosition) =
    task_order.reorder(tasks, task.id(missing), -1)
}
