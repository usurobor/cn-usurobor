(** cn_ffi.ml — Native OCaml system bindings

    Replaces Node.js FFI with stdlib + Unix.
    Single source of truth for all system interop used by CN modules. *)

module Process = struct
  let argv = Sys.argv
  let cwd () = Sys.getcwd ()
  let exit = exit
  let getenv_opt = Sys.getenv_opt
end

module Fs = struct
  let exists = Sys.file_exists

  let read path =
    let ic = open_in path in
    try
      let n = in_channel_length ic in
      let s = Bytes.create n in
      really_input ic s 0 n;
      close_in ic;
      Bytes.to_string s
    with e ->
      close_in_noerr ic;
      raise e

  let write path content =
    let oc = open_out path in
    try
      output_string oc content;
      close_out oc
    with e ->
      close_out_noerr oc;
      raise e

  let append path content =
    let oc = open_out_gen [Open_append; Open_creat; Open_text] 0o644 path in
    try
      output_string oc content;
      close_out oc
    with e ->
      close_out_noerr oc;
      raise e

  let readdir path = Sys.readdir path |> Array.to_list

  let unlink = Sys.remove

  let rec mkdir_p path =
    if path <> "" && path <> "/" && not (Sys.file_exists path) then begin
      mkdir_p (Filename.dirname path);
      try Unix.mkdir path 0o755
      with Unix.Unix_error (Unix.EEXIST, _, _) -> ()
    end

  let ensure_dir path = if not (exists path) then mkdir_p path
end

module Path = struct
  let join = Filename.concat
  let dirname = Filename.dirname
  let basename = Filename.basename
  let basename_ext path _ext = Filename.remove_extension (basename path)
end

module Child_process = struct
  let exec_in ~cwd cmd =
    let full_cmd = Printf.sprintf "cd %s && %s" (Filename.quote cwd) cmd in
    try
      let ic = Unix.open_process_in full_cmd in
      let buf = Buffer.create 1024 in
      (try while true do Buffer.add_char buf (input_char ic) done
       with End_of_file -> ());
      match Unix.close_process_in ic with
      | Unix.WEXITED 0 -> Some (Buffer.contents buf)
      | _ -> None
    with _ -> None

  let exec cmd =
    try
      let ic = Unix.open_process_in cmd in
      let buf = Buffer.create 1024 in
      (try while true do Buffer.add_char buf (input_char ic) done
       with End_of_file -> ());
      match Unix.close_process_in ic with
      | Unix.WEXITED 0 -> Some (Buffer.contents buf)
      | _ -> None
    with _ -> None
end
