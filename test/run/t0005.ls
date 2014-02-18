(* TEST[-check 100] ARGS[] *)
(* Compilation of simple automata *)

let node counter n = o where
  rec o = 0 -> i
  and i = if pre o = n then 0 else pre o + 1

let node counter_with_weak_automaton n = o where
  rec
      automaton
      | S1 -> do o = 0 then S2 done
      | S2 -> do o = last o + 1 until (o = n) then S1 done

let node counter_with_weak_automaton_parameters n = o where
  rec
      automaton
      | S1 -> do o = 0 then S2(0) done
      | S2(k) -> 
          do o = (k + 1) -> pre o + 1 
          until | (o = n - 5) then S2(o)
                | (o = n) then S1 
          done

let node main () =
  let y1 = counter 10 in
  let y2 = counter_with_weak_automaton 10 in
  let y3 = counter_with_weak_automaton_parameters 10 in
  print_int y3; print_newline ();
  (y1 = y2) && (y1 = y3)

