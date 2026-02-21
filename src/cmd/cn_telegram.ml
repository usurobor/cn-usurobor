(** cn_telegram.ml — Telegram Bot API client

    Provides get_updates (long-polling) and send_message.
    Pure API client — offset persistence and allowed_users filtering
    are caller responsibilities (cn_runtime).

    Uses curl config on stdin via Cn_ffi.Process.exec_args (no argv secrets).
    Retries 3x with exponential backoff on 5xx/timeout; 4xx fails immediately. *)

type message = {
  message_id : int;
  chat_id : int;
  user_id : int;
  username : string option;
  text : string;
  date : int;
  update_id : int;
}

let api_base = "https://api.telegram.org"

(** Build curl config for Telegram API. Same pattern as cn_llm:
    omit --fail, use write-out for HTTP status on last line.
    max_time should exceed Telegram's long-poll timeout to avoid
    curl killing the connection before the server responds. *)
let build_config ~url ~body_opt ~max_time =
  let q = Cn_ffi.Http.curl_quote in
  let buf = Buffer.create 256 in
  Buffer.add_string buf (Printf.sprintf "url = \"%s\"\n" (q url));
  (match body_opt with
   | Some body ->
       Buffer.add_string buf "request = \"POST\"\n";
       Buffer.add_string buf (Printf.sprintf "header = \"%s\"\n"
         (q "content-type: application/json"));
       Buffer.add_string buf (Printf.sprintf "data-raw = \"%s\"\n" (q body))
   | None -> ());
  Buffer.add_string buf "connect-timeout = 10\n";
  Buffer.add_string buf (Printf.sprintf "max-time = %d\n" max_time);
  Buffer.add_string buf "silent\n";
  Buffer.add_string buf "show-error\n";
  Buffer.add_string buf "write-out = \"\\n%{http_code}\"\n";
  Buffer.contents buf

let split_status output =
  match String.rindex_opt output '\n' with
  | Some i ->
      let body = String.sub output 0 i in
      let code_str = String.sub output (i + 1) (String.length output - i - 1) in
      (match int_of_string_opt (String.trim code_str) with
       | Some code -> (body, code)
       | None -> (output, 0))
  | None ->
      (match int_of_string_opt (String.trim output) with
       | Some code -> ("", code)
       | None -> (output, 0))

let is_retryable status = status >= 500 || status = 0

(** Execute a Telegram API request with retry logic. *)
let request ~url ~body_opt ~max_time =
  let config = build_config ~url ~body_opt ~max_time in
  let max_retries = 3 in
  let rec attempt n =
    let code, output =
      Cn_ffi.Process.exec_args ~prog:"curl" ~args:["--config"; "-"]
        ~stdin_data:config ()
    in
    if code = 0 then
      let body, status = split_status output in
      if status >= 200 && status < 300 then
        Ok body
      else if is_retryable status then begin
        if n >= max_retries then
          Error (Printf.sprintf "HTTP %d after %d retries: %s" status max_retries
                   (String.sub body 0 (min 200 (String.length body))))
        else begin
          Unix.sleepf (float_of_int (1 lsl n));
          attempt (n + 1)
        end
      end else
        (* 4xx — non-retryable *)
        Error (Printf.sprintf "HTTP %d: %s" status
                 (String.sub body 0 (min 200 (String.length body))))
    else if n >= max_retries then
      Error (Printf.sprintf "curl exit %d: %s (after %d retries)"
               code (String.trim output) max_retries)
    else begin
      Unix.sleepf (float_of_int (1 lsl n));
      attempt (n + 1)
    end
  in
  attempt 0

(** Parse a single update object into a message.
    Returns None for updates without a message/from/chat structure
    (channel_post, edited_message, etc.). Non-text messages (photos,
    stickers) return text="". *)
let parse_update update =
  match Cn_json.get_int "update_id" update with
  | None -> None
  | Some update_id ->
  match Cn_json.get "message" update with
  | None -> None
  | Some msg ->
  match Cn_json.get_int "message_id" msg with
  | None -> None
  | Some message_id ->
  match Cn_json.get "chat" msg with
  | None -> None
  | Some chat ->
  match Cn_json.get_int "id" chat with
  | None -> None
  | Some chat_id ->
  match Cn_json.get "from" msg with
  | None -> None
  | Some from ->
  match Cn_json.get_int "id" from with
  | None -> None
  | Some user_id ->
  let username = Cn_json.get_string "username" from in
  let text = match Cn_json.get_string "text" msg with Some t -> t | None -> "" in
  let date = match Cn_json.get_int "date" msg with Some d -> d | None -> 0 in
  Some { message_id; chat_id; user_id; username; text; date; update_id }

let get_updates ~token ~offset ~timeout =
  let url = Printf.sprintf "%s/bot%s/getUpdates" api_base token in
  let body = Cn_json.to_string (Cn_json.Object [
    "offset", Cn_json.Int offset;
    "timeout", Cn_json.Int timeout;
    "allowed_updates", Cn_json.Array [Cn_json.String "message"];
  ]) in
  (* curl max-time must exceed Telegram's long-poll timeout *)
  match request ~url ~body_opt:(Some body) ~max_time:(timeout + 10) with
  | Error msg -> Error msg
  | Ok resp_body ->
      match Cn_json.parse resp_body with
      | Error msg -> Error (Printf.sprintf "JSON parse error: %s" msg)
      | Ok json ->
          match Cn_json.get "ok" json with
          | Some (Cn_json.Bool true) ->
              let messages = match Cn_json.get_list "result" json with
                | Some updates -> List.filter_map parse_update updates
                | None -> []
              in
              Ok messages
          | _ ->
              let desc = match Cn_json.get_string "description" json with
                | Some d -> d | None -> resp_body
              in
              Error (Printf.sprintf "Telegram API error: %s" desc)

let send_message ~token ~chat_id ~text =
  let url = Printf.sprintf "%s/bot%s/sendMessage" api_base token in
  let body = Cn_json.to_string (Cn_json.Object [
    "chat_id", Cn_json.Int chat_id;
    "text", Cn_json.String text;
  ]) in
  match request ~url ~body_opt:(Some body) ~max_time:60 with
  | Error msg -> Error msg
  | Ok resp_body ->
      match Cn_json.parse resp_body with
      | Error msg -> Error (Printf.sprintf "JSON parse error: %s" msg)
      | Ok json ->
          match Cn_json.get "ok" json with
          | Some (Cn_json.Bool true) -> Ok ()
          | _ ->
              let desc = match Cn_json.get_string "description" json with
                | Some d -> d | None -> resp_body
              in
              Error (Printf.sprintf "Telegram API error: %s" desc)
