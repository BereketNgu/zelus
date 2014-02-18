(*********************************
The "Clutch Engagement Model" Simulink example
n.3 in simulink-stateflow-automotive.pdf
**********************************)

open Basics

(* Physical constants *)
let i_e = 1.0   (* inertia, engine-side      *)
let i_v = 5.0   (* inertia, wheel-side       *)
let b_e = 2.0   (* damping rate, engine-side *)
let b_v = 1.0   (* damping rate, wheel-side  *)
let mu_k = 1.0  (* kinetik coef. of friction *)
let mu_s = 1.5  (* static coef. of friction  *)
let r = 1.0     (* equivalent net radius     *)

(* The sign function with an hysteresis *)
let hybrid sgn(x) = o where
  rec init o = if x >= 0.0 then 1.0 else -1.0
  and z1 = up(x -. 0.01)
  and z2 = up(-. x -. 0.01)
  and automaton
      | Up -> do until z1 then do o = 1.0 in Down 
                  else z2 then do o = -1.0 in Up
      | Down -> do until z2 then do o = -1.0 in Up
      
let friction_model f_n = t_fmaxs, t_fmaxk where
  rec t_fmaxk = (2.0 /. 3.0) *. r *. mu_k *. f_n
  and t_fmaxs = t_fmaxk *. (mu_s /. mu_k)

(* The clutch *)
(* [f_n]: force between the two plates *)
(* [t_in]: torque on the motor-side axis *)
(* [w_e]: ang. speed of the motor-side axis *)
(* [w_v]: ang. speed of the wheel-side axis *)
(* [w]:   ang. speed of the shaft *)
(* [t_fmaxk]: Torque capacity of the clutch, when slipping *)
(* [t_fmaxs]: Torque capacity of the clutch, when static *)
(* [t_f]: torque transmitted by the clutch when locked *)
(* [t_c1]: Torque transmitted through the clutch *)
let hybrid clutch (f_n, t_in) = t_fmaxs, t_fmaxk, w_e, w_v, w where
  rec init w_v = 0.0
  and init w_e = 0.0
  and init w = 0.0
  and t_fmaxs, t_fmaxk = friction_model(f_n)
  and automaton 
      | Slipping ->
          local s_torque in do
                s_torque = abs_float ((t_in -. w_e *. (b_e +. b_v)) *. i_v /. (i_v +. i_e)
                                      +. b_v *. w_e)

            and der w_e = ( t_in -. b_e *. w_e -. t_c1) /. i_e
            and der w_v = ( t_c1 -. b_v *. w_v) /. i_v

            and t_c1 = sgn(w_e -. w_v) *. t_fmaxk

          until up(t_fmaxs -. s_torque) on (w_e =~= w_v) then do w = w_e in Locked
           else up(w_e -. w_v) on (s_torque < t_fmaxs) then do w = w_e in Locked
           else up(w_v -. w_e) on (s_torque < t_fmaxs) then do w = w_e in Locked

      | Locked ->
          local l_torque in do
                l_torque = abs_float((i_v *. t_in -. (i_v *. b_e -. i_e *. b_v) *. w)
                                     /. (i_v +. i_e))
            and der w = (t_in -. b_e *. w -. b_v *. w) /. (i_v +. i_e)
          until up(l_torque -. t_fmaxs) then do w_e = w and w_v = w in Slipping

let hybrid simulation () =
  let
  rec der t = 1.0 init 0.0

  (* The inputs *)
  and automaton
  | High    -> do t_in = 2.0
               until (period (5.0)) then Falling

  | Falling -> do t_in = 2.0 -. 2.0 *. (t -. 5.0)
               until (period (1.0)) then Low

  | Low     -> do t_in = 0.0 done

  and automaton
  | Rising  -> do f_n = 0.8 *. t
               until (period (2.0)) then Flat

  | Flat    -> do f_n = 1.6
               until (period (3.0)) then Falling

  | Falling -> do f_n = 1.6 -. 0.8 *. (t -. 5.0)
               until (period(2.0)) then Low

  | Low     -> do f_n = 0.0 done
 
  (* The Clutch *)
  and t_fmaxs, t_fmaxk, w_e, w_v, w = clutch(f_n,t_in)
  in (t, t_in, f_n, t_fmaxs, t_fmaxk, w_e, w_v, w)

