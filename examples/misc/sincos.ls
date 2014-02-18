(* Sinus/Cosinus *)
let hybrid f () = (sin, cos) where
  rec der cos = -. sin init 1.0 reset z -> 1.0
  and der sin = cos init 0.0  reset z -> 0.0
  and z = period (4.0)

let hybrid g () = (sin, cos, sin_cos) where
  rec 
      automaton
      | Mode1 ->
	  do sin, cos = f()
	  until z then Mode2
      | Mode2 ->
	  do sin = 0.0 and cos = 0.0
	  until z then Mode1
      end
  and z = period (2.5)
  and sin_cos = sin *. sin +. cos *. cos

open Scope

let hybrid main () =
  let der t = 1.0 init 0.0 in
  let (sin, cos, sin_cos) = g () in
  present (period (0.1)) ->
      let s = Scope.scope3 (-1.0, 2.5, ("sin", Scope.linear, sin),
                                       ("cos", Scope.linear, cos),
                                       ("sin_cos", Scope.linear, sin_cos))
      in Scope.window ("sincos", 10.0, t, s)
  else ()

