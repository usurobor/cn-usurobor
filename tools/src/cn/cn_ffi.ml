(** cn_ffi.ml — Node.js FFI bindings (Melange externals)

    Single source of truth for all Node.js interop used by CN modules.
    Extracted from cn.ml lines 37-99. *)

module Process = struct
  external argv : string array = "argv" [@@mel.scope "process"]
  external cwd : unit -> string = "cwd" [@@mel.scope "process"]
  external exit : int -> unit = "exit" [@@mel.scope "process"]
  external env : string Js.Dict.t = "env" [@@mel.scope "process"]
end

module Fs = struct
  external exists_sync : string -> bool = "existsSync" [@@mel.module "fs"]
  external read_file_sync : string -> string -> string = "readFileSync" [@@mel.module "fs"]
  external write_file_sync : string -> string -> unit = "writeFileSync" [@@mel.module "fs"]
  external append_file_sync : string -> string -> unit = "appendFileSync" [@@mel.module "fs"]
  external unlink_sync : string -> unit = "unlinkSync" [@@mel.module "fs"]
  external readdir_sync : string -> string array = "readdirSync" [@@mel.module "fs"]
  external mkdir_sync : string -> < recursive : bool > Js.t -> unit = "mkdirSync" [@@mel.module "fs"]

  let exists = exists_sync
  let read path = read_file_sync path "utf8"
  let write = write_file_sync
  let append = append_file_sync
  let unlink = unlink_sync
  let readdir path = readdir_sync path |> Array.to_list
  let mkdir_p path = mkdir_sync path [%mel.obj { recursive = true }]
  let ensure_dir path = if not (exists path) then mkdir_p path
end

module Path = struct
  external join : string -> string -> string = "join" [@@mel.module "path"]
  external dirname : string -> string = "dirname" [@@mel.module "path"]
  external basename : string -> string = "basename" [@@mel.module "path"]
  external basename_ext : string -> string -> string = "basename" [@@mel.module "path"]
end

module Yaml = struct
  external parse : string -> Js.Json.t = "parse" [@@mel.module "yaml"]
  external stringify : Js.Json.t -> string = "stringify" [@@mel.module "yaml"]
end

module Child_process = struct
  external exec_sync : string -> < cwd : string ; encoding : string ; stdio : string array > Js.t -> string = "execSync" [@@mel.module "child_process"]
  external exec_sync_simple : string -> < encoding : string > Js.t -> string = "execSync" [@@mel.module "child_process"]

  let exec_in ~cwd cmd =
    match exec_sync cmd [%mel.obj { cwd; encoding = "utf8"; stdio = [|"pipe"; "pipe"; "pipe"|] }] with
    | result -> Some result
    | exception Js.Exn.Error _ -> None

  let exec cmd =
    match exec_sync_simple cmd [%mel.obj { encoding = "utf8" }] with
    | result -> Some result
    | exception Js.Exn.Error _ -> None
end

module Json = struct
  external stringify : 'a -> string = "stringify" [@@mel.scope "JSON"]
end

(* Melange emits UTF-8 literals as \xNN escapes which JS interprets as Latin-1.
   Use String.fromCodePoint for correct Unicode output. *)
module Str = struct
  external from_code_point : int -> string = "fromCodePoint" [@@mel.scope "String"]
end
