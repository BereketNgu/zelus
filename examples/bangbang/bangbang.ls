(*
  Version of the Mathworks Simulink example:
      Bang-Bang Control Using Temporal Logic
 *)

(* ** library functions ** *)
let hybrid integrator (i, u) = y where
  der y = u init i

let node round x = floor (x +. 0.5)

(* ** model of analog-to-digital convertor ** *)

let node quantize (q, u) = q *. round(u /. q)

(* limiting without zero-crossings *)
let node limit (min, max, x) =
  if x >= max then max
  else if x <= min then min
  else x

let node adc (v) = pcm where
  rec vs = v *. (256.0 /. 5.0)
  and pcm = quantize (1.0, limit (0.0, 255.0, vs))

(* ** model of digital thermometer ** *)

let node digital_thermometer (temp) = int_of_float(adv) where
  rec voltage = 0.05 *. temp +. 0.75
  and adv = adc (voltage)

(* signed fixed-point int from scale and bias *)
let discrete fixdt (s, b, v) = int_of_float ((v -. b) /. s)

(* ** model of boiler plant with an exponential ** *)
let hybrid boiler_exponential(k1, k2, is_on) = actual_temp where
  rec der actual_temp = 
           (* two modes. [is_on] is a boolean and will only change *)
           (* at a zero-crossing instant. *)
           if is_on then k1 -. k2 *. actual_temp
           else -. k2 *. actual_temp
         init 15.0

(* the one below is the Simulink version with an approximation by a *)
(* linear function *)
let hybrid boiler(is_on) = actual_temp where
  rec der actual_temp = 
           (* two modes. [is_on] is a boolean and will only change *)
           (* at a zero-crossing instant. *)
           (if is_on then 1.0 else -0.1) /. 25.0
         init 15.0

(* ** Bang-Bang Controller ** *)

let off   = 0
let red   = 1
let green = 2

let b_off  = false
let b_on   = true

let node after (x) =
  let rec c = x fby max (0, c - 1) in
  c = 0

let node at (x) =
  let rec c = 0 fby ((c + 1) mod x) in
  false -> (c = 0)

let node flash_led (color, delay) = led where
  automaton
  | Off -> do led = off   until (after delay) then On
  | On  -> do led = color until (after delay) then Off

let node controller (ref, temp) = (led, boiler) where
  rec cold = temp <= ref
  and automaton
  | Off ->
      do boiler = b_off
      and led = flash_led (red, 5)
      until (after 40) & cold then On
  | On ->
      do boiler = b_on
      and led = flash_led (green, 1)
      until (not cold) then Off
      else  (at 20) then Off

(* ** main ** *)

let reference = fixdt (5.0 /. 256.0 /. 0.05, -. 0.75 /. 0.05, 20.0)

let hybrid model () = (led, on_off, actual_temp) where
  rec trigger = period (1.0)

  and (led, on_off) = 
           present trigger -> controller(reference, last digital_temp) 
      init (red, false)
  and actual_temp = boiler(on_off)
  and digital_temp = 
         present trigger -> digital_thermometer (actual_temp)
      init 0

open Scope (* Dump *)
let sample_period = 1.0

let node bool_to_float(x) = if x then 1.0 else 0.0

let node plot (led, boiler, temp) =
  let s1 =
    scope (0.0, 2.0, ("led (0=OFF, 1=RED, 2=GREEN)", points true, float(led))) in
  let s2 =
    scope (0.0, 1.0, ("boiler (0=OFF, 1=ON)", points true, bool_to_float(boiler))) in
  let s3 =
    scope (11.0, 25.0, ("temperature (degC)", linear, temp)) in
  let rec t = 0.0 fby t +. sample_period in
  window3 ("bangbang", 600.0, t, s1, s2, s3)

let hybrid main () =
  let (led, on_off, actual_temp) = model () in
  let trigger = period (0.5) in
  present trigger -> plot (led, on_off, actual_temp) else ()

