(** cn_llm.ml — Claude Messages API client

    Single-turn text completion: one user message in, one text response out.
    No tools, no streaming, no multi-turn.

    Uses Cn_json for request body (single-line guarantee) and response parsing.
    Retries 3x with exponential backoff on 5xx/timeout; 4xx fails immediately. *)

type response = {
  content : string;
  stop_reason : string;
  input_tokens : int;
  output_tokens : int;
  cache_creation_input_tokens : int;
  cache_read_input_tokens : int;
}

let api_url = "https://api.anthropic.com/v1/messages"
let api_version = "2023-06-01"

(** Build a curl config string that captures HTTP status code.
    Unlike Cn_ffi.Http.request, this omits --fail and appends
    --write-out so we can distinguish 4xx from 5xx for retry logic. *)
let build_config ~api_key ~body =
  let q = Cn_ffi.Http.curl_quote in
  let buf = Buffer.create 512 in
  Buffer.add_string buf (Printf.sprintf "url = \"%s\"\n" (q api_url));
  Buffer.add_string buf "request = \"POST\"\n";
  Buffer.add_string buf (Printf.sprintf "header = \"%s\"\n" (q ("content-type: application/json")));
  Buffer.add_string buf (Printf.sprintf "header = \"%s\"\n" (q ("x-api-key: " ^ api_key)));
  Buffer.add_string buf (Printf.sprintf "header = \"%s\"\n" (q ("anthropic-version: " ^ api_version)));
  Buffer.add_string buf (Printf.sprintf "data-raw = \"%s\"\n" (q body));
  Buffer.add_string buf "connect-timeout = 10\n";
  Buffer.add_string buf "max-time = 120\n";
  Buffer.add_string buf "silent\n";
  Buffer.add_string buf "show-error\n";
  (* Write HTTP status code on last line, preceded by newline separator *)
  Buffer.add_string buf "write-out = \"\\n%{http_code}\"\n";
  Buffer.contents buf

(** Parse the last line of curl output as HTTP status code.
    Returns (body, status_code). *)
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

let is_retryable status = status >= 500 || status = 0 (* 0 = curl error / timeout *)

(** Execute one HTTP request, returning (body, http_status) or curl error. *)
let do_request ~api_key ~body =
  let config = build_config ~api_key ~body in
  let code, output =
    Cn_ffi.Process.exec_args ~prog:"curl" ~args:["--config"; "-"]
      ~stdin_data:config ()
  in
  if code = 0 then
    let body, status = split_status output in
    Ok (body, status)
  else
    (* curl itself failed (network error, DNS, timeout, etc.) *)
    Error (Printf.sprintf "curl exit %d: %s" code (String.trim output))

let parse_response body =
  match Cn_json.parse body with
  | Error msg -> Error (Printf.sprintf "JSON parse error: %s" msg)
  | Ok json ->
      (* Extract all type=text blocks, concatenate.
         Handles multi-block responses and skips non-text blocks
         (e.g. thinking, tool_use) so future features don't break. *)
      let content =
        match Cn_json.get_list "content" json with
        | Some blocks ->
            let texts = blocks |> List.filter_map (fun block ->
              match Cn_json.get_string "type" block with
              | Some "text" -> Cn_json.get_string "text" block
              | _ -> None
            ) in
            String.concat "\n\n" texts
        | None -> ""
      in
      let stop_reason =
        match Cn_json.get_string "stop_reason" json with Some s -> s | None -> ""
      in
      let usage = Cn_json.get "usage" json in
      let get_usage_int key = match usage with
        | Some u -> (match Cn_json.get_int key u with Some i -> i | None -> 0)
        | None -> 0
      in
      Ok {
        content;
        stop_reason;
        input_tokens = get_usage_int "input_tokens";
        output_tokens = get_usage_int "output_tokens";
        cache_creation_input_tokens = get_usage_int "cache_creation_input_tokens";
        cache_read_input_tokens = get_usage_int "cache_read_input_tokens";
      }

let call ~api_key ~model ~max_tokens ~content =
  let body = Cn_json.to_string (Cn_json.Object [
    "model", Cn_json.String model;
    "max_tokens", Cn_json.Int max_tokens;
    "messages", Cn_json.Array [
      Cn_json.Object [
        "role", Cn_json.String "user";
        "content", Cn_json.String content;
      ]
    ];
  ]) in
  let max_retries = 3 in
  let rec attempt n =
    match do_request ~api_key ~body with
    | Ok (resp_body, status) when status >= 200 && status < 300 ->
        parse_response resp_body
    | Ok (resp_body, status) when not (is_retryable status) ->
        (* 4xx — non-retryable *)
        let detail = match Cn_json.parse resp_body with
          | Ok json ->
              (match Cn_json.get "error" json with
               | Some err ->
                   (match Cn_json.get_string "message" err with
                    | Some m -> m
                    | None -> resp_body)
               | None -> resp_body)
          | Error _ -> resp_body
        in
        Error (Printf.sprintf "HTTP %d: %s" status detail)
    | Ok (resp_body, status) ->
        (* 5xx or status=0 — retryable *)
        if n >= max_retries then
          Error (Printf.sprintf "HTTP %d after %d retries: %s" status max_retries
                   (String.sub resp_body 0 (min 200 (String.length resp_body))))
        else begin
          Unix.sleepf (float_of_int (1 lsl n)); (* 1s, 2s, 4s *)
          attempt (n + 1)
        end
    | Error msg ->
        (* curl-level failure (network, DNS, timeout) — retryable *)
        if n >= max_retries then
          Error (Printf.sprintf "%s (after %d retries)" msg max_retries)
        else begin
          Unix.sleepf (float_of_int (1 lsl n));
          attempt (n + 1)
        end
  in
  attempt 0
