(** cn.ml — CLI entrypoint, thin dispatch (Melange → Node.js)

    DESIGN: This is the CLI dispatch layer. It parses args,
    finds the hub, and routes to the right module.

    Layering (deliberate):
      cn.ml         → Dispatch (THIS FILE — ~100 lines)
      cn_agent.ml   → Agent I/O, queue, execution
      cn_mail.ml    → Inbox/outbox mail transport
      cn_gtd.ml     → Thread lifecycle + creation
      cn_mca.ml     → Managed Concern Aggregation
      cn_commands.ml→ Peers + git commands
      cn_system.ml  → Setup, update, init
      cn_hub.ml     → Hub discovery, paths, helpers
      cn_fmt.ml     → Output formatting
      cn_ffi.ml     → Node.js FFI bindings
      cn_io.ml      → Protocol I/O (sync, flush, archive)
      cn_lib.ml     → Types, parsing (pure)
      git.ml        → Raw git operations *)

open Cn_lib

let drop n lst =
  let rec go n lst = match n, lst with
    | 0, lst -> lst
    | _, [] -> []
    | n, _ :: rest -> go (n - 1) rest
  in go n lst

let () =
  Cn_system.self_update_check ();

  let args = Cn_ffi.Process.argv |> Array.to_list |> drop 2 in
  let flags, cmd_args = parse_flags args in
  Cn_fmt.dry_run_mode := flags.dry_run;
  if flags.dry_run then Cn_fmt.dry_run_banner ();

  match parse_command cmd_args with
  | None ->
      (match cmd_args with cmd :: _ -> print_endline (Cn_fmt.fail (Printf.sprintf "Unknown command: %s" cmd)) | [] -> ());
      print_endline help_text;
      Cn_ffi.Process.exit 1
  | Some Help -> print_endline help_text
  | Some Version -> Printf.printf "cn %s\n" version
  | Some Update ->
      (match Cn_hub.find_hub_path (Cn_ffi.Process.cwd ()) with
       | Some hub_path -> Cn_system.run_update_with_cron hub_path
       | None -> Cn_system.run_update ())
  | Some (Init name) -> Cn_system.run_init name
  | Some cmd ->
      match Cn_hub.find_hub_path (Cn_ffi.Process.cwd ()) with
      | None ->
          print_endline (Cn_fmt.fail "Not in a cn hub.");
          print_endline "";
          print_endline "Either:";
          print_endline "  1) cd into an existing hub (cn-sigma, cn-pi, etc.)";
          print_endline "  2) cn init <name> to create a new one";
          Cn_ffi.Process.exit 1
      | Some hub_path ->
          let name = derive_name hub_path in
          match cmd with
          | Status -> Cn_system.run_status hub_path name
          | Doctor -> Cn_system.run_doctor hub_path
          | Inbox Inbox.Check -> Cn_mail.inbox_check hub_path name
          | Inbox Inbox.Process -> Cn_mail.inbox_process hub_path
          | Inbox Inbox.Flush -> Cn_mail.inbox_flush hub_path name
          | Outbox Outbox.Check -> Cn_mail.outbox_check hub_path
          | Outbox Outbox.Flush -> Cn_mail.outbox_flush hub_path name
          | Sync -> Cn_system.run_sync hub_path name
          | Next -> Cn_mail.run_next hub_path
          | Inbound -> Cn_agent.run_inbound hub_path name
          | Read t -> Cn_gtd.run_read hub_path t
          | Reply (t, m) -> Cn_commands.run_reply hub_path t m
          | Send (p, m) -> Cn_commands.run_send hub_path p m
          | Gtd (Gtd.Delete t) -> Cn_gtd.gtd_delete hub_path t
          | Gtd (Gtd.Defer (t, u)) -> Cn_gtd.gtd_defer hub_path t u
          | Gtd (Gtd.Delegate (t, p)) -> Cn_gtd.gtd_delegate hub_path name t p
          | Gtd (Gtd.Do t) -> Cn_gtd.gtd_do hub_path t
          | Gtd (Gtd.Done t) -> Cn_gtd.gtd_done hub_path t
          | Commit msg -> Cn_commands.run_commit hub_path name msg
          | Push -> Cn_commands.run_push hub_path
          | Save msg -> Cn_commands.run_commit hub_path name msg; Cn_commands.run_push hub_path
          | Peer Peer.List -> Cn_commands.run_peer_list hub_path
          | Peer (Peer.Add (n, url)) -> Cn_commands.run_peer_add hub_path n url
          | Peer (Peer.Remove n) -> Cn_commands.run_peer_remove hub_path n
          | Peer Peer.Sync -> Cn_commands.run_peer_sync hub_path
          | Queue Queue.List -> Cn_agent.run_queue_list hub_path
          | Queue Queue.Clear -> Cn_agent.run_queue_clear hub_path
          | Mca Mca.List -> Cn_mca.run_mca_list hub_path
          | Mca (Mca.Add desc) -> Cn_mca.run_mca_add hub_path name desc
          | Out gtd -> Cn_agent.run_out hub_path name gtd
          | Adhoc title -> Cn_gtd.run_adhoc hub_path title
          | Daily -> Cn_gtd.run_daily hub_path
          | Weekly -> Cn_gtd.run_weekly hub_path
          | Setup -> Cn_system.run_setup hub_path
          | Help | Version | Init _ | Update -> ()
