let node f (i,r) = (o) where
  rec init m = 0
  and automaton
      | A ->
          do
          until i then B
      | B ->
          do
          until i then
	    do m = last m + 1 in A
          unless r then
	    do emit o = last m in A
      end
