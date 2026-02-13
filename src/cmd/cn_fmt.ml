(** cn_fmt.ml — Terminal output formatting

    Unicode symbols, color output, dry-run mode.
    Used by all CN modules for user-facing output. *)

let check = "\xe2\x9c\x93"   (* ✓ U+2713 *)
let cross = "\xe2\x9c\x97"   (* ✗ U+2717 *)
let warning = "\xe2\x9a\xa0" (* ⚠ U+26A0 *)

let now_iso () =
  let t = Unix.gettimeofday () in
  let tm = Unix.gmtime t in
  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02d.000Z"
    (tm.tm_year + 1900) (tm.tm_mon + 1) tm.tm_mday
    tm.tm_hour tm.tm_min tm.tm_sec

let no_color = Cn_ffi.Process.getenv_opt "NO_COLOR" |> Option.is_some

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
