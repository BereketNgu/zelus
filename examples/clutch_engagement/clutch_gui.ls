open Scope

let hybrid main () =
  let (t, t_in, f_n, t_fmaxs, t_fmaxk, w_e, w_v, w) = Clutch_model.simulation () in

(* Plotting in/outputs *)
  present (period(0.2)) ->
    let inputs  = scope3(0.0, 2.0, ("Tin",     linear, t_in),
                                   ("Tfmaxs",  linear, t_fmaxs),
                                   ("Tfmaxk",  linear, t_fmaxk)) in
    let outputs = scope3(0.0, 0.8, ("Engine",  linear, w_e),
                                   ("Vehicle", linear, w_v),
                                   ("Shaft",   linear, w)) in

    window2 ("Clutch model", 10.0, t, inputs, outputs)
  else ()

