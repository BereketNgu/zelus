(* TEST[-period] *)
(* automaton containing a period in a guard of a nested let/in *)

let hybrid nested z = x where
  x = (let automaton
           | S0 -> 
              do
                p = 1
              until (period 1.0(1.0)) then S1(3)
           | S1(t) ->
              do
                p = 2
              done
           end
       in p)

let hybrid main () =
  let
  rec der y = 1.0 init -2.0
  and x = nested (up(y)) in
  ()

