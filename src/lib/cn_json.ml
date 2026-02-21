(** cn_json.ml — Minimal JSON parser/emitter (pure, no deps)

    Handles the subset of JSON needed for Anthropic Messages API,
    Telegram Bot API responses, and .cn/config.json.

    Design constraints:
    - to_string produces single-line output (curl config injection safety)
    - \uXXXX escapes decoded to UTF-8 (Telegram sends these for emoji)
    - Unknown fields ignored (forward compatibility)
    - UTF-8 bytes passed through unmodified *)

type t =
  | Null
  | Bool of bool
  | Int of int
  | Float of float
  | String of string
  | Array of t list
  | Object of (string * t) list

(* === Accessors === *)

let get key = function
  | Object fields -> List.assoc_opt key fields
  | _ -> None

let get_string key j =
  match get key j with Some (String s) -> Some s | _ -> None

let get_int key j =
  match get key j with Some (Int i) -> Some i | _ -> None

let get_list key j =
  match get key j with Some (Array l) -> Some l | _ -> None

(* === Emitter === *)

let escape_string s =
  let buf = Buffer.create (String.length s + 8) in
  Buffer.add_char buf '"';
  String.iter (fun c ->
    match c with
    | '"'  -> Buffer.add_string buf "\\\""
    | '\\' -> Buffer.add_string buf "\\\\"
    | '\n' -> Buffer.add_string buf "\\n"
    | '\r' -> Buffer.add_string buf "\\r"
    | '\t' -> Buffer.add_string buf "\\t"
    | '\b' -> Buffer.add_string buf "\\b"
    | c when Char.code c < 0x20 ->
        Buffer.add_string buf (Printf.sprintf "\\u%04x" (Char.code c))
    | c -> Buffer.add_char buf c
  ) s;
  Buffer.add_char buf '"';
  Buffer.contents buf

(** Serialize JSON to a single-line string. No trailing newline.
    Critical: callers depend on single-line guarantee for curl config. *)
let rec to_string = function
  | Null -> "null"
  | Bool true -> "true"
  | Bool false -> "false"
  | Int i -> string_of_int i
  | Float f ->
      let s = Printf.sprintf "%.17g" f in
      if String.contains s '.' || String.contains s 'e' then s
      else s ^ ".0"
  | String s -> escape_string s
  | Array items ->
      "[" ^ String.concat "," (List.map to_string items) ^ "]"
  | Object fields ->
      let pair (k, v) = escape_string k ^ ":" ^ to_string v in
      "{" ^ String.concat "," (List.map pair fields) ^ "}"

(* === Parser === *)

type state = {
  src : string;
  mutable pos : int;
}

let make_state s = { src = s; pos = 0 }

let peek st =
  if st.pos < String.length st.src then Some st.src.[st.pos] else None

let advance st = st.pos <- st.pos + 1

let skip_ws st =
  while st.pos < String.length st.src &&
        (let c = st.src.[st.pos] in c = ' ' || c = '\t' || c = '\n' || c = '\r')
  do advance st done

let expect st c =
  skip_ws st;
  if st.pos < String.length st.src && st.src.[st.pos] = c then
    (advance st; Ok ())
  else
    Error (Printf.sprintf "expected '%c' at pos %d" c st.pos)

let expect_str st s =
  let len = String.length s in
  if st.pos + len <= String.length st.src &&
     String.sub st.src st.pos len = s then
    (st.pos <- st.pos + len; Ok ())
  else
    Error (Printf.sprintf "expected '%s' at pos %d" s st.pos)

