
open Fuelc_data
open Fuelc_common
open Library

let node oxygen_status (ego_in) = (o2_normal, ego_out, failed) where
  rec ego_out = ego_in
  and automaton
      | O2_warmup ->
          do
                o2_normal = false
            and failed = false
          until (after (479, true)) then O2_running
          done

      | O2_running ->
          do
                o2_normal = true
            and automaton
                | Norm -> do failed = false unless (ego_in > max) then Fail done
                | Fail -> do failed = true  unless (ego_in < max) then Norm done
                end
          done
      end

let node pressure_status (speed, throttle, map) = (map', failed) where
  rec automaton
  | Norm ->
      do
            failed = false
        and map' = map
      unless (map < min_press || map > max_press) then Fail
      done

  | Fail ->
      do
            failed = true
        and map' = lookup (speed_bps, throt_bps, press_est, (speed, throttle))
      unless (min_press < map && map < max_press) then Norm
      done
  end

let node throttle_status (speed, map, throttle) = (throttle', failed) where
  rec automaton
  | Norm ->
      do
            failed = false
        and throttle' = throttle
      unless (throttle < min_throt || throttle > max_throt) then Fail
      done

  | Fail ->
      do
            failed = true
        and throttle' = lookup (speed_bps, press_bps, throt_est, (speed, map))
      unless (min_throt < throttle && throttle < max_throt) then Norm
      done
  end

let node speed_status (throttle, map, speed) = speed' where
  rec automaton
  | Norm ->
      do
            failed = false
        and speed' = speed
      unless (speed = 0.0 && map < float(zero_thresh)) then Fail
      done

  | Fail ->
      do
            failed = true
        and speed' = lookup (throt_bps, press_bps, speed_est, (throt, map))
      unless (speed > 0.0) then Norm
      done
  end

(* fueling mode *)

let node running (terminate_warmup, fail, o2_normal) = fuel_mode where
  rec automaton
  | Warmup -> do
        fuel_mode = Low
      unless (terminate_warmup || o2_normal) then Steady
      done

  | Steady -> do
        fuel_mode = if fail then Rich else Low
      done
  end

let node fueling_mode (fail, multifail, o2_normal, speed_normal, speed) =
  fuel_mode where
  rec automaton
  | Init -> do fuel_mode = Low then Running(false) done

  | Running(force_start) ->
      do
        fuel_mode = running (force_start, fail, o2_normal)
      unless (redge (multifail)) then Fuel_disabled(true)
           | (speed > float(max_speed)) then Fuel_disabled(false)
      done

  | Fuel_disabled(shutdown) ->
      let underspeed =
        not shutdown && speed_normal && speed < float (max_speed - hys)
      in do
        fuel_mode = Disabled 
      until (underspeed && not multifail) continue Running(false)
          | (underspeed) then Fuel_disabled(true)
      unless (shutdown && fedge(multifail)) continue Running(true)
      done
  end

(* put it all together *)

let fcount b = if b then 1 else 0

let node control_logic
     {throttle=throttle; speed=speed; pressure=press; ego=ego}
  = ({throttle=throttle'; speed=speed'; pressure=press'; ego=ego'},
     o2_normal, fuel_mode)
  where
  rec (o2_normal, ego', fail_oxygen)  = oxygen_status (ego)
  and (press',         fail_press)    = pressure_status (speed, throttle, press)
  and (throttle',      fail_throttle) = throttle_status (speed, press, throttle)
  and (speed',         fail_speed)    = speed_status (throttle, press, speed)
  and num_failures =   fcount fail_oxygen
                     + fcount fail_press
                     + fcount fail_throttle
                     + fcount fail_speed
  and fail      = num_failures > 0
  and multifail = num_failures > 1
  and fuel_mode =
    fueling_mode (fail, multifail, o2_normal, not fail_speed, speed)

