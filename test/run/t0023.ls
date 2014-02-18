(* TEST[-check 20 -dzero] *)

(* Check that continuous states are correctly initialized when option
   dzero is used. If t < 1 (i.e. z < 2), then x and y should be equal
   to -1.

   Currently the program does not behave correctly : every up is
   activated at t=0 which causes x=1 and y=1. *)

let hybrid f () = (x,y,z) where
  rec der x = 0. init -1. reset 
    | up(z) -> 1.
  and der y = 0. init -1. reset 
    | up(x) -> 1.
  and der z = 1. init 1.

let hybrid main () = obs where
  rec (x,y,z) = f ()
  and obs = present (period(0.9)) -> (if (z < 2.) then (x = -1. && y = -1.) else true) 
                   else true
