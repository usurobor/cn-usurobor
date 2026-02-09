(* Hub layer prelude *)

type thread_location =
  | In
  | Mail_inbox
  | Mail_outbox
  | Mail_sent
  | Reflections_daily
  | Reflections_weekly
  | Reflections_monthly
  | Adhoc
  | Archived

let thread_path location name =
  let prefix = match location with
    | In -> "threads/in"
    | Mail_inbox -> "threads/mail/inbox"
    | Mail_outbox -> "threads/mail/outbox"
    | Mail_sent -> "threads/mail/sent"
    | Reflections_daily -> "threads/reflections/daily"
    | Reflections_weekly -> "threads/reflections/weekly"
    | Reflections_monthly -> "threads/reflections/monthly"
    | Adhoc -> "threads/adhoc"
    | Archived -> "threads/archived"
  in
  prefix ^ "/" ^ name ^ ".md"

let timestamp_filename slug =
  "20260209-120000-" ^ slug ^ ".md"

let state_path name =
  "state/" ^ name

let log_path name =
  "logs/" ^ name
