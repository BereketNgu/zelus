open Graphics

let start =
  open_graph ""; auto_synchronize false; set_line_width 2

type pendulum =
    { x0: float;
      y0: float;
      x: float;
      y: float}

let make_pend (x0, y0, x, y) = { x0 = x0; y0 = y0; x = x; y = y }

let get_cursor () =
  let (cx,cy) = mouse_pos() in
  float cx /. 10.0, float cy /. 10.0

let node draw_pendulum1 (color, { x0 = x0; y0 = y0; x = x; y = y }) =
  let x0 = truncate (10.0 *. x0) in
  let x  = truncate (10.0 *. x)  in
  let y0 = truncate (10.0 *. y0) in
  let y  = truncate (10.0 *. y) in
  set_color color;
  moveto(x0, y0);
  lineto(x, y);
  draw_circle(x, y, 5)

(* p is the current pendulum and pp is the previous one *)
let node draw_pendulum (p, pp) =
  draw_pendulum1(background, pp);
  draw_pendulum1(foreground, p);
  synchronize()
