(*
  There is a causality problem because the transition condition is defined in
  parallel with the automaton that defines a variable used within the condition
  (Cf. run/t0015).
*)

let max = 2.0

let hybrid f z = pos where
  rec init pos = 0.0
  and automaton
    | S0 ->
        do
          der pos = 0.0
        until (z on (not atmax)) then S1

    | S1 ->
        do
          der pos = 1.0
        until (up(pos -. max)) then S0
    end

  and atmax = ((* last *) pos >= max)

let hybrid main () = check where
  rec z = period (1.0)
  and y = f(z)
  and check = present z -> (y <= max +. 0.1) else true

