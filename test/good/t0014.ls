let hybrid main () =
  let rec
      der time = 1.0 init 0.0
  and
      automaton
      | Init -> do der x = 1.0 until (up(time -. 1.0)) then Two
      | Two -> do der x = time
               until (up(time -. 2.0)) then Init
      end in
  ()

