(* Git layer prelude *)

type branch_info = {
  peer: string;
  branch: string;
}

let parse_branch_name name =
  match String.split_on_char '/' name with
  | peer :: rest -> { peer; branch = name }
  | [] -> { peer = "unknown"; branch = name }

(* Mock merge-base detection *)
let orphans = ref ["pi/orphan-topic"]

let has_merge_base branch =
  not (List.mem branch !orphans)

let git_operations = ["fetch"; "push"; "branch -r"; "merge-base"; "show"; "log"]
