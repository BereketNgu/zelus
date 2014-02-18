(*
   This program should be rejected because x is both tested before being reset.
   The program is therefore not causual.
 *)

let hybrid main z = x where
  rec init x = true
  and automaton
    | S0 ->
        do
        until z on x then do x = false in S0