(** Encode a Unicode code point as UTF-8 bytes. *)
let utf8_of_codepoint buf cp =
  if cp < 0x80 then
    Buffer.add_char buf (Char.chr cp)
  else if cp < 0x800 then begin
    Buffer.add_char buf (Char.chr (0xC0 lor (cp lsr 6)));
    Buffer.add_char buf (Char.chr (0x80 lor (cp land 0x3F)))
  end else if cp < 0x10000 then begin
    Buffer.add_char buf (Char.chr (0xE0 lor (cp lsr 12)));
    Buffer.add_char buf (Char.chr (0x80 lor ((cp lsr 6) land 0x3F)));
    Buffer.add_char buf (Char.chr (0x80 lor (cp land 0x3F)))
  end else begin
    Buffer.add_char buf (Char.chr (0xF0 lor (cp lsr 18)));
    Buffer.add_char buf (Char.chr (0x80 lor ((cp lsr 12) land 0x3F)));
    Buffer.add_char buf (Char.chr (0x80 lor ((cp lsr 6) land 0x3F)));
    Buffer.add_char buf (Char.chr (0x80 lor (cp land 0x3F)))
  end

let hex_digit c =
  match c with
  | '0'..'9' -> Some (Char.code c - Char.code '0')
  | 'a'..'f' -> Some (Char.code c - Char.code 'a' + 10)
  | 'A'..'F' -> Some (Char.code c - Char.code 'A' + 10)
  | _ -> None

let parse_hex4 st =
  if st.pos + 4 > String.length st.src then
    Error (Printf.sprintf "unexpected end of \\uXXXX at pos %d" st.pos)
  else
    let r = ref 0 in
    let ok = ref true in
    for i = 0 to 3 do
      match hex_digit st.src.[st.pos + i] with
      | Some d -> r := !r * 16 + d
      | None -> ok := false
    done;
    if !ok then (st.pos <- st.pos + 4; Ok !r)
    else Error (Printf.sprintf "invalid hex in \\uXXXX at pos %d" st.pos)

let parse_string st =
  match expect st '"' with
  | Error e -> Error e
  | Ok () ->
    let buf = Buffer.create 64 in
    let rec loop () =
      if st.pos >= String.length st.src then
        Error (Printf.sprintf "unterminated string at pos %d" st.pos)
      else
        let c = st.src.[st.pos] in
        if c = '"' then (advance st; Ok (Buffer.contents buf))
        else if c = '\\' then begin
          advance st;
          if st.pos >= String.length st.src then
            Error (Printf.sprintf "unterminated escape at pos %d" st.pos)
          else
            let esc = st.src.[st.pos] in
            advance st;
            match esc with
            | '"'  -> Buffer.add_char buf '"'; loop ()
            | '\\' -> Buffer.add_char buf '\\'; loop ()
            | '/'  -> Buffer.add_char buf '/'; loop ()
            | 'b'  -> Buffer.add_char buf '\b'; loop ()
            | 'f'  -> Buffer.add_char buf '\x0C'; loop ()
            | 'n'  -> Buffer.add_char buf '\n'; loop ()
            | 'r'  -> Buffer.add_char buf '\r'; loop ()
            | 't'  -> Buffer.add_char buf '\t'; loop ()
            | 'u'  ->
                (match parse_hex4 st with
                 | Error e -> Error e
                 | Ok hi ->
                   (* Handle surrogate pairs: \uD800-\uDBFF followed by \uDC00-\uDFFF *)
                   if hi >= 0xD800 && hi <= 0xDBFF then
                     match expect_str st "\\u" with
                     | Error _ ->
                         (* Lone high surrogate — emit replacement char *)
                         utf8_of_codepoint buf 0xFFFD; loop ()
                     | Ok () ->
                       (match parse_hex4 st with
                        | Error e -> Error e
                        | Ok lo ->
                          if lo >= 0xDC00 && lo <= 0xDFFF then begin
                            let cp = 0x10000 + (hi - 0xD800) * 0x400 + (lo - 0xDC00) in
                            utf8_of_codepoint buf cp; loop ()
                          end else begin
                            utf8_of_codepoint buf 0xFFFD;
                            utf8_of_codepoint buf lo; loop ()
                          end)
                   else begin
                     utf8_of_codepoint buf hi; loop ()
                   end)
            | _ -> Error (Printf.sprintf "unknown escape '\\%c' at pos %d" esc st.pos)
        end else begin
          Buffer.add_char buf c; advance st; loop ()
        end
    in
    loop ()

