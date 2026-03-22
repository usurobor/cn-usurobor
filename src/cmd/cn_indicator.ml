(** cn_indicator.ml — Processing indicator abstraction

    Best-effort UX signals for human-facing sinks during N-pass
    bind loop processing. Never blocks the processing pipeline.
    Never changes correctness or authority.

    Telegram is the first concrete sink implementation.
    Other sinks return None (no indicator). *)

(* === Types === *)

type sink =
  | Telegram of { token : string; chat_id : int }
  | No_sink

type handle = {
  sink : sink;
  trigger_id : string;
}

(* === Lifecycle === *)

(** Start a processing indicator for the given sink.
    For Telegram: sends sendChatAction typing.
    Returns None for No_sink or on failure.
    Emits indicator.start trace event. *)
let start ~sink ~trigger_id =
  match sink with
  | No_sink -> None
  | Telegram { token; chat_id } ->
    Cn_trace.gemit ~component:"indicator" ~layer:Sensor
      ~event:"indicator.start" ~severity:Info ~status:Ok_
      ~trigger_id
      ~details:[
        "sink", Cn_json.String "telegram";
        "chat_id", Cn_json.Int chat_id;
      ] ();
    (try Cn_telegram.send_typing ~token ~chat_id
     with _ -> ());
    Some { sink = Telegram { token; chat_id }; trigger_id }

(** Refresh the indicator (e.g., re-send typing action before next LLM call).
    For Telegram: typing expires after ~5s, so refresh before each call.
    Emits indicator.refresh trace event. *)
let refresh handle =
  match handle.sink with
  | No_sink -> ()
  | Telegram { token; chat_id } ->
    Cn_trace.gemit ~component:"indicator" ~layer:Sensor
      ~event:"indicator.refresh" ~severity:Debug ~status:Ok_
      ~trigger_id:handle.trigger_id
      ~details:[
        "sink", Cn_json.String "telegram";
        "chat_id", Cn_json.Int chat_id;
      ] ();
    (try Cn_telegram.send_typing ~token ~chat_id
     with _ -> ())

(** Stop the indicator. For Telegram, typing expires naturally
    so this is a no-op. Emits indicator.stop trace event. *)
let stop handle =
  match handle.sink with
  | No_sink -> ()
  | Telegram { token = _; chat_id } ->
    Cn_trace.gemit ~component:"indicator" ~layer:Sensor
      ~event:"indicator.stop" ~severity:Info ~status:Ok_
      ~trigger_id:handle.trigger_id
      ~details:[
        "sink", Cn_json.String "telegram";
        "chat_id", Cn_json.Int chat_id;
      ] ()

(** Signal indicator failure (processing failed).
    For Telegram: optionally set a failure reaction if available.
    Emits indicator.fail trace event. *)
let fail handle =
  match handle.sink with
  | No_sink -> ()
  | Telegram { token = _; chat_id } ->
    Cn_trace.gemit ~component:"indicator" ~layer:Sensor
      ~event:"indicator.fail" ~severity:Warn ~status:Degraded
      ~trigger_id:handle.trigger_id
      ~details:[
        "sink", Cn_json.String "telegram";
        "chat_id", Cn_json.Int chat_id;
      ] ()
