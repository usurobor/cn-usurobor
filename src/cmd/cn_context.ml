(** cn_context.ml — Context packer

    Loads hub artifacts and assembles the full context string sent to
    the LLM. Missing files degrade gracefully (skip, don't error).

    Loading order (per design doc + AGENTS.md session contract):
    1. spec/SOUL.md
    2. spec/USER.md
    3. Mindsets from src/agent/mindsets/ (deterministic order, role-aware)
    4. Last 3 daily reflections from threads/reflections/daily/
    5. Current weekly reflection from threads/reflections/weekly/
    6. Top 3 keyword-matched skills from src/agent/skills/ (role-weighted)
    7. Conversation history from state/conversation.json (last 10)
    8. Inbound message *)

type packed = {
  trigger_id : string;
  from : string;
  content : string;
}

(** Read a file, returning "" if missing or unreadable. *)
let read_opt path =
  if Cn_ffi.Fs.exists path then
    (try Cn_ffi.Fs.read path with _ -> "")
  else ""

(** Substring containment check (no Str dependency). *)
let contains_sub (s : string) (sub : string) : bool =
  let n = String.length s in
  let m = String.length sub in
  if m = 0 then true
  else if m > n then false
  else
    let rec loop i =
      if i + m > n then false
      else if String.sub s i m = sub then true
      else loop (i + 1)
    in
    loop 0

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

(** Load mindsets in deterministic order, selecting role-specific file.
    Returns concatenated content or "" if no mindsets found. *)
let load_mindsets ~hub_path ~(role : string option) : string =
  let dir = Cn_ffi.Path.join hub_path "src/agent/mindsets" in
  let role_file =
    match role with
    | Some "pm" -> "PM.md"
    | _ -> "ENGINEERING.md"
  in
  [ "COHERENCE.md"
  ; role_file
  ; "WRITING.md"
  ; "OPERATIONS.md"
  ; "PERSONALITY.md"
  ; "MEMES.md"
  ]
  |> List.filter_map (fun f ->
       let p = Cn_ffi.Path.join dir f in
       let c = String.trim (read_opt p) in
       if c = "" then None else Some c)
  |> String.concat "\n\n---\n\n"

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

(** Load top N skills by keyword overlap with the message.
    When role is set, skills under the matching role path get a small
    score bonus (reorders, does not introduce zero-overlap skills). *)
let load_skills ~hub_path ~message ~(role : string option) ~n =
  let skills_dir = Cn_ffi.Path.join hub_path "src/agent/skills" in
  if not (Cn_ffi.Fs.exists skills_dir) then []
  else
    let keywords = tokenize message in
    if keywords = [] then []
    else
      (* Walk skill directories, find SKILL.md files.
         Sort entries for deterministic traversal across filesystems. *)
      let rec walk dir =
        if not (Cn_ffi.Fs.exists dir) then []
        else
          try
            Cn_ffi.Fs.readdir dir
            |> List.sort String.compare
            |> List.concat_map (fun entry ->
              let path = Cn_ffi.Path.join dir entry in
              let skill_path = Cn_ffi.Path.join path "SKILL.md" in
              if Cn_ffi.Fs.exists skill_path then
                let content = read_opt skill_path in
                if content = "" then []
                else [skill_path, content]
              else if Sys.is_directory path then
                walk path
              else [])
          with _ -> []
      in
      let bonus_for_path path =
        match role with
        | Some "pm" when contains_sub path "/skills/pm/" -> 2
        | Some "engineer" when contains_sub path "/skills/eng/" -> 2
        | _ -> 0
      in
      let all_skills = walk skills_dir in
      all_skills
      |> List.map (fun (path, content) ->
           let base = score_skill keywords content in
           let score = base + bonus_for_path path in
           (path, content, base, score))
      |> List.filter (fun (_, _, base, _) -> base > 0)
      (* Sort by score desc, then path asc for stable tie-breaking.
         Deterministic order matters for prompt caching effectiveness. *)
      |> List.sort (fun (p1, _, _, s1) (p2, _, _, s2) ->
           match compare s2 s1 with 0 -> String.compare p1 p2 | c -> c)
      |> (fun lst -> if List.length lst > n then List.filteri (fun i _ -> i < n) lst else lst)
      |> List.map (fun (_, content, _, _) -> content)

(** Load last N entries from state/conversation.json. *)
let load_conversation ~hub_path ~n =
  let path = Cn_ffi.Path.join hub_path "state/conversation.json" in
  let raw = read_opt path in
  if raw = "" then ""
  else
    match Cn_json.parse raw with
    | Error _ -> ""
    | Ok json ->
        match json with
        | Cn_json.Array items ->
            let len = List.length items in
            let recent = if len <= n then items
              else List.filteri (fun i _ -> i >= len - n) items
            in
            (* Format each exchange as role: content *)
            recent |> List.filter_map (fun entry ->
              let role = match Cn_json.get_string "role" entry with
                | Some r -> r | None -> "unknown"
              in
              let text = match Cn_json.get_string "content" entry with
                | Some c -> c | None -> ""
              in
              if text = "" then None
              else Some (Printf.sprintf "**%s**: %s" role text)
            ) |> String.concat "\n\n"
        | _ -> ""

let pack ~hub_path ~trigger_id ~message ~from =
  let buf = Buffer.create 4096 in
  let section title content =
    if content <> "" then begin
      Buffer.add_string buf (Printf.sprintf "## %s\n\n" title);
      Buffer.add_string buf content;
      Buffer.add_string buf "\n\n"
    end
  in
  let role = load_role ~hub_path in
  (* 1. Core identity *)
  section "Identity" (read_opt (Cn_ffi.Path.join hub_path "spec/SOUL.md"));
  (* 2. User context *)
  section "User" (read_opt (Cn_ffi.Path.join hub_path "spec/USER.md"));
  (* 2.5. Mindsets — session substrate, deterministic order *)
  let mindsets = load_mindsets ~hub_path ~role in
  if mindsets <> "" then section "Mindsets" mindsets;
  (* 3. Last 3 daily reflections *)
  let daily_dir = Cn_ffi.Path.join hub_path "threads/reflections/daily" in
  let dailies = list_md_desc daily_dir in
  let daily_texts = dailies
    |> (fun lst -> if List.length lst > 3 then List.filteri (fun i _ -> i < 3) lst else lst)
    |> List.map (fun f -> read_opt (Cn_ffi.Path.join daily_dir f))
    |> List.filter (fun s -> s <> "")
  in
  if daily_texts <> [] then
    section "Recent Reflections (Daily)" (String.concat "\n---\n" daily_texts);
  (* 4. Current weekly reflection *)
  let weekly_dir = Cn_ffi.Path.join hub_path "threads/reflections/weekly" in
  let weeklies = list_md_desc weekly_dir in
  (match weeklies with
   | latest :: _ ->
       section "Current Weekly Reflection"
         (read_opt (Cn_ffi.Path.join weekly_dir latest))
   | [] -> ());
  (* 5. Top 3 keyword-matched skills (role-weighted) *)
  let skills = load_skills ~hub_path ~message ~role ~n:3 in
  if skills <> [] then
    section "Relevant Skills" (String.concat "\n---\n" skills);
  (* 6. Conversation history (last 10) *)
  let conv = load_conversation ~hub_path ~n:10 in
  if conv <> "" then
    section "Recent Conversation" conv;
  (* 7. Inbound message *)
  Buffer.add_string buf "## Inbound Message\n\n";
  Buffer.add_string buf (Printf.sprintf "**From**: %s\n" from);
  Buffer.add_string buf (Printf.sprintf "**ID**: %s\n\n" trigger_id);
  Buffer.add_string buf message;
  Buffer.add_char buf '\n';
  { trigger_id; from; content = Buffer.contents buf }
