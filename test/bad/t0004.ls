(*
   This program should be rejected because x is initialized both outside and
   inside the match/with (inside a let statement).
 *)

let hybrid main () =
  let rec
      der time = 1.0 init 0.0
  and
      init x = 0.0
  and
      match true with
      | true ->  do der x = 1.0 init 0.0 done
      | false -> do der x = 1.0 init 0.0 done
      in
  ()