let rec parse_value st =
  skip_ws st;
  match peek st with
  | None -> Error (Printf.sprintf "unexpected end of input at pos %d" st.pos)
  | Some '"' -> (match parse_string st with Ok s -> Ok (String s) | Error e -> Error e)
  | Some '{' -> parse_object st
  | Some '[' -> parse_array st
  | Some 't' -> (match expect_str st "true"  with Ok () -> Ok (Bool true) | Error e -> Error e)
  | Some 'f' -> (match expect_str st "false" with Ok () -> Ok (Bool false) | Error e -> Error e)
  | Some 'n' -> (match expect_str st "null"  with Ok () -> Ok Null | Error e -> Error e)
  | Some c when c = '-' || (c >= '0' && c <= '9') -> parse_number st
  | Some c -> Error (Printf.sprintf "unexpected char '%c' at pos %d" c st.pos)

and parse_object st =
  match expect st '{' with
  | Error e -> Error e
  | Ok () ->
    skip_ws st;
    if peek st = Some '}' then (advance st; Ok (Object []))
    else
      let rec fields acc =
        match parse_string st with
        | Error e -> Error e
        | Ok key ->
          match expect st ':' with
          | Error e -> Error e
          | Ok () ->
            match parse_value st with
            | Error e -> Error e
            | Ok v ->
              let acc = (key, v) :: acc in
              skip_ws st;
              match peek st with
              | Some ',' -> advance st; skip_ws st; fields acc
              | Some '}' -> advance st; Ok (Object (List.rev acc))
              | _ -> Error (Printf.sprintf "expected ',' or '}' at pos %d" st.pos)
      in
      fields []

and parse_array st =
  match expect st '[' with
  | Error e -> Error e
  | Ok () ->
    skip_ws st;
    if peek st = Some ']' then (advance st; Ok (Array []))
    else
      let rec items acc =
        match parse_value st with
        | Error e -> Error e
        | Ok v ->
          let acc = v :: acc in
          skip_ws st;
          match peek st with
          | Some ',' -> advance st; skip_ws st; items acc
          | Some ']' -> advance st; Ok (Array (List.rev acc))
          | _ -> Error (Printf.sprintf "expected ',' or ']' at pos %d" st.pos)
      in
      items []

and parse_number st =
  let start = st.pos in
  if st.pos < String.length st.src && st.src.[st.pos] = '-' then advance st;
  (* Integer part *)
  while st.pos < String.length st.src &&
        st.src.[st.pos] >= '0' && st.src.[st.pos] <= '9'
  do advance st done;
  let is_float = ref false in
  (* Fractional part *)
  if st.pos < String.length st.src && st.src.[st.pos] = '.' then begin
    is_float := true; advance st;
    while st.pos < String.length st.src &&
          st.src.[st.pos] >= '0' && st.src.[st.pos] <= '9'
    do advance st done
  end;
  (* Exponent *)
  if st.pos < String.length st.src &&
     (st.src.[st.pos] = 'e' || st.src.[st.pos] = 'E') then begin
    is_float := true; advance st;
    if st.pos < String.length st.src &&
       (st.src.[st.pos] = '+' || st.src.[st.pos] = '-') then advance st;
    while st.pos < String.length st.src &&
          st.src.[st.pos] >= '0' && st.src.[st.pos] <= '9'
    do advance st done
  end;
  let s = String.sub st.src start (st.pos - start) in
  if !is_float then
    match float_of_string_opt s with
    | Some f -> Ok (Float f)
    | None -> Error (Printf.sprintf "invalid number '%s' at pos %d" s start)
  else
    match int_of_string_opt s with
    | Some i -> Ok (Int i)
    | None ->
      (* Integer too large for int — fall back to float *)
      match float_of_string_opt s with
      | Some f -> Ok (Float f)
      | None -> Error (Printf.sprintf "invalid number '%s' at pos %d" s start)

let parse s =
  let st = make_state s in
  match parse_value st with
  | Error e -> Error e
  | Ok v ->
    skip_ws st;
    if st.pos = String.length st.src then Ok v
    else Error (Printf.sprintf "trailing content at pos %d" st.pos)
