(** The same as the bouncing ball, this time with a mean *)
(* to avoid crossing the ground *)

(* [ground x] returns the position in [y] *)
let ground x = World.ground(x)
let ground_abs x = World.ground_abs(x)

let x_0 = 0.0
let y_0 = 5.6
let x_v = 0.8
let eps = 0.01

(* The bouncing ball with two modes. *)
let hybrid ball(x_0, y_0) = (x, y) where
  rec init y_start = y_0 
  and der x = x_v init x_0
  and
  automaton
  | Bouncing ->
      (* the ball is falling with a possible bound. *)
      local z, y_v in
      do
        (y, y_v, z) = Ball.ball(x, y_start)
      until z on (y_v < eps) then Sliding(ground(x))
  | Sliding(y0) ->
      (* the ball is fixed, i.e., the derivative for y is 0 *)
      do 
        y = y0 
      until up(x -. ground_abs x)
        (* up(y -. eps -. ground(x)) *)
      then do next y_start = 0.0 in Bouncing
  end
  
(* Main entry point *)
let hybrid main () =
  let (x, y) = ball(x_0, y_0) in
  present (period (0.04)) -> Showball.show(x fby x, y fby y, x, y);
  ()

