open Riot

type Riot.Message.t += | A of int | End | Collected_messages of Riot.Message.t list

type state = { messages: Riot.Message.t list; main: Pid.t }

let rec loop state =
  match receive () with
  | End -> send state.main (Collected_messages (List.rev state.messages))
  | (A _) as msg -> loop {state with messages = msg :: state.messages}
  | _ -> loop state

let main () =
  let this = self () in
  let pid = spawn (fun () -> loop {messages=[]; main=this}) in
  send pid (A 1);
  send pid (A 2);
  send pid (A 3);
  send pid End;

  match receive () with
  | Collected_messages (A 1 :: A 2 :: A 3 :: []) ->
      Logs.log (fun f -> f "received messages in order");
      shutdown ()
  | _ -> 
      Logs.log (fun f -> f "received messages in order");
      exit 1

let () =
  Logs.set_log_level None;
  Riot.run @@ main
