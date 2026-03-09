(** cn_context.ml — Context packer

    Loads hub artifacts and assembles a structured prompt for the LLM.
    Returns system blocks (with cache hints) and message turns, plus
    a flattened audit_text for state/input.md logging.

    v3.4: delegates asset loading to Cn_assets (three-layer CAR).
    Fails fast if core cognitive assets are missing.

    Structured output:
    - system[0]: Identity + User + Mindsets (stable, cache_control=true)
    - system[1]: Reflections + Skills + Capabilities (dynamic, no cache)
    - messages[]: Conversation history turns + inbound message

    Loading order (per CAR-v3.4 design):
    1. spec/SOUL.md          → system block 1
    2. spec/USER.md          → system block 1
    3. Mindsets (via CAR)    → system block 1
    4. Daily reflections     → system block 2
    5. Weekly reflection     → system block 2
    6. Keyword-matched skills (via CAR) → system block 2
    7. Capabilities + asset summary     → system block 2
    8. Conversation history  → messages (real turns)
    9. Inbound message       → messages (last user turn) *)

type packed = {
  trigger_id : string;
  from : string;
  system : Cn_llm.system_block list;
  messages : Cn_llm.message_turn list;
  raw_inbound : string;
  audit_text : string;
}

(** Read a file, returning "" if missing or unreadable. *)
let read_opt path =
  if Cn_ffi.Fs.exists path then
    (try Cn_ffi.Fs.read path with _ -> "")
  else ""

(** Read runtime.role from .cn/config.json. Returns None if missing or unset. *)
let load_role ~hub_path : string option =
  let cfg = Cn_ffi.Path.join hub_path ".cn/config.json" in
  let raw = read_opt cfg in
  if raw = "" then None
  else
    match Cn_json.parse raw with
    | Error _ -> None
    | Ok json ->
        (match Cn_json.get "runtime" json with
         | None -> None
         | Some runtime ->
             match Cn_json.get_string "role" runtime with
             | Some r -> Some (String.lowercase_ascii r)
             | None -> None)

