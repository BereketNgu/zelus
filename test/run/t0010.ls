(* TEST[-check 20 -period] ARGS[-precisetime] *)
(* Test for the persistence of discrete every; i.e., x should start at 0.0 and
   then, at some point, change permanently to 1.0 *)
(* For more information, add these two options to ARGS[] above:
      -lzeroc -lgcalls *)

let node do_check (t, x) =
  let () = print_string "t=" in
  let () = print_float t in
  let () = print_string " x=" in
  let () = print_float x in
  let () = print_string "\n" in
  let () = flush_all () in
  t < 1.1 || x = 1.0

let hybrid main () = check where
  rec der t = 1.0 init 0.0
  and x = present (up(t -. 1.0)) -> 1.0 init 0.1
  and check = present (period (0.5)) -> do_check (t, x) init true

