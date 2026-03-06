(** cn_sha256.ml — Pure OCaml SHA-256 (no external deps)

    Implements FIPS 180-4 SHA-256 for artifact hashing.
    Operates on strings; returns hex-encoded digest.

    Uses Int32 for 32-bit word operations to avoid platform
    differences with native int width. *)

(* === Int32 helpers === *)

let ( +~ ) = Int32.add
let ( &~ ) = Int32.logand
let ( |~ ) = Int32.logor
let ( ^~ ) = Int32.logxor
let ( !~ ) = Int32.lognot
let shr n x = Int32.shift_right_logical x n
let rotr n x = Int32.logor (Int32.shift_right_logical x n) (Int32.shift_left x (32 - n))

(* === Constants === *)

let k = [|
  0x428a2f98l; 0x71374491l; 0xb5c0fbcfl; 0xe9b5dba5l;
  0x3956c25bl; 0x59f111f1l; 0x923f82a4l; 0xab1c5ed5l;
  0xd807aa98l; 0x12835b01l; 0x243185bel; 0x550c7dc3l;
  0x72be5d74l; 0x80deb1fel; 0x9bdc06a7l; 0xc19bf174l;
  0xe49b69c1l; 0xefbe4786l; 0x0fc19dc6l; 0x240ca1ccl;
  0x2de92c6fl; 0x4a7484aal; 0x5cb0a9dcl; 0x76f988dal;
  0x983e5152l; 0xa831c66dl; 0xb00327c8l; 0xbf597fc7l;
  0xc6e00bf3l; 0xd5a79147l; 0x06ca6351l; 0x14292967l;
  0x27b70a85l; 0x2e1b2138l; 0x4d2c6dfcl; 0x53380d13l;
  0x650a7354l; 0x766a0abbl; 0x81c2c92el; 0x92722c85l;
  0xa2bfe8a1l; 0xa81a664bl; 0xc24b8b70l; 0xc76c51a3l;
  0xd192e819l; 0xd6990624l; 0xf40e3585l; 0x106aa070l;
  0x19a4c116l; 0x1e376c08l; 0x2748774cl; 0x34b0bcb5l;
  0x391c0cb3l; 0x4ed8aa4al; 0x5b9cca4fl; 0x682e6ff3l;
  0x748f82eel; 0x78a5636fl; 0x84c87814l; 0x8cc70208l;
  0x90befffal; 0xa4506cebl; 0xbef9a3f7l; 0xc67178f2l;
|]

let h0 = [|
  0x6a09e667l; 0xbb67ae85l; 0x3c6ef372l; 0xa54ff53al;
  0x510e527fl; 0x9b05688cl; 0x1f83d9abl; 0x5be0cd19l;
|]

(* === Padding === *)

(** Pad message to 512-bit (64-byte) block boundary per FIPS 180-4. *)
let pad msg =
  let len = String.length msg in
  let bit_len = Int64.of_int (len * 8) in
  (* Need: len + 1 (0x80 byte) + padding + 8 (length) ≡ 0 mod 64 *)
  let pad_len =
    let rem = (len + 1 + 8) mod 64 in
    if rem = 0 then 0 else 64 - rem
  in
  let total = len + 1 + pad_len + 8 in
  let buf = Bytes.create total in
  Bytes.blit_string msg 0 buf 0 len;
  Bytes.set buf len '\x80';
  Bytes.fill buf (len + 1) pad_len '\x00';
  (* Big-endian 64-bit length *)
  for i = 0 to 7 do
    Bytes.set buf (total - 8 + i)
      (Char.chr (Int64.to_int (Int64.shift_right_logical bit_len ((7 - i) * 8)) land 0xff))
  done;
  Bytes.to_string buf

(* === Block processing === *)

(** Read a big-endian 32-bit word from a string at offset. *)
let get_u32be s off =
  let b i = Int32.of_int (Char.code s.[off + i]) in
  Int32.logor
    (Int32.logor
       (Int32.shift_left (b 0) 24)
       (Int32.shift_left (b 1) 16))
    (Int32.logor
       (Int32.shift_left (b 2) 8)
       (b 3))

(** Process a single 512-bit block. Mutates the hash state array. *)
let process_block state block_str offset =
  let w = Array.make 64 0l in
  (* Load 16 words from block *)
  for i = 0 to 15 do
    w.(i) <- get_u32be block_str (offset + i * 4)
  done;
  (* Extend to 64 words *)
  for i = 16 to 63 do
    let s0 = rotr 7 w.(i-15) ^~ rotr 18 w.(i-15) ^~ shr 3 w.(i-15) in
    let s1 = rotr 17 w.(i-2) ^~ rotr 19 w.(i-2) ^~ shr 10 w.(i-2) in
    w.(i) <- w.(i-16) +~ s0 +~ w.(i-7) +~ s1
  done;
  (* Working variables *)
  let a = ref state.(0) in
  let b = ref state.(1) in
  let c = ref state.(2) in
  let d = ref state.(3) in
  let e = ref state.(4) in
  let f = ref state.(5) in
  let g = ref state.(6) in
  let h = ref state.(7) in
  (* 64 rounds *)
  for i = 0 to 63 do
    let s1 = rotr 6 !e ^~ rotr 11 !e ^~ rotr 25 !e in
    let ch = (!e &~ !f) ^~ (!~ !e &~ !g) in
    let temp1 = !h +~ s1 +~ ch +~ k.(i) +~ w.(i) in
    let s0 = rotr 2 !a ^~ rotr 13 !a ^~ rotr 22 !a in
    let maj = (!a &~ !b) ^~ (!a &~ !c) ^~ (!b &~ !c) in
    let temp2 = s0 +~ maj in
    h := !g;
    g := !f;
    f := !e;
    e := !d +~ temp1;
    d := !c;
    c := !b;
    b := !a;
    a := temp1 +~ temp2
  done;
  state.(0) <- state.(0) +~ !a;
  state.(1) <- state.(1) +~ !b;
  state.(2) <- state.(2) +~ !c;
  state.(3) <- state.(3) +~ !d;
  state.(4) <- state.(4) +~ !e;
  state.(5) <- state.(5) +~ !f;
  state.(6) <- state.(6) +~ !g;
  state.(7) <- state.(7) +~ !h

(* === Public API === *)

(** Compute SHA-256 of a string. Returns hex-encoded lowercase digest. *)
let hash s =
  let padded = pad s in
  let state = Array.copy h0 in
  let num_blocks = String.length padded / 64 in
  for i = 0 to num_blocks - 1 do
    process_block state padded (i * 64)
  done;
  let buf = Buffer.create 64 in
  Array.iter (fun w ->
    Buffer.add_string buf (Printf.sprintf "%08lx" w)
  ) state;
  Buffer.contents buf

(** Hash with "sha256:" prefix for receipt format. *)
let hash_prefixed s = "sha256:" ^ hash s
