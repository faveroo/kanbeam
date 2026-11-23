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

fn start_counter() -> actor.StartResult(process.Subject(CounterMessage)) {
  actor.new(0)
  |> actor.on_message(handle_message)
  |> actor.start()
}

fn supervised_counter() -> supervision.ChildSpecification(
  process.Subject(CounterMessage),
) {
  supervision.worker(start_counter)
}

pub fn supervisor_counter_test() {
  let child_specification = supervised_counter()

  let assert Ok(started) =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(child_specification)
    |> static_supervisor.start()

  assert process.is_alive(started.pid)

  process.unlink(started.pid)
  process.kill(started.pid)
}
