(** cn_ext_host.ml — Subprocess extension host protocol

    Implements the subprocess execution model for extensions.
    Protocol: stdio JSON messages (describe, health, execute, shutdown).

    Design:
    - Extensions run as subprocesses
    - Communication via stdin/stdout JSON lines
    - No ambient credentials — secrets injected explicitly
    - Failure is isolated: host crash does not affect core runtime *)

(* === Types === *)

type host_request =
  | Describe
  | Health
  | Execute of {
      op_kind : string;
      arguments : (string * Cn_json.t) list;
      limits : (string * Cn_json.t) list;
      permissions : (string * Cn_json.t) list;
    }
  | Shutdown

type host_response = {
  status : string;             (* "ok" | "error" *)
  data : Cn_json.t option;
  error : string option;
}

type host_result =
  | Success of Cn_json.t
  | HostError of string
  | ProcessFailed of int

(* === JSON protocol === *)

let request_to_json = function
  | Describe ->
    Cn_json.Object [("method", Cn_json.String "describe")]
  | Health ->
    Cn_json.Object [("method", Cn_json.String "health")]
  | Execute { op_kind; arguments; limits; permissions } ->
    Cn_json.Object [
      ("method", Cn_json.String "execute");
      ("op", Cn_json.Object (
        [("kind", Cn_json.String op_kind)] @ arguments));
      ("limits", Cn_json.Object limits);
      ("permissions", Cn_json.Object permissions);
    ]
  | Shutdown ->
    Cn_json.Object [("method", Cn_json.String "shutdown")]

let parse_response json =
  match json with
  | Cn_json.Object _ ->
    let status = match Cn_json.get_string "status" json with
      | Some s -> s | None -> "error" in
    let data = Cn_json.get "data" json in
    let error = Cn_json.get_string "error" json in
    Ok { status; data; error }
  | _ -> Error "response must be a JSON object"

(* === Subprocess execution === *)

(** Execute a single request against a subprocess host.
    Spawns the process, sends the request on stdin, reads response from stdout.
    Returns structured result. *)
let execute_subprocess ~command request =
  match command with
  | [] -> HostError "empty command"
  | prog :: args ->
    let request_json = Cn_json.to_string (request_to_json request) ^ "\n" in
    let code, output =
      Cn_ffi.Process.exec_args ~prog ~args
        ~stdin_data:request_json ()
    in
    if code <> 0 then
      ProcessFailed code
    else
      match Cn_json.parse (String.trim output) with
      | Error msg -> HostError (Printf.sprintf "response parse error: %s" msg)
      | Ok json ->
        match parse_response json with
        | Error msg -> HostError msg
        | Ok resp ->
          if resp.status = "ok" then
            match resp.data with
            | Some d -> Success d
            | None -> Success (Cn_json.Object [])
          else
            HostError (match resp.error with
              | Some e -> e
              | None -> "unknown extension error")

(** Execute an extension op via subprocess host.
    This is the main entry point called by cn_executor for extension ops.

    Returns a receipt-compatible result:
    - Ok (status, content) on success
    - Error reason on failure *)
let execute_extension_op ~command ~op_kind ~arguments
    ?(limits = []) ?(permissions = []) () =
  let request = Execute { op_kind; arguments; limits; permissions } in
  match execute_subprocess ~command request with
  | Success data ->
    let content = match Cn_json.get_string "content" data with
      | Some c -> c
      | None -> Cn_json.to_string data in
    Ok ("ok", content)
  | HostError msg -> Error msg
  | ProcessFailed code ->
    Error (Printf.sprintf "extension_process_exit_%d" code)

(** Check extension host health. *)
let check_health ~command () =
  match execute_subprocess ~command Health with
  | Success _ -> Ok ()
  | HostError msg -> Error msg
  | ProcessFailed code ->
    Error (Printf.sprintf "health_process_exit_%d" code)
