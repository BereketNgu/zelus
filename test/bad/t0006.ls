(*
   This program should be rejected because x is initialized both outside and
   inside the automaton (in a definition).
 *)

let hybrid main () = () where
  rec
      der time = 1.0 init 0.0
  and
      init x = 0.0
  and
      automaton
      | One -> do der x = 1.0 init 0.0 done
      | Two -> do der x = 1.0 init 0.0 done

