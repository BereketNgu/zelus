(*
 * This example is taken from the paper:
 *   "Conflict Resolution in Air Traffic Management; A Study in Multiagent
 *    Hybrid Systems", Tomlin, Pappas, Sastry, 1998
 *)

(** constants, initial state **)

let pi = 4.0 *. atan 1.0

let d = 10.0                (* distance to deviate for avoidance, in miles *)
let delta_phi = (pi /. 4.0) (* change in heading for avoidance, radians *)

let radius_protected = 5.0  (* radius of the protected zone, in miles *)
let radius_alert = 25.0     (* radius of the alert zone, in miles *)

let alpha1 = 16.0           (* distance at which avoidance is triggered *)
let alpha2 = 20.0           (* distance at which avoidance is terminated *)

let aircraft1_v = 540.0     (* velocity of aircraft1, miles/hour *)
let aircraft2_v = 570.0     (* velocity of aircraft2, miles/hour *)

(* initial position of aircraft2, relative to aircraft1 *)
let aircraft2_xi = 60.0
let aircraft2_yi = 28.0
let aircraft2_thetai = -. 3.0 *. pi /. 4.0

(** algorithm **)

let rotate (theta, x, y) = (x', y') where
  rec cos_theta = cos(theta)
  and sin_theta = sin(theta)
  and x' = (cos_theta *. x) +. (-. sin_theta *. y)
  and y' = (sin_theta *. x) +. (cos_theta *. y)

let rotate_x (theta, x, y) = (cos(theta) *. x) +. (-. sin(theta) *. y)
let rotate_y (theta, x, y) = (sin(theta) *. x) +. (cos(theta) *. y)

let sqr x = x *. x

let hybrid integr(x', x0) = x where rec der x = x' init x0

let hybrid avoidance (x_i, y_i, theta_i, v_1, v_2) = (st, x, y, theta, t) where
  rec init theta = theta_i
  and der x = -. v_1 +. v_2 *. cos(theta) init x_i reset nxy(nx, _) -> nx
  and der y = v_2 *. sin(theta) init y_i reset nxy(_, ny) -> ny
  and der t = t' init 0.0
  and automaton
      | Cruise ->
          do
            t' = 0.0
            and st = 0
          until up(sqr(alpha1) -. sqr(last x) -. sqr(last y))
            then do emit nxy = rotate(-. delta_phi, last x, last y) in Left
      | Left ->
          local t1, t2 in
          do
            t1 = d /. (v_1 *. sin(delta_phi))
            and t2 = d /. (v_2 *. sin(delta_phi))
            and t' = 1.0
            and st = 1
          until up(t -. t1)
            then do emit nxy = rotate(delta_phi, last x, last y) in Straight
          else  up(t -. t2)
            then do emit nxy = rotate(delta_phi, last x, last y) in Straight
      | Straight -> 
          do
            t' = 0.0
            and st = 2
          until up(sqr(last x) +. sqr(last y) -. sqr(alpha2))
            then do emit nxy = rotate(delta_phi, last x, last y) in Right
      | Right -> 
          do
            t' = -. 1.0
            and st = 3
          until up(-. t)
            then do emit nxy = rotate(-. delta_phi, last x, last y) in Cruise

let hybrid noavoidance (x_i, y_i, theta_i, v_1, v_2) = (0, x, y, theta, t) where
  rec theta = theta_i
  and der x = -. v_1 +. v_2 *. cos(theta) init x_i
  and der y = v_2 *. sin(theta) init y_i
  and t = 0.0

(** Animation **)

open Airtrafficgui

let hybrid main () = () where
  rec p = period (0.001)

  and (click, (nxr, nyr), (ntheta_r, nd)) =
    present p -> sample ()
    init (false, (aircraft2_xi, aircraft2_yi), (aircraft2_thetai, 0.0))

  and automaton
      S1 -> do
        (st, xr, yr, theta_r, t) =
          avoidance (nxr, nyr, ntheta_r, aircraft1_v, aircraft2_v)
      until p on click then S1

  and _ = present p -> showupdate (d, delta_phi, radius_alert, radius_protected, 0.0,
                                   st, xr, yr, theta_r, aircraft1_v, aircraft2_v, t)

