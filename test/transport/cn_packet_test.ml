(** cn_packet_test: ppx_expect tests for message packet transport (#150)

    Invariants tested:
    1. Envelope round-trip: serialize → parse → fields match
    2. Validation pipeline: rejects invalid schema, wrong recipient, payload mismatch
    3. Dedup: same content = duplicate, different content = equivocation
    4. Packet ref parsing: valid/invalid ref formats
    5. Negative space: no materialization without validation *)

(* ============================================================
   Invariant 1: Envelope round-trip
   ============================================================ *)

let%expect_test "envelope: round-trip serialize → parse preserves fields" =
  let env = Cn_packet.make_envelope
    ~sender:"sigma" ~recipient:"pi"
    ~topic:"hello-world" ~content:"Hello, world!"
    ~msg_id:"test-001@sigma" ~created_at:"2026-04-03T00:00:00Z" in
  let json_str = Cn_packet.envelope_to_string env in
  (match Cn_packet.parse_envelope json_str with
   | Error e -> Printf.printf "error: %s\n" e.reason
   | Ok parsed ->
       Printf.printf "schema=%s\n" parsed.pkt_schema;
       Printf.printf "msg_id=%s\n" parsed.msg_id;
       Printf.printf "sender=%s\n" parsed.pkt_sender;
       Printf.printf "recipient=%s\n" parsed.pkt_recipient;
       Printf.printf "topic=%s\n" parsed.pkt_topic;
       Printf.printf "payload_path=%s\n" parsed.payload_path;
       Printf.printf "payload_bytes=%d\n" parsed.payload_bytes;
       Printf.printf "sha_matches=%b\n" (parsed.payload_sha256 = env.payload_sha256));
  [%expect {|
    schema=cn.packet.v1
    msg_id=test-001@sigma
    sender=sigma
    recipient=pi
    topic=hello-world
    payload_path=packet/message.md
    payload_bytes=13
    sha_matches=true
  |}]

(* ============================================================
   Invariant 2: Validation pipeline — reject invalid
   ============================================================ *)

let make_test_envelope () =
  Cn_packet.make_envelope
    ~sender:"sigma" ~recipient:"pi"
    ~topic:"test" ~content:"Test content"
    ~msg_id:"test-001@sigma" ~created_at:"2026-04-03T00:00:00Z"

let%expect_test "validate: rejects unsupported schema" =
  let env = { (make_test_envelope ()) with pkt_schema = "cn.packet.v99" } in
  let json = Cn_packet.envelope_to_string env in
  (match Cn_packet.validate_packet ~ref_sender:"sigma" ~ref_msg_id:"test-001@sigma"
           ~local_name:"pi" ~envelope_json:json ~payload_content:"Test content" with
   | Ok _ -> Printf.printf "unexpected ok\n"
   | Error e -> Printf.printf "code=%s\n" e.reason_code);
  [%expect {| code=unsupported_protocol |}]

let%expect_test "validate: rejects wrong recipient" =
  let env = make_test_envelope () in
  let json = Cn_packet.envelope_to_string env in
  (match Cn_packet.validate_packet ~ref_sender:"sigma" ~ref_msg_id:"test-001@sigma"
           ~local_name:"omega" ~envelope_json:json ~payload_content:"Test content" with
   | Ok _ -> Printf.printf "unexpected ok\n"
   | Error e -> Printf.printf "code=%s\n" e.reason_code);
  [%expect {| code=wrong_recipient |}]

let%expect_test "validate: rejects namespace sender mismatch" =
  let env = make_test_envelope () in
  let json = Cn_packet.envelope_to_string env in
  (match Cn_packet.validate_packet ~ref_sender:"attacker" ~ref_msg_id:"test-001@sigma"
           ~local_name:"pi" ~envelope_json:json ~payload_content:"Test content" with
   | Ok _ -> Printf.printf "unexpected ok\n"
   | Error e -> Printf.printf "code=%s\n" e.reason_code);
  [%expect {| code=namespace_mismatch |}]

let%expect_test "validate: rejects payload hash mismatch" =
  let env = make_test_envelope () in
  let json = Cn_packet.envelope_to_string env in
  (match Cn_packet.validate_packet ~ref_sender:"sigma" ~ref_msg_id:"test-001@sigma"
           ~local_name:"pi" ~envelope_json:json ~payload_content:"WRONG content" with
   | Ok _ -> Printf.printf "unexpected ok\n"
   | Error e -> Printf.printf "code=%s\n" e.reason_code);
  [%expect {| code=payload_mismatch |}]

let%expect_test "validate: rejects malformed JSON envelope" =
  (match Cn_packet.validate_packet ~ref_sender:"sigma" ~ref_msg_id:"test@sigma"
           ~local_name:"pi" ~envelope_json:"not json" ~payload_content:"" with
   | Ok _ -> Printf.printf "unexpected ok\n"
   | Error e -> Printf.printf "code=%s\n" e.reason_code);
  [%expect {| code=invalid_envelope |}]

let%expect_test "validate: accepts valid packet" =
  let env = make_test_envelope () in
  let json = Cn_packet.envelope_to_string env in
  (match Cn_packet.validate_packet ~ref_sender:"sigma" ~ref_msg_id:"test-001@sigma"
           ~local_name:"pi" ~envelope_json:json ~payload_content:"Test content" with
   | Ok (validated_env, payload) ->
       Printf.printf "valid=true\n";
       Printf.printf "sender=%s\n" validated_env.pkt_sender;
       Printf.printf "payload_len=%d\n" (String.length payload)
   | Error e -> Printf.printf "error: %s\n" e.reason);
  [%expect {|
    valid=true
    sender=sigma
    payload_len=12
  |}]

(* ============================================================
   Invariant 3: Dedup — duplicate vs equivocation
   ============================================================ *)

let%expect_test "dedup: new message = accepted" =
  let result = Cn_packet.check_dedup []
    ~msg_id:"msg-001@sigma" ~sender:"sigma" ~payload_sha256:"abc123" in
  Printf.printf "status=%s\n" (Cn_packet.string_of_dedup_status result);
  [%expect {| status=accepted |}]

let%expect_test "dedup: same msg_id + same hash = duplicate" =
  let index = [Cn_packet.{ dedup_msg_id = "msg-001@sigma"; dedup_sender = "sigma";
                            dedup_payload_sha = "abc123"; dedup_status = Accepted }] in
  let result = Cn_packet.check_dedup index
    ~msg_id:"msg-001@sigma" ~sender:"sigma" ~payload_sha256:"abc123" in
  Printf.printf "status=%s\n" (Cn_packet.string_of_dedup_status result);
  [%expect {| status=duplicate |}]

let%expect_test "dedup: same msg_id + different hash = equivocation" =
  let index = [Cn_packet.{ dedup_msg_id = "msg-001@sigma"; dedup_sender = "sigma";
                            dedup_payload_sha = "abc123"; dedup_status = Accepted }] in
  let result = Cn_packet.check_dedup index
    ~msg_id:"msg-001@sigma" ~sender:"sigma" ~payload_sha256:"DIFFERENT" in
  Printf.printf "status=%s\n" (Cn_packet.string_of_dedup_status result);
  [%expect {| status=equivocation |}]

(* ============================================================
   Invariant 4: Packet ref parsing
   ============================================================ *)

let%expect_test "parse_packet_ref: valid ref" =
  (match Cn_packet.parse_packet_ref "refs/cn/msg/sigma/test-001@sigma" with
   | Some (sender, msg_id) ->
       Printf.printf "sender=%s msg_id=%s\n" sender msg_id
   | None -> Printf.printf "none\n");
  [%expect {| sender=sigma msg_id=test-001@sigma |}]

let%expect_test "parse_packet_ref: rejects non-packet ref" =
  (match Cn_packet.parse_packet_ref "refs/heads/main" with
   | Some _ -> Printf.printf "unexpected some\n"
   | None -> Printf.printf "rejected=true\n");
  [%expect {| rejected=true |}]

let%expect_test "parse_packet_ref: rejects incomplete ref" =
  (match Cn_packet.parse_packet_ref "refs/cn/msg/" with
   | Some _ -> Printf.printf "unexpected some\n"
   | None -> Printf.printf "rejected=true\n");
  [%expect {| rejected=true |}]

(* ============================================================
   Invariant 5: Payload SHA-256 is content commitment
   ============================================================ *)

let%expect_test "payload_sha256: different content = different hash" =
  let env1 = Cn_packet.make_envelope
    ~sender:"s" ~recipient:"r" ~topic:"t" ~content:"hello"
    ~msg_id:"m1@s" ~created_at:"2026-01-01T00:00:00Z" in
  let env2 = Cn_packet.make_envelope
    ~sender:"s" ~recipient:"r" ~topic:"t" ~content:"world"
    ~msg_id:"m2@s" ~created_at:"2026-01-01T00:00:00Z" in
  Printf.printf "different=%b\n" (env1.payload_sha256 <> env2.payload_sha256);
  Printf.printf "len1=%d len2=%d\n" (String.length env1.payload_sha256) (String.length env2.payload_sha256);
  [%expect {|
    different=true
    len1=64
    len2=64
  |}]

let%expect_test "payload_sha256: same content = same hash (deterministic)" =
  let env1 = Cn_packet.make_envelope
    ~sender:"s" ~recipient:"r" ~topic:"t" ~content:"identical"
    ~msg_id:"m1@s" ~created_at:"2026-01-01T00:00:00Z" in
  let env2 = Cn_packet.make_envelope
    ~sender:"s" ~recipient:"r" ~topic:"t" ~content:"identical"
    ~msg_id:"m2@s" ~created_at:"2026-01-02T00:00:00Z" in
  Printf.printf "same_hash=%b\n" (env1.payload_sha256 = env2.payload_sha256);
  [%expect {| same_hash=true |}]

(* ============================================================
   Invariant 6: msg_id format
   ============================================================ *)

let%expect_test "make_msg_id: contains sender and @ separator" =
  let id = Cn_packet.make_msg_id "sigma" in
  let has_at = String.contains id '@' in
  let ends_with_sender =
    let suffix = "@sigma" in
    let slen = String.length suffix in
    String.length id > slen &&
    String.sub id (String.length id - slen) slen = suffix in
  Printf.printf "has_at=%b ends_with_sender=%b\n" has_at ends_with_sender;
  [%expect {| has_at=true ends_with_sender=true |}]
