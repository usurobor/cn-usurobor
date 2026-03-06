(** cn_sha256_test: ppx_expect tests for SHA-256

    Uses NIST test vectors from FIPS 180-4 + known values. *)

(* === NIST test vectors === *)

let%expect_test "sha256: empty string" =
  print_endline (Cn_sha256.hash "");
  [%expect {| e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 |}]

let%expect_test "sha256: 'abc' (NIST one-block)" =
  print_endline (Cn_sha256.hash "abc");
  [%expect {| ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad |}]

let%expect_test "sha256: 448-bit message (NIST two-block)" =
  print_endline (Cn_sha256.hash "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq");
  [%expect {| 248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1 |}]

let%expect_test "sha256: 896-bit message (NIST)" =
  print_endline (Cn_sha256.hash
    "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
  [%expect {| cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1 |}]

(* === hash_prefixed === *)

let%expect_test "sha256: hash_prefixed adds sha256: prefix" =
  print_endline (Cn_sha256.hash_prefixed "abc");
  [%expect {| sha256:ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad |}]

(* === Known values === *)

let%expect_test "sha256: single 'a'" =
  print_endline (Cn_sha256.hash "a");
  [%expect {| ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb |}]

let%expect_test "sha256: 'hello world'" =
  print_endline (Cn_sha256.hash "hello world");
  [%expect {| b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9 |}]

let%expect_test "sha256: 55-byte message (boundary: fits in one block with padding)" =
  (* 55 bytes: msg(55) + 0x80(1) + length(8) = 64, exactly one block *)
  let msg = String.make 55 'a' in
  print_endline (Cn_sha256.hash msg);
  [%expect {| 9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318 |}]

let%expect_test "sha256: 56-byte message (boundary: needs two blocks)" =
  (* 56 bytes: msg(56) + 0x80(1) + padding(63) + length(8) = 128, two blocks *)
  let msg = String.make 56 'a' in
  print_endline (Cn_sha256.hash msg);
  [%expect {| b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a |}]

let%expect_test "sha256: 64-byte message (exactly one block before padding)" =
  let msg = String.make 64 'a' in
  print_endline (Cn_sha256.hash msg);
  [%expect {| ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb |}]
