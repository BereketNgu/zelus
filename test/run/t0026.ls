(* TEST[-check 20 -period] *)
(* Test the initial state of a nested automaton. *)

let node f () = r where
  automaton
  | S0 -> do
      automaton
      | T0 -> do () = print_endline "T0" and r = true done
      | T1 -> do () = print_endline "T1" and r = false done
    done

let hybrid main () = r where
  rec init r = true
  and der t = 1.0 init 0.0
  and present (period (0.5)) -> do r = f () done

