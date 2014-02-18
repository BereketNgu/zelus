
let hybrid sticky z = () where
  rec der x1 = v1 init 0.0 reset join(v) -> v
  and der x2 = v2 init 0.0 reset join(v) -> v 
  and init v1 = 0.0
  and init v2 = 0.0
  and automaton
      | S0 ->
          do v1 = x1
          (*and der v2 = x2 *)
          until z then do emit join = last x1 in S0