(** List .md files in a directory, sorted descending (newest first).
    Returns [] if directory doesn't exist. *)
let list_md_desc dir =
  if Cn_ffi.Fs.exists dir then
    (try
       Cn_ffi.Fs.readdir dir
       |> List.filter (fun f -> Filename.check_suffix f ".md")
       |> List.sort (fun a b -> String.compare b a)
     with _ -> [])
  else []

(** Simple keyword tokenizer: lowercase, split on non-alpha, drop short tokens. *)
let tokenize s =
  let buf = Buffer.create 32 in
  let tokens = ref [] in
  let flush () =
    if Buffer.length buf >= 3 then
      tokens := Buffer.contents buf :: !tokens;
    Buffer.clear buf
  in
  String.iter (fun c ->
    if (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') then
      Buffer.add_char buf c
    else if c >= 'A' && c <= 'Z' then
      Buffer.add_char buf (Char.chr (Char.code c + 32))
    else
      flush ()
  ) s;
  flush ();
  !tokens

(** Score a skill file against message keywords. Returns overlap count. *)
let score_skill keywords skill_content =
  let skill_tokens = tokenize skill_content in
  keywords |> List.fold_left (fun acc kw ->
    if List.mem kw skill_tokens then acc + 1 else acc
  ) 0

(** Role-path bonus: skills under the role's directory get a small
    score bump (reorders, does not introduce zero-overlap skills). *)
let bonus_for_path path role =
  match role with
  | Some "pm" when Cn_assets.contains_sub path "/skills/pm/" -> 2
  | Some "engineer" when Cn_assets.contains_sub path "/skills/eng/" -> 2
  | _ -> 0

(** Load top N skills by keyword overlap with the message.
    Delegates to Cn_assets.collect_skills for three-layer resolution. *)
let load_skills ~hub_path ~message ~(role : string option) ~n =
  let all_skills = Cn_assets.collect_skills ~hub_path in
  let keywords = tokenize message in
  if keywords = [] then []
  else
    all_skills
    |> List.map (fun (rel_path, content, _source) ->
         let base = score_skill keywords content in
         let score = base + bonus_for_path rel_path role in
         (rel_path, content, base, score))
    |> List.filter (fun (_, _, base, _) -> base > 0)
    |> List.sort (fun (p1, _, _, s1) (p2, _, _, s2) ->
         match compare s2 s1 with 0 -> String.compare p1 p2 | c -> c)
    |> (fun lst -> if List.length lst > n then List.filteri (fun i _ -> i < n) lst else lst)
    |> List.map (fun (_, content, _, _) -> content)

(** Load last N entries from state/conversation.json as message turns.
    Returns structured turns for the messages array. *)
let load_conversation_turns ~hub_path ~n : Cn_llm.message_turn list =
  let path = Cn_ffi.Path.join hub_path "state/conversation.json" in
  let raw = read_opt path in
  if raw = "" then []
  else
    match Cn_json.parse raw with
    | Error _ -> []
    | Ok (Cn_json.Array items) ->
        let len = List.length items in
        let recent = if len <= n then items
          else List.filteri (fun i _ -> i >= len - n) items
        in
        recent |> List.filter_map (fun entry ->
          match Cn_json.get_string "role" entry, Cn_json.get_string "content" entry with
          | Some role, Some content when content <> "" ->
              Some { Cn_llm.role; content }
          | _ -> None)
    | _ -> []

let pack ~hub_path ~trigger_id ~message ~from ?shell_config () =
  (* Fail fast if core cognitive assets are missing *)
  (match Cn_assets.validate_core ~hub_path with
   | Ok () -> ()
   | Error msg ->
       failwith (Printf.sprintf
         "Core cognitive assets missing: %s\n\
          Run 'cn setup' or 'cn deps restore' to materialize assets." msg));

  let role = load_role ~hub_path in

  (* === Read all source data once === *)
  let soul = read_opt (Cn_ffi.Path.join hub_path "spec/SOUL.md") in
  let user = read_opt (Cn_ffi.Path.join hub_path "spec/USER.md") in
  let mindsets = Cn_assets.load_mindsets ~hub_path ~role in

  let daily_dir = Cn_ffi.Path.join hub_path "threads/reflections/daily" in
  let dailies = list_md_desc daily_dir in
  let daily_texts = dailies
    |> (fun lst -> if List.length lst > 3 then List.filteri (fun i _ -> i < 3) lst else lst)
    |> List.map (fun f -> read_opt (Cn_ffi.Path.join daily_dir f))
    |> List.filter (fun s -> s <> "")
  in

  let weekly_dir = Cn_ffi.Path.join hub_path "threads/reflections/weekly" in
  let weeklies = list_md_desc weekly_dir in
  let weekly_text = match weeklies with
    | latest :: _ -> read_opt (Cn_ffi.Path.join weekly_dir latest)
    | [] -> ""
  in

  let skills = load_skills ~hub_path ~message ~role ~n:3 in
  let conv_turns = load_conversation_turns ~hub_path ~n:10 in

  (* === Build system blocks === *)
  let add_section buf title content =
    if content <> "" then begin
      Buffer.add_string buf (Printf.sprintf "## %s\n\n" title);
      Buffer.add_string buf content;
      Buffer.add_string buf "\n\n"
    end
  in

  (* Block 1: stable identity context (cacheable) *)
  let stable_buf = Buffer.create 4096 in
  add_section stable_buf "Identity" soul;
  add_section stable_buf "User" user;
  if mindsets <> "" then add_section stable_buf "Mindsets" mindsets;

  (* Block 2: dynamic context (reflections + skills) *)
  let dynamic_buf = Buffer.create 2048 in
  if daily_texts <> [] then
    add_section dynamic_buf "Recent Reflections (Daily)"
      (String.concat "\n---\n" daily_texts);
  if weekly_text <> "" then
    add_section dynamic_buf "Current Weekly Reflection" weekly_text;
  if skills <> [] then
    add_section dynamic_buf "Relevant Skills"
      (String.concat "\n---\n" skills);

  (* CN Shell capabilities block — after skills, before conversation.
     Only present when shell_config is provided (v3.3.5+).
     v3.4: includes asset summary for cognitive substrate awareness. *)
  (match shell_config with
   | Some sc ->
       let assets = Cn_assets.summarize ~hub_path in
       Buffer.add_string dynamic_buf (Cn_capabilities.render ~assets sc)
   | None -> ());

  let system =
    let stable = String.trim (Buffer.contents stable_buf) in
    let dynamic = String.trim (Buffer.contents dynamic_buf) in
    (if stable = "" then [] else [{ Cn_llm.text = stable; cache = true }])
    @ (if dynamic = "" then [] else [{ Cn_llm.text = dynamic; cache = false }])
  in

  (* === Build messages: conversation history + inbound === *)
  let messages = conv_turns @ [{ Cn_llm.role = "user"; content = message }] in

  (* === Build audit text (backward-compatible markdown for input.md) === *)
  let audit_buf = Buffer.create 4096 in
  List.iter (fun (b : Cn_llm.system_block) ->
    Buffer.add_string audit_buf b.text;
    Buffer.add_string audit_buf "\n\n"
  ) system;
  let conv_text = conv_turns |> List.map (fun (m : Cn_llm.message_turn) ->
    Printf.sprintf "**%s**: %s" m.role m.content
  ) |> String.concat "\n\n" in
  if conv_text <> "" then
    add_section audit_buf "Recent Conversation" conv_text;
  Buffer.add_string audit_buf "## Inbound Message\n\n";
  Buffer.add_string audit_buf (Printf.sprintf "**From**: %s\n" from);
  Buffer.add_string audit_buf (Printf.sprintf "**ID**: %s\n\n" trigger_id);
  Buffer.add_string audit_buf message;
  Buffer.add_char audit_buf '\n';

  {
    trigger_id;
    from;
    system;
    messages;
    raw_inbound = message;
    audit_text = Buffer.contents audit_buf;
  }
