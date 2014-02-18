
let hybrid legsegment ((min, max, i), rate, (extend, retract, stop)) =
  ((segin, segout), pos) where

  rec init pos = i
  and init segin  = pos <= min
  and init segout = pos >= max

  and automaton
    | Stationary ->
        do
          der pos = 0.0
        until extend() on (not segout)
          then do next segin = false in Extending
        else  retract() on (not segin)
          then do next segout = false in Retracting

    | Extending ->
        do
          der pos = rate
        until up(pos -. max)
          then do next segout = true in Stationary
        else  stop()         then Stationary
        else  retract()      then Retracting

    | Retracting ->
        do
          der pos = -. rate
        until up(min -. pos) then do next segin = true in Stationary
        else  stop()         then Stationary
        else  extend()       then Extending

