(** cn_fmt.ml — Terminal output formatting

    Unicode symbols, color output, dry-run mode.
    Used by all CN modules for user-facing output. *)

let check = Cn_ffi.Str.from_code_point 0x2713  (* ✓ U+2713 *)
let cross = Cn_ffi.Str.from_code_point 0x2717  (* ✗ U+2717 *)
let warning = Cn_ffi.Str.from_code_point 0x26A0 (* ⚠ U+26A0 *)

let now_iso () = Js.Date.toISOString (Js.Date.make ())

let no_color = Js.Dict.get Cn_ffi.Process.env "NO_COLOR" |> Option.is_some

let color code s = if no_color then s else Printf.sprintf "\027[%sm%s\027[0m" code s
let green = color "32"
let red = color "31"
let yellow = color "33"
let cyan = color "36"
let dim = color "2"

let ok msg = green (check ^ " ") ^ msg
let fail msg = red (cross ^ " ") ^ msg
let warn msg = yellow (warning ^ " ") ^ msg
let info = cyan

let dry_run_mode = ref false

let would msg =
  if !dry_run_mode then begin
    print_endline (dim ("Would: " ^ msg));
    true
  end else false

let dry_run_banner () =
  if !dry_run_mode then
    print_endline (warn "DRY RUN — no changes will be made")
