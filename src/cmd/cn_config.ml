(** cn_config.ml — Runtime configuration loader

    Loads config from environment variables + .cn/config.json.
    Secrets (API keys) come from env only; non-secrets from config
    file under the "runtime" key, with env overrides.

    Uses Cn_json for config file parsing — same parser as API responses. *)

type config = {
  telegram_token : string option;
  anthropic_key : string;
  model : string;
  poll_interval : int;
  poll_timeout : int;
  max_tokens : int;
  allowed_users : int list;
  hub_path : string;
}

let default_model = "claude-sonnet-4-latest"
let default_poll_interval = 1
let default_poll_timeout = 30
let default_max_tokens = 8192

let load ~hub_path =
  (* Secrets from env only *)
  let anthropic_key = Cn_ffi.Process.getenv_opt "ANTHROPIC_KEY" in
  let telegram_token = Cn_ffi.Process.getenv_opt "TELEGRAM_TOKEN" in
  let env_model = Cn_ffi.Process.getenv_opt "CN_MODEL" in
  (* Load config file if it exists *)
  let config_path = Cn_ffi.Path.join hub_path ".cn/config.json" in
  let runtime =
    if Cn_ffi.Fs.exists config_path then
      match Cn_ffi.Fs.read config_path |> Cn_json.parse with
      | Ok obj -> Cn_json.get "runtime" obj
      | Error _ -> None
    else None
  in
  (* Extract non-secret settings from runtime config, with defaults *)
  let get_int key default =
    match runtime with
    | Some r -> (match Cn_json.get_int key r with Some i -> i | None -> default)
    | None -> default
  in
  let allowed_users =
    match runtime with
    | Some r ->
        (match Cn_json.get_list "allowed_users" r with
         | Some items ->
             items |> List.filter_map (fun item ->
               match item with Cn_json.Int i -> Some i | _ -> None)
         | None -> [])
    | None -> []
  in
  let model = match env_model with
    | Some m -> m
    | None ->
        match runtime with
        | Some r -> (match Cn_json.get_string "model" r with Some m -> m | None -> default_model)
        | None -> default_model
  in
  match anthropic_key with
  | None -> Error "ANTHROPIC_KEY not set (required for agent runtime)"
  | Some key ->
      Ok {
        telegram_token;
        anthropic_key = key;
        model;
        poll_interval = get_int "poll_interval" default_poll_interval;
        poll_timeout = get_int "poll_timeout" default_poll_timeout;
        max_tokens = get_int "max_tokens" default_max_tokens;
        allowed_users;
        hub_path;
      }
