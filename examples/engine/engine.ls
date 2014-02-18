(*********************************
The "Engine Model" Simulink example
n.1 in simulink-stateflow-automotive.pdf
**********************************)

let hybrid timer v = t where
  rec der c = 1.0 init -.v reset t -> -.v
  and t = up(last c)

let abs x = if (x<0.0) then -.x else x

let limit_to_positive x = if x>0.0 then x else 0.0

(*THROTTLE MANIFOLD *)
let f(u) = r where r = 2.821 -. 0.05231*.u +. 0.10299*.u*.u -. 0.00063*.u*.u*.u

let throttle (angle, manifold_pressure, atm_pressure) =
  let g = if (manifold_pressure <= (atm_pressure /. 2.0)) then 1.0
          else if
	    ((atm_pressure /. 2.0) <=  manifold_pressure 
	       & manifold_pressure <= atm_pressure)
          then (2.0 *. sqrt(manifold_pressure*.atm_pressure 
			      -. manifold_pressure*.manifold_pressure))/.atm_pressure
          else if ( atm_pressure <= manifold_pressure 
		      & manifold_pressure <= (2.0 *. atm_pressure) )
          then (-2.0 *. sqrt(manifold_pressure*.atm_pressure 
			       -. atm_pressure*.atm_pressure))/.manifold_pressure
          else if ( manifold_pressure >= 2.0 *. atm_pressure ) then -1.0
          else -1.0
          in
  let direction = 1.0 
     (* if (atm_pressure >= manifold_pressure) then -1.0 else 1.0*) in
  let throttle_flow = f(angle) *. g *. direction in
  throttle_flow
    
let hybrid intake_manifold ( mdot_in, n ) =
  let rec pm' = 0.41328 *. ( mdot_in -. mdot_out ) 
  and der pm = pm' init 0.0
  and  mdot_out = 
    -.0.366  +. 0.08979 *. n *. pm -. 0.0337 *. n 
      *. pm *. pm +. 0.0001 *. n *. n *. pm 
  in (mdot_out, pm')

let hybrid throttle_manifold ( throttle_angle , engine_speed ) = 
  let atm_press = 1.0 in (*  à externaliser ? *)
  let rec mass_airflow_rate , manifold_pressure' = 
    intake_manifold (mdot_input , engine_speed )
  and der manifold_pressure = manifold_pressure' init 0.543
  and mdot_input = 
    throttle (limit_to_positive(throttle_angle), manifold_pressure,atm_press )
  in mass_airflow_rate
    

(*COMPRESSION*)
(*
let hybrid valve_timing ( n ) =
  let rec automaton
            Demitour -> do der theta = n init 0.0 reset 0.0 every demitour
                        until demitour then Demitour
          done
  end
  and demitour = up(abs(theta)-.180.0)
  in (demitour,theta)
*)

let hybrid valve_timing ( n ) =
  let rec der theta = n init 0.0 reset demitour -> 0.0
  and demitour = up(abs(last theta)-.180.0) in
  (demitour,theta)

(*
let hybrid intake (trigger,mass_airflow_rate) = mass_total, mass_current where
  rec automaton
      | Increasing -> do der mass_current = mass_airflow_rate init 0.0 until trigger then Mem done
      | Mem -> do der mass_total = 0.0 init mass_current until (init on true) then Reset done
      | Reset -> do mass_current = 0.0 until (init on true) then Increasing done
  end
*)
 
let hybrid intake (trigger,mass_airflow_rate) = mass_total, mass_current where
  rec init mass_total = 0.0
  and automaton
      | Increasing -> 
           do der mass_current = mass_airflow_rate init 0.0 
           until trigger then do mass_total = mass_current in Increasing done

(*COMBUSTION*)
let hybrid combustion ( n , air_charge ) = torque_engine where
  rec r = 14.7 (*air/fuel ratio *)
  and s = 30.0 (* ? *)
  and ma = air_charge
  and torque_engine = -.181.3 +. 379.36*.ma +. 21.91*.r -. 0.85*.r*.r +. 0.26*.s -. 0.0028*.s*.s +. 0.027*.n -. 0.000107*.n*.n +. 0.00048*.n*.s +. 2.55*.s*.ma -. 0.05*.s*.s*.ma

(*Vehicle Dynamics*)
let hybrid vehicle_dynamics ( torque_engine , torque_load ) = n' where
  rec j = 1000.0
  and n' = (torque_engine -. torque_load) /. j
  


let hybrid main () =
  let der t = 1.0 init 0.0 in
  
  (*inputs*)
  let torque_load = present (period(10.0)) -> 20.0 init 25.0 in
  let throttle = present (period(5.0)) -> 11.93 init 8.97 in

  let rec mass_airflow_rate = throttle_manifold (throttle,n)
  and (demitour,theta) = valve_timing(n)
  and (masse_t,masse_c) = intake(demitour,mass_airflow_rate)
  and torque_engine = combustion (n,masse_t)
  and der n = vehicle_dynamics (torque_engine,torque_load) init 2000.0
  in


  (*boucle ouverte *)
  (*let n_static = 10.0 in
  let rec mass_airflow_rate = throttle_manifold ( throttle , n_static)
  and (masse_c,masse_t) = intake(valve_timing(n_static),mass_airflow_rate)
  and torque_engine = combustion (n_static,masse_t)
  and der n = vehicle_dynamics ( torque_engine , torque_load )*)

  present (period(0.1)) ->
    let s = Scope.scope3 (-.300.0, 3000.0, ("N : speed", Scope.linear, n),("Mass_airflow_rate", Scope.linear, mass_airflow_rate),("Theta", Scope.linear, theta)) in
    let sn = Scope.scope (-.300.0, 3000.0, ("N : speed", Scope.linear, n)) in
    let s2 = Scope.scope3 (-.100.0, 100.0, ("masse_t", Scope.linear, masse_t),("masse_c", Scope.linear, masse_c),("torque_engine", Scope.linear, torque_engine)) in
    let st = Scope.scope2 (-.100.0, 100.0, ("command:Throttle", Scope.linear,throttle),("command:Torque load", Scope.linear,torque_load)) in
    Scope.window2 ("engine", 100.0, t, sn,s2)
  else ()
