(** cn_context.ml — Context packer

    Loads hub artifacts and assembles the full context string sent to
    the LLM. Missing files degrade gracefully (skip, don't error).

    Loading order (per design doc):
    1. spec/SOUL.md
    2. spec/USER.md
    3. Last 3 daily reflections from threads/reflections/daily/
    4. Current weekly reflection from threads/reflections/weekly/
    5. Top 3 keyword-matched skills from src/agent/skills/
    6. Conversation history from state/conversation.json (last 10)
    7. Inbound message *)

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

(** Load top N skills by keyword overlap with the message. *)
let load_skills ~hub_path ~message ~n =
  let skills_dir = Cn_ffi.Path.join hub_path "src/agent/skills" in
  if not (Cn_ffi.Fs.exists skills_dir) then []
  else
    let keywords = tokenize message in
    if keywords = [] then []
    else
      (* Walk skill directories, find SKILL.md files *)
      let rec walk dir =
        if not (Cn_ffi.Fs.exists dir) then []
        else
          try
            Cn_ffi.Fs.readdir dir |> List.concat_map (fun entry ->
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
      let all_skills = walk skills_dir in
      all_skills
      |> List.map (fun (path, content) -> (path, content, score_skill keywords content))
      |> List.filter (fun (_, _, score) -> score > 0)
      |> List.sort (fun (_, _, a) (_, _, b) -> compare b a)
      |> (fun lst -> if List.length lst > n then List.filteri (fun i _ -> i < n) lst else lst)
      |> List.map (fun (_, content, _) -> content)

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
  (* 1. Core identity *)
  section "Identity" (read_opt (Cn_ffi.Path.join hub_path "spec/SOUL.md"));
  (* 2. User context *)
  section "User" (read_opt (Cn_ffi.Path.join hub_path "spec/USER.md"));
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
  (* 5. Top 3 keyword-matched skills *)
  let skills = load_skills ~hub_path ~message ~n:3 in
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
