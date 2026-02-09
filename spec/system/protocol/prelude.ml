(* Protocol layer prelude *)

type peer_info = {
  name: string;
  hub: string option;
  clone: string option;
  kind: string option;
}

type validation_result =
  | Valid of { merge_base: string }
  | Orphan of { reason: string }

let example_peer = {
  name = "pi";
  hub = Some "https://github.com/user/cn-pi";
  clone = Some "/path/to/cn-pi-clone";
  kind = Some "agent";
}

let orphans = ref ["pi/orphan-topic"]

let validate_branch branch =
  if List.mem branch !orphans then
    Orphan { reason = "no merge base with main" }
  else
    Valid { merge_base = "abc123" }

let rejection_notice peer branch =
  Printf.sprintf "Branch %s rejected: no merge base with main" branch

let sync_phases = ["fetch"; "validate"; "materialize"; "triage"; "flush"]

let required_frontmatter = ["to"; "created"]
let optional_frontmatter = ["from"; "subject"; "in-reply-to"; "branch"; "trigger"]
