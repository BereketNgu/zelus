(* TEST[-check 20 -period] *)

(* Check for a simultaneous reset of two derivatives by a pair-valued signal
   given directly. Compare to t0025.ls where the signal value is returned by
   a function.

   Expected behaviour of x: a sawtooth signal, rising from -1 to 0 with a slope
   of 1, then being reset to -1 and starting again.

   Expected behaviour of y: a sawtooth signal, rising from -2 to -1 with a slope
   of 1, then being reset to -2 and starting again.
     
   Both signals are sampled at 0.5, 1.5, 2.5, ... when x should be
   (approximately) equal to -0.5 and y should be (approximately) equal to -1.5.
 *)

open Basics

let hybrid f () = (x,y) where
  rec der x = 1.0 init -1.0 reset nxy(nx, _) -> nx
  and der y = 1.0 init -2.0 reset nxy(_, ny) -> ny
  and present
      | up(last x) -> do emit nxy = (-1.0, -2.0) done

let hybrid main () = obs where
  rec (x,y) = f ()
  and obs = present (period 0.5(1.0)) -> (x =~= -0.5 && y =~= -1.5)
                   else true

