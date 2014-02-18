(** Bouncing ball. *)

(* [ground x] returns the position in [y] *)
let ground x = World.ground(x)
let ground_abs x = World.ground_abs(x)

let x_0 = 0.0
let y_0 = 9.0
let x_v = 0.8
let g = 9.81
let loose = 0.8

(* The bouncing ball *)
let hybrid ball(x, y_0) = (y, y_v, z) where
  rec
      der y = y_v init y_0
  and 
      der y_v = -. g init 0.0 reset z -> (-. loose *. last y_v)
  and z = up(ground(x) -. y)

  
(* Main entry point *)
let hybrid main () =
  let der x = x_v init x_0 in
  let (y, _, z) = ball(x, y_0) in
  let ok = present (period (0.04)) -> () | z -> () in
  present ok() -> Showball.show (x fby x, y fby y, x, y);
  ()

