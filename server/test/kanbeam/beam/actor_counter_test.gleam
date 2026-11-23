import gleam/erlang/process
import gleam/otp/actor

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

pub fn actor_counter_increments_test() {
  let assert Ok(started) =
    actor.new(0)
    |> actor.on_message(handle_message)
    |> actor.start()

  let subject = started.data

  actor.send(subject, Increment)
  actor.send(subject, Increment)

  let reply_to = process.new_subject()

  actor.send(subject, GetCount(reply_to))

  let count = process.receive(reply_to, 1000)

  assert count == Ok(2)

  actor.send(subject, Stop)
}

pub fn actor_counter_stops_normally_test() {
  let assert Ok(started) =
    actor.new(0)
    |> actor.on_message(handle_message)
    |> actor.start()

  let subject = started.data

  let monitor = process.monitor(started.pid)
  let selector =
    process.new_selector()
    |> process.select_specific_monitor(monitor, fn(down) { down })

  process.send(subject, Stop)

  let received = process.selector_receive(selector, 1000)

  assert received
    == Ok(process.ProcessDown(monitor, started.pid, process.Normal))
}
