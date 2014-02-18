(* Single variable of paired signal type inside a block *)

let node es () = (s1, s2) where
  rec emit s1 = ()
  and emit s2 = ()

let node f (z) = s1s2 where
  automaton
  | S0 ->
      do
        s1s2 = es ()
      done
  | S1 -> do done

