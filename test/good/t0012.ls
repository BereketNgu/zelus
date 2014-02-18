let node f(x,z) = y where
  rec y,k =
    present
    | z -> (1,2)
    | z -> (3,4)
    | z -> (4,0)
    init x,44

let hybrid sampler1 (i, t) = x where
  x = present (up(3.0)) -> 2.0 init 1.0

let hybrid timer v = z where
  rec der c = 1.0 init -. v reset z -> -. v
  and z = up(last c)

let hybrid sampler (i, t) = x where
  x = present (timer t) -> i init i

let hybrid ramp m = y where
  der y = m init 0.0

let hybrid main () =
  let r = ramp 1.0 in
  let z = sampler (r, 5.0) +. sampler (r, 3.0) in
  ()
