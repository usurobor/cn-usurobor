(* Test: Rejection Terminal Cleanup *)
(* Run: ocaml spec/system/test_rejection_cleanup.ml *)

#use "prelude.ml";;

let test name expected actual =
  if expected = actual then
    Printf.printf "✓ %s\n" name
  else begin
    Printf.printf "✗ %s\n  expected: %s\n  actual: %s\n" name 
      (match expected with Some s -> s | None -> "None")
      (match actual with Some s -> s | None -> "None");
    exit 1
  end

let test_cleanup name expected actual =
  let exp_str = match expected with Deleted s -> "Deleted " ^ s | NotFound s -> "NotFound " ^ s in
  let act_str = match actual with Deleted s -> "Deleted " ^ s | NotFound s -> "NotFound " ^ s in
  if expected = actual then
    Printf.printf "✓ %s\n" name
  else begin
    Printf.printf "✗ %s\n  expected: %s\n  actual: %s\n" name exp_str act_str;
    exit 1
  end

let () =
  print_endline "\n=== Rejection Terminal Cleanup Tests ===\n";
  
  (* Test parse_rejected_branch *)
  test "parse rejection notice"
    (Some "pi/failed-topic")
    (parse_rejected_branch "Branch `pi/failed-topic` rejected and deleted.");
  
  test "parse non-rejection"
    None
    (parse_rejected_branch "Some other message");
  
  test "parse malformed"
    None
    (parse_rejected_branch "Branch without backticks rejected");
  
  (* Reset state for cleanup tests *)
  local_branches := ["pi/failed-topic"; "pi/other-topic"];
  deleted_branches := [];
  
  (* Test rejection_cleanup *)
  test_cleanup "cleanup existing branch"
    (Deleted "pi/failed-topic")
    (rejection_cleanup ~hub_path:"/test" ~branch:"pi/failed-topic");
  
  test_cleanup "cleanup nonexistent branch"
    (NotFound "pi/nonexistent")
    (rejection_cleanup ~hub_path:"/test" ~branch:"pi/nonexistent");
  
  (* Test process_rejection_notice *)
  local_branches := ["pi/another-failed"];
  let result = process_rejection_notice 
    ~hub_path:"/test" 
    ~content:"Branch `pi/another-failed` rejected and deleted." in
  if result.materialized && result.branch_deleted = Some "pi/another-failed" then
    print_endline "✓ process_rejection_notice with rejection"
  else begin
    print_endline "✗ process_rejection_notice with rejection";
    exit 1
  end;
  
  let result2 = process_rejection_notice 
    ~hub_path:"/test" 
    ~content:"Regular message" in
  if result2.materialized && result2.branch_deleted = None then
    print_endline "✓ process_rejection_notice without rejection"
  else begin
    print_endline "✗ process_rejection_notice without rejection";
    exit 1
  end;
  
  print_endline "\n=== All spec tests passed ===\n"
