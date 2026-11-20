import gleam/erlang/process

pub type CounterMessage {
  Increment
  GetCount(reply_to: process.Subject(Int))
  Stop
}

fn loop(inbox: process.Subject(CounterMessage), count: Int) -> Nil {
  case process.receive_forever(inbox) {
    Increment -> {
      loop(inbox, count + 1)
    }

    GetCount(reply_to) -> {
      process.send(reply_to, count)
    }

    Stop -> Nil
  }
}

pub fn child_send_count_test() {
  let ready = process.new_subject()

  let _pid =
    process.spawn(fn() {
      let inbox = process.new_subject()

      process.send(ready, inbox)
      loop(inbox, 0)
    })

  let assert Ok(inbox) = process.receive(ready, 1000)

  process.send(inbox, Increment)
  process.send(inbox, Increment)

  let reply = process.new_subject()

  process.send(inbox, GetCount(reply))

  let assert Ok(2) = process.receive(reply, 1000)

  process.send(inbox, Stop)
}
