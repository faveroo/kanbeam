import gleam/erlang/process

pub fn child_send_messages_test() {
  let subject = process.new_subject()

  let _pid = process.spawn(fn() { process.send(subject, "Ready") })

  let received = process.receive(subject, 1000)

  assert received == Ok("Ready")
}
