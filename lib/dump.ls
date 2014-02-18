open Basics

let piecewise  = ()
let linear     = ()
let points x = ()

let node scope (yl, yu, (n1, t1, v1)) =
  let init names = singleton n1 in
  (names, singleton v1)
  
let node scope2 (yl, yu, (n1, t1, v1), (n2, t2, v2)) =
  let init names = cons (n1, singleton n2) in
  (names, cons (v1, singleton v2))

let node scope3 (yl, yu,
                 (n1, t1, v1), (n2, t2, v2), (n3, t3, v3)) =
  let init names = cons (n1, cons (n2, singleton n3)) in
  (names, cons (v1, cons (v2, singleton v3)))

let node scope4 (yl, yu,
                 (n1, t1, v1), (n2, t2, v2), (n3, t3, v3), (n4, t4, v4)) =
  let init names = cons (n1, cons (n2, cons (n3, singleton n4))) in
  (names, cons (v1, cons (v2, cons (v3, singleton v4))))

let node window (title, imaxt, t, (n1, v1)) =
  output_floats (f, cons (t, v1))
  where rec 
      automaton
      | I -> 
          do f = open_out (title ^ ".out")
          and () = output_quoted_strings (f, cons ("t", n1))
          until true then S
      | S -> do done
      end

let node window2 (title, imaxt, t, (n1, v1), (n2, v2)) =
  output_floats (f, cons (t, append (v1, v2)))
  where rec 
      automaton
      | I -> 
          do f = open_out (title ^ ".out")
          and () = output_quoted_strings (f, cons ("t", append (n1, n2)))
          until true then S
      | S -> do done
      end

let node window3 (title, imaxt, t, (n1, v1), (n2, v2), (n3, v3)) =
  output_floats (f, cons (t, append (v1, append (v2, v3))))
  where rec 
      automaton
      | I -> 
          do f = open_out (title ^ ".out")
          and () = output_quoted_strings
              (f, cons ("t", append (n1, append (n2, n3))))
          until true then S
      | S -> do done
      end

let node window4 (title, imaxt, t, (n1, v1), (n2, v2), (n3, v3), (n4, v4)) =
  output_floats (f, cons (t, append (v1, append (v2, append (v3, v4)))))
  where rec 
      automaton
      | I -> 
          do f = open_out (title ^ ".out")
          and () = output_quoted_strings
              (f, append (n1, append (n2, cons ("t", append (n3, n4)))))
          until true then S
      | S -> do done
      end

let node window5 (title, imaxt, t,
                  (n1, v1), (n2, v2), (n3, v3), (n4, v4), (n5, v5)) =
  output_floats (f, cons (t, append (v1, append (v2,
                               append (v3, append (v4, v5))))))
  where rec 
      automaton
      | I -> 
          do f = open_out (title ^ ".out")
          and () = output_quoted_strings
              (f, cons ("t", append (n1, append (n2,
                                                 append (n3, append (n4, n5))))))
          until true then S
      | S -> do done
      end

