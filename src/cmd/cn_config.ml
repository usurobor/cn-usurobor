(** cn_config.ml — Runtime configuration loader

    Loads config from environment variables + .cn/config.json + .cn/secrets.env.
    Secrets (API keys) resolved via Cn_dotenv: env var > secrets.env file.
    Non-secrets from config file under the "runtime" key, with env overrides.

    Uses Cn_json for config file parsing — same parser as API responses. *)

type scheduler_config = {
  sync_interval_sec : int;
  review_interval_sec : int;
  oneshot_drain_limit : int;
  daemon_drain_limit : int;
}

let default_scheduler_config = {
  sync_interval_sec = 300;
  review_interval_sec = 300;
  oneshot_drain_limit = 1;
  daemon_drain_limit = 8;
}

type config = {
  telegram_token : string option;
  anthropic_key : string;
  model : string;
  poll_interval : int;
  poll_timeout : int;
  max_tokens : int;
  allowed_users : int list;  (* [] = deny all Telegram users *)
  hub_path : string;
  shell : Cn_shell.shell_config;
  scheduler : scheduler_config;
}

let default_model = "claude-sonnet-4-latest"
let default_poll_interval = 1
let default_poll_timeout = 30
let default_max_tokens = 8192

let non_empty_env key =
  match Cn_ffi.Process.getenv_opt key with
  | Some "" | None -> None
  | some -> some

let load ~hub_path =
  (* Secrets: env var > .cn/secrets.env (via Cn_dotenv) *)
  let anthropic_key = Cn_dotenv.resolve_secret ~hub_path ~env_key:"ANTHROPIC_KEY" in
  let telegram_token = Cn_dotenv.resolve_secret ~hub_path ~env_key:"TELEGRAM_TOKEN" in
  let env_model = non_empty_env "CN_MODEL" in
  (* Load config file — surface parse errors, tolerate missing file *)
  let config_path = Cn_ffi.Path.join hub_path ".cn/config.json" in
  let file_json =
    if Cn_ffi.Fs.exists config_path then
      match Cn_ffi.Fs.read config_path |> Cn_json.parse with
      | Ok obj -> Ok (Some obj)
      | Error msg -> Error (Printf.sprintf "%s: %s" config_path msg)
    else Ok None
  in
  match file_json with
  | Error msg -> Error msg
  | Ok file_obj ->
  let runtime = match file_obj with
    | Some obj -> Cn_json.get "runtime" obj
    | None -> None
  in
  (* Extract non-secret settings from runtime config, with defaults *)
  let get_int key default min_val =
    let raw = match runtime with
      | Some r -> (match Cn_json.get_int key r with Some i -> i | None -> default)
      | None -> default
    in
    max raw min_val
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
  (* CN Shell config from runtime section *)
  let get_string_cfg key default =
    match runtime with
    | Some r -> (match Cn_json.get_string key r with Some s -> s | None -> default)
    | None -> default
  in
  let get_bool_cfg key default =
    match runtime with
    | Some r ->
      (match Cn_json.get key r with
       | Some (Cn_json.Bool b) -> b
       | _ -> default)
    | None -> default
  in
  let get_string_list key =
    match runtime with
    | Some r ->
      (match Cn_json.get_list key r with
       | Some items ->
         List.filter_map (fun item ->
           match item with Cn_json.String s -> Some s | _ -> None
         ) items
       | None -> [])
    | None -> []
  in
  let d = Cn_shell.default_shell_config in
  (* Normalize two_pass and apply_mode: invalid → default *)
  let normalize_enum valid default raw =
    if List.mem raw valid then raw else default
  in
  let shell = {
    Cn_shell.two_pass =
      normalize_enum ["auto"; "off"] d.two_pass
        (get_string_cfg "two_pass" d.two_pass);
    apply_mode =
      normalize_enum ["off"; "branch"; "working_tree"] d.apply_mode
        (get_string_cfg "apply_mode" d.apply_mode);
    exec_enabled = get_bool_cfg "exec_enabled" d.exec_enabled;
    exec_allowlist = get_string_list "exec_allowlist";
    max_observe_ops = get_int "max_observe_ops" d.max_observe_ops 1;
    max_artifact_bytes = get_int "max_artifact_bytes" d.max_artifact_bytes 1024;
    max_artifact_bytes_per_op = get_int "max_artifact_bytes_per_op" d.max_artifact_bytes_per_op 1024;
  } in
  (* Scheduler config from runtime.scheduler sub-object *)
  let scheduler_obj = match runtime with
    | Some r -> Cn_json.get "scheduler" r
    | None -> None
  in
  let sched_int key default =
    let raw = match scheduler_obj with
      | Some s -> (match Cn_json.get_int key s with Some i -> i | None -> default)
      | None -> default
    in
    max raw 1
  in
  let scheduler = {
    sync_interval_sec = sched_int "sync_interval_sec" default_scheduler_config.sync_interval_sec;
    review_interval_sec = sched_int "review_interval_sec" default_scheduler_config.review_interval_sec;
    oneshot_drain_limit = sched_int "oneshot_drain_limit" default_scheduler_config.oneshot_drain_limit;
    daemon_drain_limit = sched_int "daemon_drain_limit" default_scheduler_config.daemon_drain_limit;
  } in
  match anthropic_key with
  | None -> Error "ANTHROPIC_KEY not set (required for agent runtime)"
  | Some key ->
      Ok {
        telegram_token;
        anthropic_key = key;
        model;
        poll_interval = get_int "poll_interval" default_poll_interval 1;
        poll_timeout = get_int "poll_timeout" default_poll_timeout 0;
        max_tokens = get_int "max_tokens" default_max_tokens 1;
        allowed_users;
        hub_path;
        shell;
        scheduler;
      }
