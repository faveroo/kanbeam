import gleam/list
import kanbeam/domain/board
import kanbeam/domain/board_state
import kanbeam/domain/column
import kanbeam/domain/task

fn make_board(id: String) -> board.Board {
  let assert Ok(created) = board.new(id, "Board " <> id)
  created
}

fn make_column(
  id: String,
  parent: board.Board,
  position: Int,
) -> column.Column {
  let assert Ok(created) =
    column.new(id, board.id(parent), "Column " <> id, position)
  created
}

fn make_task(
  id: String,
  parent: column.Column,
  position: Int,
) -> task.Task {
  let assert Ok(created) =
    task.new(
      id,
      column.id(parent),
      "Task " <> id,
      "Description " <> id,
      task.Medium,
      position,
    )
  created
}

fn fixture() -> #(
  board.Board,
  List(column.Column),
  List(task.Task),
) {
  let parent = make_board("board-1")
  let todo = make_column("todo", parent, 0)
  let doing = make_column("doing", parent, 1)
  let tasks = [
    make_task("task-1", todo, 0),
    make_task("task-2", todo, 1),
    make_task("task-3", doing, 0),
  ]
  #(parent, [todo, doing], tasks)
}

pub fn creates_empty_board_state_test() {
  let parent = make_board("board-1")
  let assert Ok(state) = board_state.new(parent, [], [])

  assert board_state.board(state) == parent
  assert board_state.columns(state) == []
  assert board_state.tasks(state) == []
}

pub fn creates_state_with_columns_and_no_tasks_test() {
  let parent = make_board("board-1")
  let first = make_column("todo", parent, 0)
  let second = make_column("doing", parent, 1)
  let columns = [first, second]
  let assert Ok(state) = board_state.new(parent, columns, [])

  assert board_state.columns(state) == columns
  assert board_state.tasks(state) == []
}

pub fn creates_state_with_single_column_and_task_test() {
  let parent = make_board("board-1")
  let current_column = make_column("todo", parent, 0)
  let current_task = make_task("task-1", current_column, 0)
  let assert Ok(state) =
    board_state.new(parent, [current_column], [current_task])

  assert board_state.columns(state) == [current_column]
  assert board_state.tasks(state) == [current_task]
}

pub fn creates_state_with_multiple_columns_and_tasks_test() {
  let #(parent, columns, tasks) = fixture()
  let assert Ok(state) = board_state.new(parent, columns, tasks)

  assert board_state.board(state) == parent
  assert board_state.columns(state) == columns
  assert board_state.tasks(state) == tasks
}

pub fn accepts_multiple_tasks_in_same_column_test() {
  let parent = make_board("board-1")
  let current_column = make_column("todo", parent, 0)
  let tasks = [
    make_task("task-1", current_column, 0),
    make_task("task-2", current_column, 1),
  ]
  let assert Ok(state) = board_state.new(parent, [current_column], tasks)

  assert board_state.tasks(state) == tasks
}

pub fn rejects_column_from_another_board_test() {
  let parent = make_board("board-1")
  let other_board = make_board("board-2")
  let foreign_column = make_column("foreign", other_board, 0)

  let assert Error(board_state.InvalidColumn) =
    board_state.new(parent, [foreign_column], [])
}

pub fn rejects_foreign_column_among_valid_columns_test() {
  let parent = make_board("board-1")
  let other_board = make_board("board-2")
  let valid_column = make_column("todo", parent, 0)
  let foreign_column = make_column("foreign", other_board, 1)

  let assert Error(board_state.InvalidColumn) =
    board_state.new(parent, [valid_column, foreign_column], [])
}

pub fn rejects_task_referencing_missing_column_test() {
  let parent = make_board("board-1")
  let included_column = make_column("todo", parent, 0)
  let missing_column = make_column("missing", parent, 1)
  let orphan_task = make_task("task-1", missing_column, 0)

  let assert Error(board_state.InvalidTask) =
    board_state.new(parent, [included_column], [orphan_task])
}

pub fn rejects_task_when_columns_are_empty_test() {
  let parent = make_board("board-1")
  let absent_column = make_column("todo", parent, 0)
  let orphan_task = make_task("task-1", absent_column, 0)

  let assert Error(board_state.InvalidTask) =
    board_state.new(parent, [], [orphan_task])
}

pub fn rejects_invalid_task_among_valid_tasks_test() {
  let #(parent, columns, valid_tasks) = fixture()
  let absent_column = make_column("missing", parent, 2)
  let orphan_task = make_task("orphan", absent_column, 0)
  let tasks = list.append(valid_tasks, [orphan_task])

  let assert Error(board_state.InvalidTask) =
    board_state.new(parent, columns, tasks)
}

pub fn invalid_column_has_priority_over_invalid_task_test() {
  let parent = make_board("board-1")
  let foreign_board = make_board("board-2")
  let foreign_column = make_column("foreign", foreign_board, 0)
  let missing_column = make_column("missing", parent, 0)
  let orphan_task = make_task("orphan", missing_column, 0)

  let assert Error(board_state.InvalidColumn) =
    board_state.new(parent, [foreign_column], [orphan_task])
}

pub fn board_getter_preserves_board_data_test() {
  let #(parent, columns, tasks) = fixture()
  let assert Ok(state) = board_state.new(parent, columns, tasks)
  let returned = board_state.board(state)

  assert board.id(returned) == board.id(parent)
  assert board.name(returned) == board.name(parent)
}

pub fn columns_getter_preserves_input_order_test() {
  let #(parent, columns, tasks) = fixture()
  let assert Ok(state) = board_state.new(parent, columns, tasks)

  assert list.map(board_state.columns(state), column.name) == [
    "Column todo",
    "Column doing",
  ]
  assert list.map(board_state.columns(state), column.position) == [0, 1]
}

pub fn tasks_getter_preserves_input_order_and_fields_test() {
  let #(parent, columns, tasks) = fixture()
  let assert Ok(state) = board_state.new(parent, columns, tasks)
  let returned = board_state.tasks(state)

  assert list.map(returned, task.title) == [
    "Task task-1",
    "Task task-2",
    "Task task-3",
  ]
  assert list.map(returned, task.position) == [0, 1, 0]
  assert list.map(returned, task.description) == [
    "Description task-1",
    "Description task-2",
    "Description task-3",
  ]
  assert list.all(returned, fn(current) {
    task.priority(current) == task.Medium
  })
}

pub fn constructing_state_does_not_modify_inputs_test() {
  let #(parent, columns, tasks) = fixture()
  let original_column_ids = list.map(columns, column.id)
  let original_task_ids = list.map(tasks, task.id)
  let assert Ok(state) = board_state.new(parent, columns, tasks)

  assert list.map(columns, column.id) == original_column_ids
  assert list.map(tasks, task.id) == original_task_ids
  assert board_state.columns(state) == columns
  assert board_state.tasks(state) == tasks
}
