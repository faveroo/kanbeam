import gleam/erlang/process
import gleam/otp/actor
import gleam/otp/static_supervisor
import gleam/otp/supervision

pub type CounterMessage {
  Increment
  GetCount(reply_to: process.Subject(Int))
  Stop
}

fn handle_message(
  count: Int,
  message: CounterMessage,
) -> actor.Next(Int, CounterMessage) {
  case message {
    Increment -> actor.continue(count + 1)
    GetCount(reply_to) -> {
      actor.send(reply_to, count)
      actor.continue(count)
    }
    Stop -> actor.stop()
  }
}

fn start_counter(
  notify: process.Subject(process.Pid),
) -> actor.StartResult(process.Subject(CounterMessage)) {
  let started =
    actor.new(0)
    |> actor.on_message(handle_message)
    |> actor.start()

  case started {
    Error(error) -> Error(error)
    Ok(started) -> {
      process.send(notify, started.pid)
      Ok(started)
    }
  }
}

fn supervised_counter(
  notify: process.Subject(process.Pid),
) -> supervision.ChildSpecification(process.Subject(CounterMessage)) {
  supervision.worker(fn() { start_counter(notify) })
}

pub fn supervisor_counter_test() {
  let notify = process.new_subject()
  let child_specification = supervised_counter(notify)

  let assert Ok(started) =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(child_specification)
    |> static_supervisor.start()

  assert process.is_alive(started.pid)

  process.unlink(started.pid)
  process.kill(started.pid)
}

pub fn supervisor_restarts_counter_after_failure_test() {
  let notify = process.new_subject()
  let child_specification = supervised_counter(notify)

  let assert Ok(started) =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(child_specification)
    |> static_supervisor.start()

  assert process.is_alive(started.pid)

  let assert Ok(first_pid) = process.receive(notify, 1000)

  process.send_abnormal_exit(first_pid, "simulated_failure")

  let assert Ok(second_pid) = process.receive(notify, 1000)

  assert second_pid != first_pid

  assert process.is_alive(started.pid)
  assert process.is_alive(second_pid)

  process.unlink(started.pid)
  process.kill(started.pid)
}
