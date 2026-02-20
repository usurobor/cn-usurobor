(** cn_ffi.ml — Native OCaml system bindings

    Single source of truth for all system interop used by CN modules.
    Uses stdlib + Unix only. *)

module Process = struct
  let argv = Sys.argv
  let cwd () = Sys.getcwd ()
  let exit = exit
  let getenv_opt = Sys.getenv_opt

  let exec_args ~prog ~args ?(stdin_data = "") () =
    let argv = Array.of_list (prog :: args) in
    let stdin_r, stdin_w = Unix.pipe ~cloexec:true () in
    let stdout_r, stdout_w = Unix.pipe ~cloexec:true () in
    let stderr_r, stderr_w = Unix.pipe ~cloexec:true () in
    let pid = Unix.create_process prog argv stdin_r stdout_w stderr_w in
    (* Parent closes child-side fds *)
    Unix.close stdin_r;
    Unix.close stdout_w;
    Unix.close stderr_w;
    (* Write stdin_data, then close to signal EOF *)
    if stdin_data <> "" then begin
      let b = Bytes.of_string stdin_data in
      let len = Bytes.length b in
      let rec write_all off =
        if off < len then
          let n = Unix.write stdin_w b off (len - off) in
          write_all (off + n)
      in
      write_all 0
    end;
    Unix.close stdin_w;
    (* Read stdout and stderr *)
    let read_fd fd =
      let buf = Buffer.create 4096 in
      let tmp = Bytes.create 4096 in
      let rec loop () =
        match Unix.read fd tmp 0 4096 with
        | 0 -> ()
        | n -> Buffer.add_subbytes buf tmp 0 n; loop ()
        | exception Unix.Unix_error (Unix.EINTR, _, _) -> loop ()
      in
      loop (); Unix.close fd; Buffer.contents buf
    in
    let stdout_s = read_fd stdout_r in
    let stderr_s = read_fd stderr_r in
    let _, status = Unix.waitpid [] pid in
    let code = match status with
      | Unix.WEXITED c -> c
      | Unix.WSIGNALED s -> 128 + s
      | Unix.WSTOPPED s -> 128 + s
    in
    (code, stdout_s, stderr_s)
end

module Fs = struct
  let exists = Sys.file_exists

  let read path =
    let ic = open_in path in
    Fun.protect ~finally:(fun () -> close_in_noerr ic) (fun () ->
      let n = in_channel_length ic in
      let s = Bytes.create n in
      really_input ic s 0 n;
      Bytes.to_string s)

  let write path content =
    let oc = open_out path in
    Fun.protect ~finally:(fun () -> close_out_noerr oc) (fun () ->
      output_string oc content)

  let append path content =
    let oc = open_out_gen [Open_append; Open_creat; Open_text] 0o644 path in
    Fun.protect ~finally:(fun () -> close_out_noerr oc) (fun () ->
      output_string oc content)

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
  let read_all ic =
    let buf = Buffer.create 1024 in
    (try while true do Buffer.add_char buf (input_char ic) done
     with End_of_file -> ());
    Buffer.contents buf

  let exec_in ~cwd cmd =
    let full_cmd = Printf.sprintf "cd %s && %s" (Filename.quote cwd) cmd in
    try
      let ic = Unix.open_process_in full_cmd in
      let output = read_all ic in
      match Unix.close_process_in ic with
      | Unix.WEXITED 0 -> Some output
      | _ -> None
    with Unix.Unix_error _ | Sys_error _ -> None

  let exec cmd =
    try
      let ic = Unix.open_process_in cmd in
      let output = read_all ic in
      match Unix.close_process_in ic with
      | Unix.WEXITED 0 -> Some output
      | _ -> None
    with Unix.Unix_error _ | Sys_error _ -> None
end

module Http = struct
  (** Escape a string for use as a curl --config quoted value.
      Curl config values are enclosed in double quotes. Inside:
      - backslash must be doubled: \ → \\
      - double quote must be escaped: " → \"
      - literal newlines are forbidden (would terminate the directive)
      We replace CR/LF with spaces as a safety net — callers should
      already guarantee single-line JSON bodies. *)
  let curl_quote s =
    let buf = Buffer.create (String.length s + 16) in
    String.iter (fun c ->
      match c with
      | '\\' -> Buffer.add_string buf "\\\\"
      | '"'  -> Buffer.add_string buf "\\\""
      | '\n' -> Buffer.add_char buf ' '
      | '\r' -> ()
      | c    -> Buffer.add_char buf c
    ) s;
    Buffer.contents buf

  let request ~meth ~url ~headers ~body =
    let buf = Buffer.create 512 in
    Buffer.add_string buf (Printf.sprintf "url = \"%s\"\n" (curl_quote url));
    if meth = "POST" then
      Buffer.add_string buf "request = \"POST\"\n";
    List.iter (fun (k, v) ->
      Buffer.add_string buf
        (Printf.sprintf "header = \"%s: %s\"\n" (curl_quote k) (curl_quote v))
    ) headers;
    (match body with
     | Some b -> Buffer.add_string buf (Printf.sprintf "data = \"%s\"\n" (curl_quote b))
     | None -> ());
    Buffer.add_string buf "silent\n";
    Buffer.add_string buf "show-error\n";
    Buffer.add_string buf "fail\n";
    let config = Buffer.contents buf in
    let code, stdout_s, stderr_s =
      Process.exec_args ~prog:"curl" ~args:["--config"; "-"]
        ~stdin_data:config ()
    in
    if code = 0 then Ok stdout_s
    else Error (Printf.sprintf "curl exit %d: %s" code (String.trim stderr_s))

  let post ~url ~headers ~body =
    request ~meth:"POST" ~url ~headers ~body:(Some body)

  let get ~url ~headers =
    request ~meth:"GET" ~url ~headers ~body:None
end
