(** cn_packet.ml — Canonical message packet schema and validation (#150)

    A message is a self-contained packet with one envelope, one payload,
    optional signature, and one transport proof. The receiver validates the
    packet before any inbox write. If validation fails, no materialization
    occurs.

    Design: docs/alpha/protocol/MESSAGE-PACKET-TRANSPORT.md *)

(* === Packet Schema Types === *)

type envelope = {
  pkt_schema    : string;          (** "cn.packet.v1" *)
  msg_id        : string;          (** globally unique: "{id}@{sender}" *)
  pkt_sender    : string;
  pkt_recipient : string;
  created_at    : string;          (** ISO 8601 *)
  content_type  : string;          (** "text/markdown" *)
  payload_path  : string;          (** "packet/message.md" — fixed *)
  payload_sha256: string;
  payload_bytes : int;
  pkt_topic     : string;
  thread        : string option;
  reply_to      : string option;
  transport_kind: string;          (** "git" *)
  packet_version: int;             (** 1 *)
}

type git_proof = {
  refname          : string;       (** refs/cn/msg/{sender}/{msg_id} *)
  commit_oid       : string;
  tree_oid         : string;
  payload_blob_oid : string;
}

type validation_error = {
  reason_code : string;
  reason      : string;
}

type validation_result =
  | Valid of envelope * string  (** envelope + validated payload content *)
  | Rejected of validation_error

(* === Constants === *)

let schema_v1 = "cn.packet.v1"
let required_payload_path = "packet/message.md"
let packet_ref_prefix = "refs/cn/msg/"

(* === Envelope Serialization === *)

let envelope_to_json env =
  let fields = [
    ("schema", Cn_json.String env.pkt_schema);
    ("msg_id", Cn_json.String env.msg_id);
    ("sender", Cn_json.String env.pkt_sender);
    ("recipient", Cn_json.String env.pkt_recipient);
    ("created_at", Cn_json.String env.created_at);
    ("content_type", Cn_json.String env.content_type);
    ("payload_path", Cn_json.String env.payload_path);
    ("payload_sha256", Cn_json.String env.payload_sha256);
    ("payload_bytes", Cn_json.Int env.payload_bytes);
    ("topic", Cn_json.String env.pkt_topic);
    ("protocol", Cn_json.Object [
      ("transport_kind", Cn_json.String env.transport_kind);
      ("packet_version", Cn_json.Int env.packet_version);
    ]);
  ] in
  let fields = match env.thread with
    | Some t -> fields @ [("thread", Cn_json.String t)]
    | None -> fields in
  let fields = match env.reply_to with
    | Some r -> fields @ [("reply_to", Cn_json.String r)]
    | None -> fields in
  Cn_json.Object fields

let envelope_to_string env =
  Cn_json.to_string (envelope_to_json env)

let parse_envelope json_str =
  match Cn_json.parse json_str with
  | Error e -> Error { reason_code = "invalid_envelope"; reason = Printf.sprintf "JSON parse error: %s" e }
  | Ok json ->
    let gs key = Cn_json.get_string key json in
    let gi key = Cn_json.get_int key json in
    match gs "schema", gs "msg_id", gs "sender", gs "recipient",
          gs "created_at", gs "content_type", gs "payload_path",
          gs "payload_sha256", gi "payload_bytes", gs "topic" with
    | Some schema, Some msg_id, Some sender, Some recipient,
      Some created_at, Some content_type, Some payload_path,
      Some payload_sha256, Some payload_bytes, Some topic ->
        let protocol = Cn_json.get "protocol" json in
        let transport_kind = match protocol with
          | Some p -> Cn_json.get_string "transport_kind" p |> Option.value ~default:"git"
          | None -> "git" in
        let packet_version = match protocol with
          | Some p -> Cn_json.get_int "packet_version" p |> Option.value ~default:1
          | None -> 1 in
        let thread = gs "thread" in
        let reply_to = gs "reply_to" in
        Ok {
          pkt_schema = schema; msg_id; pkt_sender = sender;
          pkt_recipient = recipient; created_at; content_type;
          payload_path; payload_sha256; payload_bytes;
          pkt_topic = topic; thread; reply_to;
          transport_kind; packet_version;
        }
    | _ ->
        Error { reason_code = "invalid_envelope";
                reason = "missing required fields" }

(* === Envelope Construction === *)

let make_envelope ~sender ~recipient ~topic ~content ~msg_id ~created_at =
  let payload_sha256 = Cn_sha256.hash content in
  let payload_bytes = String.length content in
  {
    pkt_schema = schema_v1;
    msg_id;
    pkt_sender = sender;
    pkt_recipient = recipient;
    created_at;
    content_type = "text/markdown";
    payload_path = required_payload_path;
    payload_sha256;
    payload_bytes;
    pkt_topic = topic;
    thread = None;
    reply_to = None;
    transport_kind = "git";
    packet_version = 1;
  }

(* === Message ID Generation === *)

let make_msg_id sender =
  (* Monotonic: Unix time in hex + random suffix @ sender *)
  let t = int_of_float (Unix.gettimeofday () *. 1000.0) in
  Printf.sprintf "%x-%04x@%s" t (Random.int 0xFFFF) sender

(* === Validation Pipeline === *)

(** Step 1: validate schema version *)
let validate_schema env =
  if env.pkt_schema = schema_v1 then Ok env
  else Error { reason_code = "unsupported_protocol";
               reason = Printf.sprintf "unsupported schema: %s" env.pkt_schema }

(** Step 2: validate fixed payload path *)
let validate_payload_path env =
  if env.payload_path = required_payload_path then Ok env
  else Error { reason_code = "payload_mismatch";
               reason = Printf.sprintf "payload_path must be %s, got %s"
                          required_payload_path env.payload_path }

(** Step 3: validate namespace bindings — sender/msg_id in ref match envelope *)
let validate_namespace ~ref_sender ~ref_msg_id env =
  if env.pkt_sender <> ref_sender then
    Error { reason_code = "namespace_mismatch";
            reason = Printf.sprintf "envelope sender %s != ref sender %s"
                       env.pkt_sender ref_sender }
  else if env.msg_id <> ref_msg_id then
    Error { reason_code = "namespace_mismatch";
            reason = Printf.sprintf "envelope msg_id %s != ref msg_id %s"
                       env.msg_id ref_msg_id }
  else Ok env

(** Step 4: validate recipient matches local node *)
let validate_recipient ~local_name env =
  if env.pkt_recipient = local_name then Ok env
  else Error { reason_code = "wrong_recipient";
               reason = Printf.sprintf "recipient %s != local %s"
                          env.pkt_recipient local_name }

(** Step 5: validate payload content — SHA-256 + byte length *)
let validate_payload ~content env =
  let actual_sha256 = Cn_sha256.hash content in
  let actual_bytes = String.length content in
  if actual_sha256 <> env.payload_sha256 then
    Error { reason_code = "payload_mismatch";
            reason = Printf.sprintf "payload SHA-256 mismatch: expected %s, got %s"
                       env.payload_sha256 actual_sha256 }
  else if actual_bytes <> env.payload_bytes then
    Error { reason_code = "payload_mismatch";
            reason = Printf.sprintf "payload length mismatch: expected %d, got %d"
                       env.payload_bytes actual_bytes }
  else Ok env

(** Full validation pipeline — all checks before materialization *)
let validate_packet ~ref_sender ~ref_msg_id ~local_name ~envelope_json ~payload_content =
  let ( let* ) = Result.bind in
  let* env = parse_envelope envelope_json in
  let* env = validate_schema env in
  let* env = validate_payload_path env in
  let* env = validate_namespace ~ref_sender ~ref_msg_id env in
  let* env = validate_recipient ~local_name env in
  let* env = validate_payload ~content:payload_content env in
  Ok (env, payload_content)

(* === Dedup Index === *)

type dedup_status = Accepted | Duplicate | Equivocation | Rejected_dedup

type dedup_entry = {
  dedup_msg_id      : string;
  dedup_sender      : string;
  dedup_payload_sha : string;
  dedup_status      : dedup_status;
}

let string_of_dedup_status = function
  | Accepted -> "accepted"
  | Duplicate -> "duplicate"
  | Equivocation -> "equivocation"
  | Rejected_dedup -> "rejected"

let dedup_status_of_string = function
  | "accepted" -> Accepted
  | "duplicate" -> Duplicate
  | "equivocation" -> Equivocation
  | _ -> Rejected_dedup

let dedup_entry_to_json e =
  Cn_json.Object [
    ("msg_id", Cn_json.String e.dedup_msg_id);
    ("sender", Cn_json.String e.dedup_sender);
    ("payload_sha256", Cn_json.String e.dedup_payload_sha);
    ("status", Cn_json.String (string_of_dedup_status e.dedup_status));
  ]

let parse_dedup_entry json =
  let gs key = Cn_json.get_string key json in
  match gs "msg_id", gs "sender", gs "payload_sha256", gs "status" with
  | Some msg_id, Some sender, Some sha, Some status ->
      Some { dedup_msg_id = msg_id; dedup_sender = sender;
             dedup_payload_sha = sha; dedup_status = dedup_status_of_string status }
  | _ -> None

(** Load dedup index from disk *)
let load_dedup_index path =
  if not (Sys.file_exists path) then []
  else
    let content = Cn_ffi.Fs.read path in
    match Cn_json.parse content with
    | Error _ -> []
    | Ok (Cn_json.Array entries) -> List.filter_map parse_dedup_entry entries
    | Ok _ -> []

(** Save dedup index to disk *)
let save_dedup_index path entries =
  let json = Cn_json.Array (List.map dedup_entry_to_json entries) in
  Cn_ffi.Fs.write path (Cn_json.to_string json)

(** Check dedup: returns Accepted, Duplicate, or Equivocation *)
let check_dedup index ~msg_id ~sender ~payload_sha256 =
  let matching = index |> List.filter (fun e ->
    e.dedup_msg_id = msg_id && e.dedup_sender = sender) in
  match matching with
  | [] -> Accepted
  | entries ->
      if List.exists (fun e -> e.dedup_payload_sha = payload_sha256) entries then
        Duplicate
      else
        Equivocation

(* === Helpers === *)

(** Split string on newlines, drop empty lines.
    Inlined from Cn_hub to avoid circular dependency (cn_hub is in cmd/). *)
let split_lines s =
  String.split_on_char '\n' s |> List.filter (fun s -> String.length s > 0)

(* === Git Packet Operations === *)

(** Parse ref into (sender, msg_id) from refs/cn/msg/{sender}/{msg_id} *)
let parse_packet_ref refname =
  let prefix = packet_ref_prefix in
  let plen = String.length prefix in
  if String.length refname <= plen ||
     String.sub refname 0 plen <> prefix then
    None
  else
    let rest = String.sub refname plen (String.length refname - plen) in
    match String.split_on_char '/' rest with
    | sender :: msg_parts when msg_parts <> [] ->
        let msg_id = String.concat "/" msg_parts in
        Some (sender, msg_id)
    | _ -> None

(** List packet refs for a sender from a remote *)
let list_packet_refs ~cwd ~sender =
  (* sender is a peer name (alphanumeric + hyphen), safe to interpolate directly.
     Filename.quote would add shell quotes inside the already-quoted path. *)
  let cmd = Printf.sprintf "git for-each-ref --format='%%(refname)' 'refs/remotes/origin/cn/msg/%s/' 2>/dev/null"
    sender in
  match Cn_ffi.Child_process.exec_in ~cwd cmd with
  | None -> []
  | Some output ->
      split_lines output
      |> List.filter_map (fun ref ->
        (* Convert refs/remotes/origin/cn/msg/... → refs/cn/msg/... *)
        let prefix = "refs/remotes/origin/" in
        let plen = String.length prefix in
        if String.length ref > plen && String.sub ref 0 plen = prefix then
          Some ("refs/" ^ String.sub ref plen (String.length ref - plen))
        else None)

(** Read packet files from a Git ref.
    Returns (envelope_json, payload_content) or error. *)
let read_git_packet ~cwd ~ref_name =
  (* Read envelope *)
  let env_cmd = Printf.sprintf "git show %s:packet/envelope.json 2>/dev/null"
    (Filename.quote ref_name) in
  let payload_cmd = Printf.sprintf "git show %s:packet/message.md 2>/dev/null"
    (Filename.quote ref_name) in
  match Cn_ffi.Child_process.exec_in ~cwd env_cmd,
        Cn_ffi.Child_process.exec_in ~cwd payload_cmd with
  | Some envelope_json, Some payload ->
      (* Validate tree shape: check no unexpected files *)
      let tree_cmd = Printf.sprintf "git ls-tree -r --name-only %s 2>/dev/null"
        (Filename.quote ref_name) in
      (match Cn_ffi.Child_process.exec_in ~cwd tree_cmd with
       | None -> Error { reason_code = "invalid_commit_or_proof";
                         reason = "could not list tree" }
       | Some tree_output ->
           let files = split_lines tree_output in
           let allowed = ["packet/envelope.json"; "packet/message.md"; "packet/signature.ed25519"] in
           let unexpected = files |> List.filter (fun f -> not (List.mem f allowed)) in
           if unexpected <> [] then
             Error { reason_code = "invalid_tree_shape";
                     reason = Printf.sprintf "unexpected files: %s" (String.concat ", " unexpected) }
           else
             Ok (envelope_json, payload))
  | None, _ -> Error { reason_code = "invalid_envelope";
                        reason = "could not read packet/envelope.json" }
  | _, None -> Error { reason_code = "payload_mismatch";
                        reason = "could not read packet/message.md" }

(** Create a packet commit in a Git repo.
    Creates a root commit (no parents) containing only packet/ files.
    Returns the refname on success. *)
let create_git_packet ~cwd ~sender ~recipient ~topic ~content ~msg_id ~created_at =
  let env = make_envelope ~sender ~recipient ~topic ~content ~msg_id ~created_at in
  let envelope_json = envelope_to_string env in
  let refname = Printf.sprintf "refs/cn/msg/%s/%s" sender msg_id in

  (* Write packet files to a temp index *)
  let env_blob_cmd = Printf.sprintf "echo -n %s | git hash-object -w --stdin"
    (Filename.quote envelope_json) in
  let payload_blob_cmd = Printf.sprintf "printf '%%s' %s | git hash-object -w --stdin"
    (Filename.quote content) in

  match Cn_ffi.Child_process.exec_in ~cwd env_blob_cmd,
        Cn_ffi.Child_process.exec_in ~cwd payload_blob_cmd with
  | Some env_oid, Some pay_oid ->
      let env_oid = String.trim env_oid in
      let pay_oid = String.trim pay_oid in
      (* Build nested tree: first create packet/ subtree, then root tree.
         git mktree rejects slashed paths — must use nested subtrees. *)
      let subtree_input = Printf.sprintf "100644 blob %s\tenvelope.json\n100644 blob %s\tmessage.md"
        env_oid pay_oid in
      let subtree_cmd = Printf.sprintf "printf '%%s' %s | git mktree"
        (Filename.quote subtree_input) in
      (match Cn_ffi.Child_process.exec_in ~cwd subtree_cmd with
       | Some subtree_oid ->
           let subtree_oid = String.trim subtree_oid in
           (* Root tree contains packet/ as a subtree entry *)
           let root_input = Printf.sprintf "040000 tree %s\tpacket" subtree_oid in
           let root_cmd = Printf.sprintf "printf '%%s' %s | git mktree"
             (Filename.quote root_input) in
           (match Cn_ffi.Child_process.exec_in ~cwd root_cmd with
            | None -> Error { reason_code = "fetch_failed"; reason = "failed to create root tree" }
            | Some tree_oid ->
                let tree_oid = String.trim tree_oid in
                (* Create root commit (no parents) *)
                let commit_cmd = Printf.sprintf
                  "git commit-tree %s -m %s"
                  (Filename.quote tree_oid)
                  (Filename.quote (Printf.sprintf "packet: %s → %s [%s]" sender recipient topic)) in
                (match Cn_ffi.Child_process.exec_in ~cwd commit_cmd with
                 | Some commit_oid ->
                     let commit_oid = String.trim commit_oid in
                     (* Update ref *)
                     let ref_cmd = Printf.sprintf "git update-ref %s %s"
                       (Filename.quote refname) (Filename.quote commit_oid) in
                     (match Cn_ffi.Child_process.exec_in ~cwd ref_cmd with
                      | Some _ -> Ok (env, refname)
                      | None -> Error { reason_code = "fetch_failed";
                                        reason = "failed to update ref" })
                 | None -> Error { reason_code = "fetch_failed";
                                   reason = "failed to create commit" }))
       | None -> Error { reason_code = "fetch_failed";
                         reason = "failed to create subtree" })
  | _ -> Error { reason_code = "fetch_failed";
                 reason = "failed to hash packet objects" }
