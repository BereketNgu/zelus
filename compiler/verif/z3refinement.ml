(* Z3 interface to type check refinement types*)

(*Open Z3 interface*)
open Z3
open Z3.Symbol
open Z3.Sort
open Z3.Expr
open Z3.Boolean
open Z3.FuncDecl
open Z3.Goal
open Z3.Tactic
open Z3.Tactic.ApplyResult
open Z3.Probe
open Z3.Solver
open Z3.Arithmetic
open Z3.Arithmetic.Integer
open Z3.Arithmetic.Real
open Z3.BitVector

exception Z3FailedException of string

(*Open Zelus Interface*)
open Zident
open Global
open Modules
open Deftypes
open Ztypes
open Typerrors

open Zmisc
open Zlocation
open Format
open Zelus

open List
open Hashtbl


(*
type variable = 
  { 
    name:         string;
    refinement_t: expr;
  }
*)

(*TODO :Change this to a Z3 expression type, then add stuff by AND-ing it on the head *)
(*let z3env = ref []*)

type env_structure =
(*
      environment to hold
      exp_env : local expression environment
      var_env : local variable environment
*)
{
  exp_env : expr list ref;
  var_env : (string, expr) Hashtbl.t;
}

let add_constraint ({ exp_env = env; var_env = v}) premise = 
(*
    env     -> environment (list of z3 expressions)
    premise -> z3 expression
    
    Add premise to end of environment list
*)
   env := premise::(!env) 

(*
type z3env =
{
  scope: variable list;
  prev:  z3env;
}*)

type function_desc = 
(*
    Function object definition
*)
{
  argument_constraints: expr list;
  variable_maps: (string, string) Hashtbl.t;
  argument_list: string list;
  creation_env: env_structure;
}

(*TODO: make two variants for refinement functions and non-refinement functions *)
let function_space =
(*Hash table to store functions given a function name*)
    let function_table : ((string, function_desc ) Hashtbl.t) =  (Hashtbl.create 1)
    in ref function_table

let add_function name f_add =
(*
    name  -> fucntion name
    f_add -> function_desc object

    Adds a  new function to function space
*)
  Hashtbl.add (!function_space) name f_add 

type stream_desc =
(*
    Stream object definitions
*)
{
  initialization_var:   expr;
  application_function: string;
  return_exp : expr;
  refinement_exp : expr list;
}
let stream_space =
(* Hash table to store streams given a stream name*)
  let stream_table : ((string, stream_desc) Hashtbl.t) = (Hashtbl.create 1)
in ref stream_table

let add_stream name stream_add =
(*
    name -> stream name
    stream_add -> stream desc object

    Add a new stream to stream space
*)
  Hashtbl.add (!stream_space) name stream_add

(**
(*Define refinement type pattern*)
type z3op =
    | Z3eval of string * string * exp * exp
    
type z3exp =
    | Z3int of int
    | Z3real of float

(* convert immeiate type to respective string *)
let immediate = function
  | Ebool(b) -> if b then "true" else "false" 
  | Eint(i) -> Printf.sprintf "%d" i
  | Efloat(i) -> Printf.sprintf "%f" i
  | Echar(c) -> Printf.sprintf "'%c'" c
  | Estring(c) -> Printf.sprintf "'%s'" c
  | Evoid -> Printf.sprintf ""
  
let qualident { Lident.qual = m; Lident.id = s } =
  Printf.sprintf "%s.%s" m s
 
let print_elt f e = 
	print_string (Printf.sprintf "List exp: '%s'\n" (f e)) 
	
let type_exp typ = 
	match typ with
	  | Vconst(i) -> immediate i (* constant *)
	  | Vconstr0(ln) -> qualident ln (* constructor *)
	  | Vabstract(ln) -> qualident ln (* no implementation is given *)

let qualid_exp typ = 
	match typ with
	  | None  -> "None" (* constant *)
	  | Some(ln) -> qualident ln (* constructor *)
  
let print_info info =
	(*print_string (Printf.sprintf "Value typ: '%s' \n" (List.hd (info.value_typ.typ_vars)));*)
	print_string (Printf.sprintf "Value static: '%b' \n" (info.value_static));
	(*print_string (Printf.sprintf "Value caus: '%s' \n" info.value_caus);
	print_string ("Value init: \n");
	print_string (String.concat " " (List.map (Printf.sprintf "'%s'") info.value_init));*)
	print_string (Printf.sprintf "Value code exp: '%s' \n"  ( type_exp info.value_code.value_exp));
	print_string (Printf.sprintf "Value code name: '%s' \n" ( qualid_exp info.value_code.value_name)); "Info"
	
(* parse input expression into string and redirect to Z3 solver *)
let rec parse_expression e = 
  match e.e_desc with
    | Elocal n -> print_string "Elocal\n"; "1.0"
    | Eglobal { lname = ln } -> print_string "Eglobal\n"; let var_name = Lident.modname ln in print_string var_name; print_newline(); 
    let var2 =
    	try 
    	   let { info = info } = Modules.find_value ln in print_info info
    	with 
    	   | Not_found -> "No info" in
    var_name
    | Eop(op, e_list) -> print_string "Eop\n"; "1.0"
    | Elast x -> print_string "Elast\n"; "1.0"
    | Econstr0(ln) -> print_string "Econstr0\n"; "1.0"
    | Econst c -> print_string "Econst\n"; immediate c
    | Eapp({ app_inline = i; app_statefull = r }, e, e_list) ->
       print_string (Printf.sprintf "App inline: '%b'\n" i);
       print_string (Printf.sprintf "App stateful: '%b'\n" r);
       (*print_string (Printf.sprintf "Exp parsing: '%s' \n" (parse_expression e));
       print_string "Map start\n";
       let dummy = List.map (print_elt parse_expression) e_list in
       print_string "Eapp\n"; "1.0"*)
       let operator = Printf.sprintf "'%s'" (parse_expression e) in
       let exp_list = List.map parse_expression e_list in
       List.hd (List.tl exp_list)
    | Econstr1(ln, e_list) ->
        print_string "Econstr1\n"; "1.0"
    | Etuple(e_list) ->
        print_string "Etuple\n"; "1.0"
    | Erecord_access(e, field) ->
        print_string "Erecord_access\n"; "1.0"
    | Erecord(ln_e_list) ->
        print_string "Erecord\n"; "1.0"
    | Erecord_with(e, ln_e_list) ->
       print_string "Erecord_with\n"; "1.0"
    | Elet(l, e) ->
        print_string "Elet\n"; "1.0"
    | Eblock(b, e) ->
       print_string "Eblock\n"; "1.0"
    | Etypeconstraint(e, typ) ->
        print_string "Etypeconstraint\n"; "1.0"
    | Eseq(e1, e2) ->
        print_string "Eseq\n"; "1.0"
    | Eperiod(p) ->
        print_string "Eperiod\n"; "1.0"
    | Ematch(total, e, match_handler_list) ->
        print_string "Ematch\n"; "1.0"
    | Epresent(present_handler_list, opt_e) ->
        print_string "Epresent\n"; "1.0" 
     

let evaluate name ty e1 e2 : bool =
	Printf.printf "Running Zelus evaluation verifier \n";
	let cfg = [("model", "true"); ("proof", "false")] in
	let ctx = (mk_context cfg) in
	let var = Real.mk_numeral_s ctx e2 in
	let threshold = Real.mk_numeral_s ctx e1 in
	let phi variable refinement =
		Arithmetic.mk_ge ctx variable refinement in
	let correct = (Boolean.mk_and ctx
			[(phi var threshold);]) in
	let solver = (mk_solver ctx None) in
	let s = (Solver.add solver [correct]) in
	let q = check solver [] in
	Printf.printf "Solver says: %s\n" (string_of_status q) ;
    	if q == SATISFIABLE then true
    	else 
	     raise (Z3FailedException "Z3 verification failed")
	     
let rec prove_satisfiability op : bool =
	match op with
	| Z3eval(var, ty, e1, e2) -> 
	let arg = parse_expression e1 in
	let arg2 = parse_expression e2 in
	print_string arg; print_newline(); print_string arg2; print_newline();
	evaluate var ty (arg) (arg2)
*)
exception TestFailedException of string
let print_assignments m = 
(*
    m -> z3 model

    Print counterexamples found for a given z3 model
*)
  let decls = (Model.get_decls m) in
    List.iter (fun a -> (match (Model.get_const_interp m a) with
      | Some(e) -> Printf.printf "\t%s: %s\n" (Symbol.get_string (FuncDecl.get_name a)) 
          (if (Arithmetic.is_real e) then (Arithmetic.Real.to_decimal_string e 5) else (Expr.to_string e))
      | None -> ()
    )) decls

let build_z3_premise ctx ({exp_env = l; var_env = v}) =
(*
    ctx -> z3 context
    l   -> list of z3 expressions

    Returns the conjunctions of z3 expressions in list l
*)
  match !l with
  | [] -> Boolean.mk_true ctx
  | _ -> Boolean.mk_and ctx !l

(* let check_arg_list f arg_list =
(*
  Check that input arguments agree with function definition
*)
  if List.len (f.argument_list) != List.len (arg_list) then
    Printf.printf "Function expected different number of arguments";
    raise Z3FailedException
  else 
    let rec validate_args l1 l2 = *)

let print_env_list premise =
(*
  premise -> list of z3 expressions
    
  Print list of z3 expressions
*)
  (Printf.printf "Expression = %s ; " (Expr.to_string premise))

let print_env ({exp_env = env; var_env = v}) = 
(*
  env -> expression environment
  v   -> variable environment
*)
  Printf.printf ("Expression environment : \n");
  List.iter print_env_list !env; print_newline ()

let print_function_temp n f =
(*
  temporary function used for debugging, I will delete it later

  same thing as print_function but it is defined earlier
*)
      Printf.printf "Function: %s\n" n;
      Printf.printf "Argument_constraints:\n";
      List.iter (fun a -> (Printf.printf "%s; " (Expr.to_string a))) f.argument_constraints;
      Printf.printf "\n";
      Printf.printf "Variable map:\n";
      Hashtbl.iter (fun a b -> (Printf.printf "%s:%s; " a b)) f.variable_maps;
      Printf.printf "\n";
      Printf.printf "Argument list:\n";
      List.iter (fun a -> (Printf.printf "%s; " a)) f.argument_list;
      Printf.printf "Creation environment\n";
      print_env f.creation_env
    

let z3_solve ctx env constraints = 
(*
  ctx         -> z3 context
  env         -> environment (list of z3 expression)
  constraints -> z3 constraints to solve

  Attempts to prove that ! ( environement expreession -> constraints)

  Raises an exception if proof fails or resumes the operations
*)
  Printf.printf "\n--- Z3 SOLVE ---\n";
  Printf.printf "environment:\n";
  print_env !env; 
  Printf.printf "constraint:\n";
  Printf.printf "%s\n" (Expr.to_string constraints);
  Printf.printf "--- Z3 SOLVE ---\n\n";
  let solver = (mk_solver ctx None) in
  let c = Boolean.mk_not ctx (Boolean.mk_implies ctx 
                                    (build_z3_premise ctx !env)
                                    (constraints)) in
  Printf.printf "Constraint built: %s\n" (Expr.to_string c);
  let s = (Solver.add solver [c]) in
  let q = check solver [] in
  (if q == SATISFIABLE then
    (Printf.printf "Counterexample found:\n";
    (let m = (get_model solver) in    
      		match m with 
          | None -> ()
		      | Some (m) -> 
	  	      (*Printf.printf "Model: \n%s\n" (Model.to_string m);*)
            print_assignments m;
      Printf.printf "Could not prove %s\n" (Expr.to_string constraints);
      raise (TestFailedException "")))
  else
    (Printf.printf "Passed\n"));
    add_constraint !env constraints

let create_z3_var_typed ctx ({exp_env = e ; var_env = v}) s basetype : expr =
(*
    ctx -> z3 context
    s   -> variable name

    Create z3 sort with specific basetype with given variable name s
*)
  Printf.printf "\n --- CREATE Z3 VAR TYPED : %s --- \n" s;
  (* Look at environment for variable*)
  if (Hashtbl.mem v s) then
    (*if exists return varible*)
      let found_var = Hashtbl.find v s in
      Printf.printf "Existing variable, returning %s\n\n" (Expr.to_string found_var);
      found_var
  else
    (*otherwise create a new variable and add to environment*)
    let new_var =  
    (match basetype with
      | "int" -> Printf.printf " I will make an int here\n"; Expr.mk_const ctx (Symbol.mk_string ctx s) (Integer.mk_sort ctx)
      | "float" -> Printf.printf " I will make a float here\n"; Expr.mk_const ctx (Symbol.mk_string ctx s) (Real.mk_sort ctx)
      (* | "string" -> Printf.printf " I will make a string here\n"; (Expr.mk_const ctx (Symbol.mk_string ctx n.source) (.mk_sort ctx))
      | "char" -> Printf.printf " I will make a char here\n"; (Expr.mk_const ctx (Symbol.mk_string ctx n.source) (.mk_sort ctx))*)
      | "bool" -> Printf.printf " I will make a bool here\n"; (Expr.mk_const ctx (Symbol.mk_string ctx s) (Boolean.mk_sort ctx))
      | _ ->  Printf.printf " I don't know what to make here\n"; Integer.mk_numeral_s ctx "42"
    ) in
    Hashtbl.add v s new_var;
    Printf.printf "New variable, returning %s\n\n" (Expr.to_string new_var);
    new_var

let create_z3_var ctx ({exp_env = e ; var_env = v}) s =
  (*
      ctx -> z3 context
      s   -> variable name
  
      Create generic z3 Real sort with given variable name s
  *)
    create_z3_var_typed ctx ({exp_env = e ; var_env = v}) s "float"

let print_function n f =
(*
    n -> function name
    f -> function description

    Prints all fields in function data structure
*)
  Printf.printf "Function: %s\n" n;
  Printf.printf "Argument_constraints:\n";
  List.iter (fun a -> (Printf.printf "%s; " (Expr.to_string a))) f.argument_constraints;
  Printf.printf "\n";
  Printf.printf "Variable map:\n";
  Hashtbl.iter (fun a b -> (Printf.printf "%s:%s; " a b)) f.variable_maps;
  Printf.printf "\n";
  Printf.printf "Argument list:\n";
  List.iter (fun a -> (Printf.printf "%s; " a)) f.argument_list;
  Printf.printf "Creation environment\n";
  print_env f.creation_env

let print_function_environment () =
(*
  Prints all function description in function space
*)
    Hashtbl.iter ( fun n f -> print_function n f; Printf.printf "\n\n" ) (!function_space)

let immediate ctx i = 
(*
    ctx -> z3 context
    i   -> immediate type expression

    Converts immediate type expression into z3 sort

    Returns z3 sort
*)
  Printf.printf "\n --- CREATE Z3 VAR IMMEDIATE :  --- \n";
  (* Look at environment for variable*)
  match i with
      | Ebool(b) ->  Boolean.mk_val ctx b 
      | Eint(i) -> (Printf.printf "Z3 Int %d\n") i; Integer.mk_numeral_s ctx (Printf.sprintf "%d" i)
      (*TODO: in general reals and floating points are not the same*)
      | Efloat(i) -> (Printf.printf "Z3 Float %f\n") i; Real.mk_numeral_s ctx (Printf.sprintf "%f" i)
      | Estring(c) -> (Printf.printf "string: %s\n" c); Expr.mk_const ctx (Symbol.mk_string ctx c) (Real.mk_sort ctx)
      | Echar(c) -> Printf.printf "%c" c; Integer.mk_numeral_s ctx "42"
      | Evoid -> Printf.printf "void"; Integer.mk_numeral_s ctx "42"
      | _ -> (Printf.printf "Ignore immediate \n"); Integer.mk_numeral_s ctx "42"

(* let rec local ctx env typenv l =
   let expr = expression ctx env (List.hd l.l_eq) typenv in
   Printf.printf "%s\n" (Expr.to_string expr) *)

(* and local = 
  { l_rec: is_rec; (* is-it recursive *)
    l_eq: eq list; (* the set of parallel equations *)
    mutable l_env: Deftypes.tentry Zident.Env.t;
    l_loc: location } *)
let rec equation ctx env typenv eq =
(*
    ctx    -> z3 context
    env    -> environment (list of z3 expression)
    typenv -> typing environment ( Hash table of string = variable name * string = base type)
    eq     -> zelus equation

    Creates z3 expression from zelus equation

    Returns z3 expression
*)
    match eq.eq_desc with
    | EQeq(p, e) -> Printf.printf "EQeq:\n";
      let body_exp = expression ctx env e typenv in
      Printf.printf "body_exp: %s\n" (Expr.to_string body_exp);
      let pat_exp = 
       (match p.p_desc with 
       | Evarpat(n) -> Printf.printf "Evarpat: %s\n" n.source; create_z3_var ctx env n.source
       | _ -> Printf.printf "undefined"; create_z3_var ctx env "undefined") in
      Printf.printf "pat_exp: %s\n" (Expr.to_string pat_exp);
      let ret_exp = Boolean.mk_eq ctx pat_exp body_exp in
      Printf.printf "after ret_exp\n";
      Printf.printf "EQ Expression: %s\n" (Expr.to_string ret_exp);
      add_constraint env ret_exp
      (*ret_exp*)
    (* [p = e] *)
    (* | EQder(_, _, _, _) -> Printf.printf "EQder\n"
    (* [der n = e [init e0] [reset p1 -> e1 | ... | pn -> en]] *)
    | EQinit(_,_) -> Printf.printf "EQinit\n"
    (* [init n = e0 *)
    | EQnext(_,_,_) -> Printf.printf "EQnext\n"
    (* [next n = e] *)
    | EQpluseq(_,_) -> Printf.printf "EQpluseq\n"
    (* [n += e] *)
    | EQautomaton(_,_,_) -> Printf.printf "EQautomaton\n"
    (*added here
    | EQr_move of exp*)
    | EQpresent(_,_) -> Printf.printf "EQpresent\n"
    | EQmatch(_,_,_) -> Printf.printf "EQmatch\n"
    | EQreset(_,_) -> Printf.printf "EQreset\n"
    | EQemit(_,_) -> Printf.printf "EQemit\n"
    | EQblock(_) -> Printf.printf "EQblock\n"
    | EQand(_) -> Printf.printf "EQand\n" (* eq1 and ... and eqn *)
    | EQbefore(_) -> Printf.printf "EQbefore\n" (* eq1 before ... before eqn *)
    | EQforall(_) -> Printf.printf "EQforall\n" forall i in ... do ... initialize ... done *)
    | _ -> Printf.printf "Ignoring equation for now\n"

and create_validation_check ctx env elem1 elem2 = 
(*
    ctx -> z3 context
    constraints -> list of constraints to be satisfied by functions
    elem1 -> argument used as input in function call
    elem2 -> argument used during function definition

    return specified input contrained to funciton argument variable
*)
    Printf.printf "\n --- CHECK INPUT VALIDITY ---\n";
    let input_binding = Boolean.mk_eq ctx (expression ctx env elem1 None) elem2 in
    (* Printf.printf "%s" (Expr.to_string input_binding); *)
    input_binding

and check_validity ctx env checks =
(*
    ctx -> z3 context
    constraints -> list of constraints to be satisfied by functions
    elem1 -> argument used as input in function call
    elem2 -> argument used during function definition

    check if elem1 satisfies the conditions imposed by elem2
*)
    Printf.printf "\n --- CHECK INPUT VALIDITY ---\n";
    let arg_constraint = build_z3_premise ctx env in
    z3_solve ctx checks arg_constraint

and get_environment_constraints ctx local_env typenv arg =
(* 
  local_env -> environment 
  arg       -> expression argument used during funciton call

  Find constraints in the environment that are related to function input arguments
*)
  if (Hashtbl.mem local_env.var_env (Expr.to_string (expression ctx local_env arg typenv)) )
    then (
      Hashtbl.find local_env.var_env ( Expr.to_string (expression ctx local_env arg typenv))
    ) else (
      Boolean.mk_true ctx
    )

and prove_function ctx n local_env arg_list typenv =
(*  n        -> function name
    arg_list -> list containing expression arguments used during function call

    
    Use function space to determine if argument list has expected type
    from function space
*)
    (* if (Hashtbl.mem !stream_space n) then ()
    (* if it is a stream *)

    else ( *)(
      if (Hashtbl.mem !function_space n) 
        (* refinement function, make sure input list obeys constraints
            *)
        then (
          let ref_fun = Hashtbl.find !function_space n in
          Printf.printf "TODO -- check if arguments obey constraints\n";
          print_function_temp n ref_fun;
          print_env local_env;
          (* let expr_test = expression ctx local_env (List.hd arg_list) None in
          Printf.printf "Arg_list[0]: %s\n" (Expr.to_string expr_test); *)
          let constraint_env = ref { exp_env = ref ref_fun.argument_constraints ; var_env = ref_fun.creation_env.var_env } in 
          let arguments = List.map (fun elem -> create_z3_var ctx !constraint_env elem) ref_fun.argument_list in
          let checks = List.map2 (fun elem1 elem2 -> create_validation_check ctx !constraint_env elem1 elem2) arg_list arguments in
          (* let environment_constraints = List.map (get_environment_constraints ctx local_env typenv) arg_list in *)
          (* print_env ({ exp_env = ref( checks @ environment_constraints); var_env = Hashtbl.create 0}); *)
          let check_env = ref { exp_env = ref (checks @ !(local_env.exp_env)); var_env = Hashtbl.create 0} in
          check_validity ctx !constraint_env check_env;
        ) 
        (* not a refinement function, so assume it is true*)
        else (
          Printf.printf "Function %s not defined, assuming it is true\n" n;
          (* check if argument have other function calls*)
          ignore(List.iter (fun e_elem -> ignore(expression ctx local_env e_elem typenv)) arg_list);
        );
        (* dummy value since we don't need to handle non-refined expressions*)
        (* Figure out how to better ignore those expressions *)
      );
    Integer.mk_numeral_s ctx "42"


  (*let ref_fun = Hashtbl.find !function_space n in
  print_function_temp n ref_fun*)
  (* check argument against definition *)
  (* use z3 solve *) 

and prove_pair ctx env e_list tuple_type e typenv =
(*
    ctx      -> z3 context
    env      -> local scope environment
    e_list   -> list containing  tuple elements
    txp_list -> list containing tuple base types and binding variables  , i.e  x:int
    e        -> expression for tuple refinement type 
    typenv   -> local scope type environment

    Apply pair typing rule to tuple elements

    Gamma |- e1 : t1         Gamma |- e2 : [e1/x] t2
  ---------------------------------------------------- (DEPENDENT PAIR)
         Gamma |- (e1, e2) : Sigma(x : t1).t2

*)
  match e_list with
  (* | h :: t -> ( 
    (*
       h = 5
       t = (5 + 3, 5 + 4)

       (x = 5) && env

      x:int
    *)
    match (List.hd txp_list).desc with 
      | Erefinementpair(n, _ ) -> Printf.printf "Prove pair call - variable: %s\n" n; 
                                  e := Boolean.mk_and ctx [
                                          (Boolean.mk_eq ctx (create_z3_var ctx env n) (expression ctx env h typenv));
                                          !e ] ;
                                  Printf.printf "Success substitution: %s\n" (Expr.to_string !e);
                                  let txp_tl = List.tl txp_list in
                                   prove_pair ctx env t txp_tl e typenv
      | _ -> Printf.printf "Undefined type for pair element"
  ) *)
    | h :: [] -> ( 
      Printf.printf "Last element\n";
            match (List.hd tuple_type).desc with 
              | Erefinementpair(n,typ) -> 
                (match typ.desc with 
                  | Etypeconstr(basetype, typ_exp_list) -> Printf.printf "Etypeconstr pairs\n"; 
                                (
                                  match basetype with 
                                  | Name(btype) -> Printf.printf "Basetype found %s\n" btype; Printf.printf "Prove pair call - variable: %s\n" n;
                                        let last_element = Boolean.mk_eq ctx (create_z3_var ctx env n) 
                                        (expression ctx env h typenv) in
                                        z3_solve ctx (ref ({exp_env = ref [last_element] ; var_env = Hashtbl.create 0})) !e
                                  | Modname(q) -> Printf.printf "Modname found %s\n" q.id
                                ) 
                  | _ -> Printf.printf "Modname undefined pairs\n"
              )
              | Etypetuple(typ_list) -> Printf.printf "Etypetupple:\n";
                            
                             let exp_list = (match h.e_desc with 
                              | Etuple (e_list) -> Printf.printf "Etuple : \n"; 
                                    List.map (fun e -> e) e_list
                              | _ -> Printf.printf "Not a tuple\n"; [h]
                            ) in
                            prove_pair ctx env exp_list typ_list e typenv

              | _ -> Printf.printf "Undefined description type\n";
    )
    | h :: t -> ( 
        match (List.hd tuple_type).desc with 
                | Erefinementpair(n, typ) ->
                  (match typ.desc with
                  | Etypevar(basetype) -> (Printf.printf "Prove pair call - variable: %s\n" n; 
                                           e := Expr.substitute_one !e (create_z3_var_typed ctx env n basetype)
                                                                       (expression ctx env h typenv);
                                                                  Printf.printf "Success substitution\n"; 
                                           (* e := [
                                                   (Boolean.mk_eq ctx (create_z3_var ctx env n) (expression ctx env h typenv));
                                                   !e ] ; *)
                                           Printf.printf "Success substitution: %s\n" (Expr.to_string !e);
                                           let txp_tl = List.tl tuple_type in
                                           prove_pair ctx env t txp_tl e typenv)
                  | Etypeconstr(basetype, typ_exp_list) -> Printf.printf "Etypeconstr pairs\n"; 
                       (
                         match basetype with 
                         | Name(btype) -> Printf.printf "Basetype found %s\n" btype; (Printf.printf "Prove pair call - variable: %s\n" n;
                                           e := Boolean.mk_implies ctx 
                                                   (Boolean.mk_eq ctx (create_z3_var ctx env n) (expression ctx env h typenv))  (!e);
                                         (* e := Expr.substitute_one !e (create_z3_var ctx env n)
                                                                     (expression ctx env h typenv); *)
                                                               Printf.printf "Success substitution: %s\n" (Expr.to_string !e);
                                                               let txp_tl = List.tl tuple_type in
                                                               prove_pair ctx env t txp_tl e typenv)
                         | Modname(q) -> Printf.printf "Modname found %s\n" q.id
                       ) 
                  | _ -> Printf.printf "Undefined desc type\n"
                  )
                | _ -> Printf.printf "Undefined modname\n"
    )
      


and operator ctx env typenv e e_list =
(*
        ctx    -> z3 context
        env    -> environment (list of z3 expressions)
        typenv -> typing environment ( Hash table of string = variable name * string = base type)
        e      -> expression operator
        e_list -> expression list, contains left and right arguments used by operator

                  e
              /       \
          e_list[1]  e_list[2]
        
        Builds z3 expression from operator and its left and right side

        Returns z3 expression
*)
  (*match desc with 
  (*TODO: check for list length*)

  match e_list with
    | op_l :: [] -> ()
      match e with 
        | "~" -> () (*Unary operator case*)
    | op_l :: op_r :: [] -> ()
      match e with 
        | _ -> () (*Binary operator case*)
    | _ -> () (*ERROR!*)
  *)
  Printf.printf "Operator call %s : \n" e;
  match e with 
  | ">=" -> Arithmetic.mk_ge ctx (expression ctx env (hd e_list) typenv) (expression ctx env (hd (tl e_list)) typenv)
  | ">" -> Arithmetic.mk_gt ctx (expression ctx env (hd e_list) typenv) (expression ctx env (hd (tl e_list)) typenv)
  | "<=" -> Arithmetic.mk_le ctx (expression ctx env (hd e_list) typenv) (expression ctx env (hd (tl e_list)) typenv)
  | "<" -> Arithmetic.mk_lt ctx (expression ctx env (hd e_list) typenv) (expression ctx env (hd (tl e_list)) typenv)
  | "=" -> Boolean.mk_eq ctx (expression ctx env (hd e_list) typenv) (expression ctx env (hd (tl e_list)) typenv)
  | "!=" -> Boolean.mk_not ctx (Boolean.mk_eq ctx (expression ctx env (hd e_list) typenv) (expression ctx env (hd (tl e_list)) typenv))
  | "*." | "*" | "Stdlib.*." -> Arithmetic.mk_mul ctx [(expression ctx env (hd e_list) typenv); (expression ctx env (hd (tl e_list)) typenv)]
  | "+." | "+" | "Stdlib.+." -> Arithmetic.mk_add ctx [(expression ctx env (hd e_list) typenv); (expression ctx env (hd (tl e_list)) typenv)]
  | "-." | "-" | "Stdlib.-." -> Arithmetic.mk_sub ctx [(expression ctx env (hd e_list) typenv); (expression ctx env (hd (tl e_list)) typenv)]
  | "&&" -> Boolean.mk_and ctx [(expression ctx env (hd e_list) typenv); (expression ctx env (hd (tl e_list)) typenv)]
  | "||" -> Boolean.mk_or ctx [(expression ctx env (hd e_list) typenv); (expression ctx env (hd (tl e_list)) typenv)]
  | s -> Printf.printf "Non-standard operator s : %s\n" (s); prove_function ctx s env e_list typenv
  | t -> Printf.printf "Invalid expression symbol: %s\n" t; Printf.printf "%d\n" (List.length e_list); Integer.mk_numeral_s ctx "42"

(* translate expressions into Z3 constructs*)

and operator_expression_to_string ({ e_desc = desc; e_loc = loc}) =
(* Used to prevent creation of isolated expressions of operators: i.e >=, >, && *)
      match desc with 
      | Eglobal { lname = ln } -> Printf.printf "Operator stringfy\n"; (match ln with
        (*TODO: Append a modname to Name if not found, rather than removing it from a Modname, so we preserve module info for global declarations *)
        | Name(n) -> Printf.printf "Name: %s\n" n; n
        | Modname(qualid) -> Printf.printf "Modname: %s\n" qualid.id; qualid.id) 
      | _ -> Printf.printf "undefined behavior\n"; "undefined"

and operation ctx env typenv op e_list =
(*
    ctx -> z3 context
    env -> expression environment
    typenv -> typing environment
    op -> operation definition
    e_list -> list of operands

    Currently used to type check streams
*)
    match op, e_list with
    | Eunarypre, [e] -> Printf.printf "Eunarypre\n" 
    | Efby, [e1;e2] -> Printf.printf "Efby\n"
    | Eminusgreater, [e1;e2] -> Printf.printf "Eminusgreater (->)\n";
    (* e1 -> base case of stream*)
    (* e2 -> induction hypothesis of stream*)
    (* let new_stream = {initialization_var: e1; application_function: e2} in *)
    (* add_stream  *)
    | Eifthenelse, [e1; e2; e3] -> Printf.printf "Eifthenelse\n"
    | Eup, [e] -> Printf.printf "Eup\n"
    | Einitial, [] -> Printf.printf "Einitial\n"
    | (Etest | Edisc | Ehorizon), [e] -> Printf.printf "Etest | Edisc |Ehorizon\n"
    | Eaccess, [e1; e2] -> Printf.printf "Eaccess\n"
    | Eupdate, [e1; i; e2] -> Printf.printf "Eupdate\n"
    | Eslice _, [e] -> Printf.printf "Eslice\n"
    | Econcat, [e1; e2] -> Printf.printf "Econcat\n"
    | Eatomic, [e] -> Printf.printf "Eatomic\n"
    | _ -> Printf.printf "Operation undefined\n"
    

and expression ctx env ({ e_desc = desc; e_loc = loc }) typenv =
(*
        ctx    -> z3 context
        env    -> environment (list of z3 expressions)
        desc   -> expression desciption
        loc    -> expression location
        typenv -> typing environment ( Hash table of string = variable name * string = base type)

        Processes zelus expression into z3 expression

        Returns Z3 expression
*)
  match desc with
    | Econst(i) -> immediate ctx i
    | Eglobal { lname = ln } -> Printf.printf "Eglobal expression\n"; create_z3_var ctx env (match ln with
      (*TODO: Append a modname to Name if not found, rather than removing it from a Modname, so we preserve module info for global declarations *)
      | Name(n) -> Printf.printf "Name: %s\n" n; n
      | Modname(qualid) -> Printf.printf "Modname: %s\n" qualid.id; qualid.id) 
    | Eapp({ app_inline = i; app_statefull = r }, e, e_list) -> 
      (*Printf.printf "Expression %s\n" (Expr.to_string (expression ctx env e typenv));*)
      Printf.printf "Expression app:\n";
      operator ctx env typenv (*Expr.to_string (expression ctx env e typenv)*) (operator_expression_to_string e) e_list 
    | Elocal(n) -> Printf.printf "Elocal: %s : %d\n" n.source n.num;
          (match typenv with
          | Some(t) -> let ismember = (Hashtbl.mem t n.source)
            in (if ismember then (let basetype = (Hashtbl.find t n.source) in
              Printf.printf "%s has type %s" n.source basetype;
              (create_z3_var_typed ctx env n.source basetype))
          else
            (Printf.printf "Creating var: %s\n" n.source; immediate ctx (Estring(n.source))) )
          | _ -> Printf.printf "Error: typenv not given!\n"; Expr.mk_const ctx (Symbol.mk_string ctx n.source) (Real.mk_sort ctx))
    | Elet (l, e)-> 
        Printf.printf "Elet parsing: \n";
        (* local ctx env typenv l;
         let local_exp = expression ctx env l typenv in
        Printf.printf (Expr.to_string local_exp);
        Printf.printf "Body:\n";*)
        let body_exp = expression ctx env e typenv in
        Printf.printf "Body exp :%s \n" (Expr.to_string body_exp);
        (List.iter (equation ctx env typenv) l.l_eq);
        print_env env;
        body_exp
        (* let eq_exp = equation ctx env typenv (List.hd l.l_eq) in *)
        (* Printf.printf "Body: %s\nEq: %s\n" (Expr.to_string body_exp) (Expr.to_string eq_exp); *)
        (* let res = Boolean.mk_eq ctx (body_exp) (eq_exp) in   *)
        (* let remainder = Boolean.mk_and ctx (List.map (fun a -> equation ctx env typenv a) (l.l_eq))in *)
        (* Printf.printf  "Body: %s\n" (Expr.to_string body_exp); *)
        (* Printf.printf "Remainder: %s\n" (Expr.to_string remainder); *)
        (* res *)

    | Econstr0 _ -> Printf.printf "Econstr0\n"; Integer.mk_numeral_s ctx "42"
    | Econstr1 (_, _) -> Printf.printf "Econstr1\n";Integer.mk_numeral_s ctx "42"
    | Elast _ -> Printf.printf "Elast\n";Integer.mk_numeral_s ctx "42"
    | Eop ( op, e_list) -> Printf.printf "Eop\n"; operation ctx env typenv op e_list; Integer.mk_numeral_s ctx "42"
    (* used to type check pairs *)
    | Etuple (e_list) -> Printf.printf "Etuple : \n"; 
    let exp_list_temp = List.map (fun e -> expression ctx env e typenv) e_list in
    let mk_tuple = Symbol.mk_string ctx "mk_tuple" in
    let field_name = [ Symbol.mk_string ctx "fst"; Symbol.mk_string ctx "snd"] in
    let field_sort = [ Integer.mk_sort ctx; Integer.mk_sort ctx] in
    let my_tuple = Tuple.mk_sort ctx mk_tuple field_name field_sort in
    Printf.printf "My tuple: %s\n" (Sort.to_string my_tuple);
    let f = (Expr.mk_const ctx (Symbol.mk_string ctx "f") (Integer.mk_sort ctx))  in 
    let s = (Expr.mk_const ctx (Symbol.mk_string ctx "s") (Integer.mk_sort ctx)) in
    (* create tuple declaration and retrieve fields (fst, snd) *)
    let tuple_decl = Tuple.get_mk_decl my_tuple in
    let my_fields = Tuple.get_field_decls my_tuple in
    (* apply functions to get fst and snd elements*)
    let app1 = FuncDecl.apply (tuple_decl) [f; s] in
    let app2 = FuncDecl.apply (List.hd my_fields) [app1] in
    let app3 = FuncDecl.apply (List.hd (List.tl my_fields)) [app1] in
    (* equate functions to return expressions*)
    let exp1 = Boolean.mk_eq ctx app2 (List.hd exp_list_temp) in
    let exp2 = Boolean.mk_eq ctx app3 (List.hd (List.tl exp_list_temp)) in
    Printf.printf "Expression 1: %s\n" (Expr.to_string exp1);
    Printf.printf "Expression 2: %s\n" (Expr.to_string exp2);
    (* Printf.printf "Pair : [ "; *)
    (* List.iter (fun s -> Printf.printf "%s " (Expr.to_string s)) exp_list_temp; Printf.printf "]\n"; Integer.mk_numeral_s ctx "42" *)
    Integer.mk_numeral_s ctx "42"
    (* refinement tuples *)
    | Erefinementtuple(e_list, tuple_type, e) -> Printf.printf "Erefinementtuple : \n";
     (*  5 , 5 + 3)
         [x:int; y:int]

         e = x < y && y < z
     *)
     (* Printf.printf "Expression : %s\n" (Expr.to_string (expression ctx env e typenv)); *)
     (* List.iter ( fun elem -> Printf.printf "Element: %s\n"  (Expr.to_string (expression ctx env elem typenv))) e_list; *)
     let pair_constraint = expression ctx env e typenv in
     let type_tuple_list = (match tuple_type.desc with 
                             | Etypetuple(t_list) -> t_list                     
     ) in
     Printf.printf "Pair constraint : %s\n" (Expr.to_string pair_constraint);
     prove_pair ctx env e_list type_tuple_list (ref pair_constraint) typenv;
     Integer.mk_numeral_s ctx "42"
    | Erecord_access (_, _) -> Printf.printf "Erecord_acess\n";Integer.mk_numeral_s ctx "42"
    | Erecord _-> Printf.printf "Erecord\n";Integer.mk_numeral_s ctx "42"
    | Erecord_with (_, _)-> Printf.printf "Erecord_with\n";Integer.mk_numeral_s ctx "42"
    | Etypeconstraint (_, _)-> Printf.printf "Etypeconstraint\n";Integer.mk_numeral_s ctx "42"
    | Epresent (_, _)-> Printf.printf "Epresent\n";Integer.mk_numeral_s ctx "42"
    | Ematch (_, _, _)-> Printf.printf "Ematch\n";Integer.mk_numeral_s ctx "42"
    | Eseq ( e1, e2)-> Printf.printf ("Eseq : (e1 = %s e2 = %s)\n") (Expr.to_string (expression ctx env e1 typenv)) (Expr.to_string (expression ctx env e2 typenv));
     Integer.mk_numeral_s ctx "42"
    | Eperiod _-> Printf.printf "Eperiod\n"; Integer.mk_numeral_s ctx "42"
    | Eblock (_, _)-> Printf.printf "Eblock\n"; Integer.mk_numeral_s ctx "42"  
    | _ -> (Printf.printf "Ignore expression\n"); Integer.mk_numeral_s ctx "42"

    (*| Econstr0(lname) -> Zelus.Econstr0(longname lname)
    | Evar(Name(n)) ->
        begin try
            let { Rename.name = m } = Rename.find n env in Zelus.Elocal(m)
        with
          | Not_found -> Zaux.global (Lident.Name(n))
        end
    | Evar(lname) -> Zaux.global (longname lname)
    | Elast(n) -> Zelus.Elast(name loc env n)
    | Etuple(e_list) -> Zelus.Etuple(List.map (expression env ctx ) e_list)
    | Econstr1(lname, e_list) ->
        Zelus.Econstr1(longname lname, List.map (expression env ctx ) e_list)

    | Eop(op, e_list) ->
       Zelus.Eop(operator loc env op, List.map (expression env ctx) e_list)
    | Eapp({ app_inline = i; app_statefull = r }, e, e_list) ->
       Zelus.Eapp({ Zelus.app_inline = i; Zelus.app_statefull = r },
		  expression env ctx e, List.map (expression env ctx) e_list) 
  in emake loc desc
    
    | Erecord(label_e_list) ->
        Zelus.Erecord(recordrec loc env label_e_list)
    | Erecord_access(e1, lname) ->
        Zelus.Erecord_access(expression env ctx e1, longname lname)
    | Erecord_with(e, label_e_list) ->
       Zelus.Erecord_with(expression env ctx e, recordrec loc env label_e_list)
    | Etypeconstraint(e, ty) ->
        Zelus.Etypeconstraint(expression env ctx e, types env ty)
    | Elet(is_rec, eq_list, e_let) ->
        let env_p, env, eq_list = letin is_rec env eq_list in
        Zelus.Elet({ Zelus.l_rec = is_rec;
                     Zelus.l_eq = eq_list; 
                     Zelus.l_loc = loc; 
                     Zelus.l_env = Rename.typ_env env_p },
                    expression env ctx e_let)
    | Eseq(e1, e2) ->
        Zelus.Eseq(expression env ctx e1, expression env ctx e2)
    | Eperiod(p) ->
       Zelus.Eperiod(period env p)
    (*added here*)
    | Eassume(e) -> 
       Zelus.Eassume(expression env ctx e)   
    (*added here
    | Emove(e) ->
       Zelus.Emove(expression env e)	*)
    | Estore(c, k) ->
      		print_string("Robot command: "); print_string (c); print_string("\n");
      		print_string ("Value: "); print_float (k); print_string("\n"); Zelus.Estore(c, k)
    (* control structures are turned into equations *)
    | Ematch(e1, handlers) ->
        (* match e with P -> e1 => 
           local result do match e with P -> do result = e1 done in result *)
        let result = Zident.fresh "result" in
        let emit e = 
	  eqmake e.Zelus.e_loc (Zelus.EQeq(varpat e.Zelus.e_loc result, e)) in
	let e1 = expression env ctx e1 in
        let handlers = 
	  match_handler_list 
	    (fun _ env e -> let e = expression env ctx e in block_with_emit emit e) 
	    Rename.empty env handlers in
	let eq = eqmake loc (Zelus.EQmatch(ref false, e1, handlers)) in
        Zelus.Eblock(block_with_result result [eq], var loc result)
   | Epresent(handlers, e_opt) ->
        (* Translate a present expression into a present equation *)
        (* [present sc1 -> e1 | ... else e] into *)
        (* [local res do present sc1 -> do res = e1 done *)
        (*               |... else do res = e in res]*)
        (* [present sc1 -> e1 | ... init e] into *)
        (* [local res do present sc1 -> do res = e1 done *)
        (*               | ...and init res = e in res]*)
        (* [present sc1 -> e1 ...] into *)
        (* [local res do present sc1 -> do emit res = e1 done] *)
        (* [emit e] returns either [emit x = e] or [x = e] according to *)
        (* the completeness of the definition. A signal is emitted when the *)
        (* present handler is not complete. *)
        let result = Zident.fresh "result" in
	let emit e =
	  match e_opt with 
	    | None -> 
	        eqmake e.Zelus.e_loc (Zelus.EQemit(result, Some(e)))
	    | Some(Init _)
	    | Some(Default _) ->
	        eqmake e.Zelus.e_loc
                  (Zelus.EQeq(varpat e.Zelus.e_loc result, e)) in
	let handlers = 
	  present_handler_list
	    scondpat 
	    (fun _ env e -> let e = expression env ctx e in block_with_emit emit e)
	    Rename.empty env handlers in
	let b_opt, eq_init, is_mem = 
	    match e_opt with 
	      | None -> None, [], false
	      | Some(Init(e)) -> None, 
		[eqmake loc (Zelus.EQinit(result, expression env ctx e))],
		true
	      | Some(Default(e)) -> 
		 Some(block_with_emit emit (expression env ctx e)), [], false in
	let eq_list = 
	  eqmake loc (Zelus.EQpresent(handlers, b_opt)) :: eq_init in
	Zelus.Eblock(block_with_result result eq_list, var loc result)
    | Ereset(e_body, r) ->
  let e_body = expression env ctx e_body in
	let r = expression env ctx r in
	let result = Zident.fresh "result" in
	let eq = 
	  eqmake e_body.Zelus.e_loc
	    (Zelus.EQeq(varpat e_body.Zelus.e_loc result, e_body)) in
	let eq = eqmake loc (Zelus.EQreset([eq], r)) in
	Zelus.Eblock(block_with_result result [eq], var loc result)
    | Eautomaton(handlers, e_opt) ->
        let result = Zident.fresh "result" in
	let emit e = 
	  eqmake e.Zelus.e_loc (Zelus.EQeq(varpat e.Zelus.e_loc result, e)) in
	let is_weak, handlers, e_opt = 
	  state_handler_list loc scondpat 
           (block locals
              (fun _ env e -> let e = expression env ctx e in [emit e]))
	   (block locals equation_list)
              expression 
	      Rename.empty env handlers ctx e_opt in
	let eq = eqmake loc (Zelus.EQautomaton(is_weak, handlers, e_opt)) in
	Zelus.Eblock(block_with_result result [eq], var loc result)
    | Eblock(b, e) ->
       let env, b = block_eq_list Rename.empty env b in
       let e = expression env ctx e in
       Zelus.Eblock(b, e) in
  emake loc desc*)
and get_return_type ctx env ({ e_desc = desc; e_loc = loc }) typenv =
(*
      ctx    ->  z3 context 
      env    ->  environment (list of z3 expressions)
      desc   ->  expression description
      loc    ->  expression location
      typenv ->  typing environment ( Hash table of string = variable name * string = base type)
      
      Converts the last expression defined within a function to a Z3 expression

      Returns functions last expression as Z3 expression
*)
    match desc with
    | Eapp({ app_inline = i; app_statefull = r }, e, e_list) -> 
      let return_var = expression ctx env (List.hd e_list) typenv in
      return_var 
    | Elet (l, e)-> 
        let body_exp = expression ctx env e typenv in
        body_exp
    | _ -> Printf.printf "Not a function return type."; Integer.mk_numeral_s ctx "42"

and build_input_var ctx env e typenv istuple =
      if not istuple then (
        [(expression ctx env e typenv)]
      ) else (
        match e.e_desc with 
        | Etuple(e_list) ->
          [(expression ctx env (List.hd e_list) typenv) ; (expression ctx env (List.hd (List.tl e_list)) typenv) ]
      )

and build_return_var ctx env n istuple =
      if not istuple then (
      [create_z3_var ctx env (Printf.sprintf "%s_return" n)]
      ) else (
      [create_z3_var ctx env (Printf.sprintf "%s_fst" n); create_z3_var ctx env (Printf.sprintf "%s_snd" n) ]
      )

and qualident t =
(*
      t -> type data structure 

      Prints qualified identifier for given type
*)
    match t with
    | Lident.Name(n) -> Printf.printf "%s \n" n
    | Lident.Modname({ Lident.qual = m; Lident.id = s }) -> Printf.printf "%s.%s \n" m s

and print_type_element typ_elem =
      Printf.printf "TYPE ELEMENT : \n";
    match typ_elem.desc with
    | Etypevar(n) -> Printf.printf "Etypevar %s" n
    | Etypeconstr(basetype, t_exp_list) -> Printf.printf "Etypeconstr pairs\n"; 
                                      (
                                        match basetype with 
                                        | Name(btype) -> Printf.printf "Basetype found %s\n" btype
                                        | Modname(q) -> Printf.printf "Modname found %s\n" q.id
                                      ) 
    | Etypetuple(t_exp_list) -> Printf.printf "Etypetuple\n"; List.iter (print_type_element) t_exp_list
    | Etypevec(t_exp, sz) -> Printf.printf "Etypevec \n"; print_type_element t_exp
    | Etypefun(k, name, t_exp, t_exp2) -> Printf.printf "TODO -- print ETYPEFUN"
    | Etypefunrefinement(k, name, typ_exp, typ_exp2, e) -> Printf.printf "TODO -- print ETYPEFUNREFINEMENT"
    | Erefinementpairfuntype(t_exp_list, e) -> Printf.printf "Erefinementpairfuntype\n"; List.iter (fun elem -> print_type_element elem; Printf.printf "elem end\n\n") t_exp_list
    | Erefinement(t_exp, e) -> Printf.printf "Erefinement\n"; print_type_element t_exp
    | Erefinementpair(n, type_expression) -> Printf.printf "Erefinementpair\n"; print_type_element type_expression

and add_tuple_list_to_type_env ctx env pat_list typ_exp typenv =
(*
      ctx      -> Z3 context
      txp_list -> list of tuple elements
      typ_exp  -> type expression information
      typ_env  -> typing environment

      Add each refined element of tuple to typing environment
*)
      List.iter (
        fun elem -> 
          (match elem.p_desc with
          | Evarpat(n) -> Printf.printf "Evarpat in Etypeconstraintpat: (%s : %d) \n" n.source n.num;
            (*(pattern ctx env pat); *)
            (match typ_exp.desc with
            | Erefinement(t, e) -> Printf.printf "Adding to table: %s\n" n.source; 
              (
              match typenv with
              | Some(tbl) -> Hashtbl.add tbl n.source (match t.desc with 
              (* Find and then add base type to local typing environment *)
              | Etypeconstr(l,_) -> (match l with
                  | Name(s) -> s
                  | Modname(q) -> q.id)
              | _ -> "Unspecified typenv match\n")
              | None -> ()
              )
            | Etypevar(n) -> Printf.printf "Etypevar : %s\n" n
            | Etypeconstr(t, typ_exp_list) -> Printf.printf "Etypeconstr\n"
            | Etypetuple(typ_exp_list) ->  Printf.printf "Etypetuple\n"
            | Etypevec(typ_exp, sz) -> Printf.printf "Etypevec\n"
            | Etypefun(k, t, typ_exp1, typ_exp2) -> Printf.printf "Etypefun\n"
            | Etypefunrefinement(k, t, typ_exp1, typ_exp2, e) -> Printf.printf "Etypefunrefinement\n"
            | Erefinementpairfuntype(t_exp_list, e) -> Printf.printf "Erefinementpairfuntype\n";
                     Printf.printf "Element: %s\n" n.source;
                     let pair_expression = expression ctx env e typenv in
                     (add_constraint env pair_expression;
                     Printf.printf "Adding expression: %s\n" (Expr.to_string pair_expression))
            | Erefinementpair(n, t_exp) -> Printf.printf "Erefinementpair\n"
            | _ -> Printf.printf "Unspecified type constraint match\n")
          | Econstpat(i) -> Printf.printf "Econstpat\n"
          | Econstr0pat(t) -> Printf.printf "Econstr0pat\n"
          | Econstr1pat(t, pat_list) -> Printf.printf "Econstr1pat\n"
          | Etuplepat(pat_list) -> Printf.printf "Etuplepat\n"
          | Ealiaspat(pat, t) -> Printf.printf "Ealiaspat\n"
          | Eorpat(pat1, pat2) -> Printf.printf "Eorpat\n"
          | Erecordpat(l_p_list) -> Printf.printf "Erecordpat\n"
          | Etypeconstraintpat(pat, typ_exp) -> Printf.printf "Etypeconstraintpat\n"
          | _ -> Printf.printf "Unspecified pat.p_desc match\n");   
          ) pat_list

and type_exp_desc ctx env typenv t = 
(*
      ctx    -> z3 context
      env    -> environment (list of z3 expressions)
      typenv -> typing environment ( Hash table of string = variable name * string = base type)
      t      -> type expression 

      Creates z3 expression from type expression and adds it to the environment
*)
  match t.desc with
  | Etypevar(n) -> Printf.printf "Etypevar %s\n" n
  | Etypeconstr(t, txp_list) -> (Printf.printf "Etypeconstr\n"); qualident t; (List.iter (type_exp_desc ctx env typenv) txp_list) 
  | Etypetuple(txp_list) -> Printf.printf "Etypetuple\n"; (List.iter (type_exp_desc ctx env typenv) txp_list)
  | Etypevec(texp , si) -> Printf.printf "Etypevec\n"
  | Etypefun(k, t, texp, texp2) -> Printf.printf "Etypefun\n" 
  | Etypefunrefinement(k, t, te, te2, e) -> Printf.printf "Etypefunrefinement\n"
  | Erefinement(t, e) -> Printf.printf "Erefinement\n";  
       let expr = (expression ctx env e typenv) in
       (add_constraint env expr;
       Printf.printf "Returning from e local: %s\n" (Expr.to_string expr))
  | Erefinementpairfuntype(txp_list, exp) -> Printf.printf "Erefinementfunpair \n"
       (* List.iter (fun elem ->         ) txp_list *)

and pattern ctx env typenv pat = 
(*
      ctx    ->  z3 context     
      env    ->  environment (list of z3 expressions)
      typenv ->  typing environment ( Hash table of string = variable name * string = base type)
      pat    ->  pattern expression to be processed

      Processes the pattern expression and modifies the typing environment to account for new expressions
*)
  match pat.p_desc with
      | Ewildpat -> Printf.printf "Ewildpat\n"
      | Econstpat(i) ->  Printf.printf "Econstpat\n"; Printf.printf "%s\n" (Expr.to_string (immediate ctx i))
      | Econstr0pat(ln) -> Printf.printf "Econstr0pat\n"
      | Econstr1pat(ln, p_list) -> Printf.printf "Econstr1pat\n"
      | Etuplepat(p_list) -> Printf.printf "Etplepat\n"
      | Ealiaspat(p, t) -> Printf.printf "Ealiaspat\n"
      | Eorpat(p, p2) -> Printf.printf "Eorpat\n"
      | Erecordpat(txp_list) -> Printf.printf "Erecordpat\n"
      | Evarpat(n) ->
        Printf.printf "Evarpat: (%s : %d) \n" n.source n.num
      | Etypeconstraintpat(pat, typ_exp) -> (Printf.printf "Etypeconstraintpat: "); 
        (match pat.p_desc with
        | Evarpat(n) -> Printf.printf "Evarpat in Etypeconstraintpat: (%s : %d) \n" n.source n.num;
          (*(pattern ctx env pat); *)
          (match typ_exp.desc with
          | Erefinement(t, e) -> Printf.printf "Adding to table: %s\n" n.source; 
            (
              match typenv with
                | Some(tbl) -> Hashtbl.add tbl n.source (match t.desc with 
                (* Find and then add base type to local typing environment *)
                | Etypeconstr(l,_) -> (match l with
                    | Name(s) -> s
                    | Modname(q) -> q.id)
                | _ -> "Unspecified typenv match\n")
                | None -> ()
            )
          | Erefinementpairfuntype(t_exp_list, e) -> Printf.printf "Erefinementpairfuntype\n"
          | Erefinementpair(n, t_exp) -> Printf.printf "Erefinementpair\n"
          | Etypevar(n) -> Printf.printf "Etypevar \n"
          | Etypeconstr(name, t_exp_list) -> Printf.printf "Etypeconstr \n"
          | Etypetuple(t_exp_list) -> Printf.printf "Etypetuple \n"
          | Etypevec(t_exp, sz) -> Printf.printf "Etypevec \n"
          | Etypefun(k, n, t_exp, t_exp2) -> Printf.printf "Etypefun \n"
          | Etypefunrefinement(k, n, t_exp, t_exp2, e) -> Printf.printf "Etypefunrefinement \n"
          | _ -> Printf.printf "Unspecified type constraint match\n")
        | Etuplepat(pat_list) -> Printf.printf "Etypetuple match: \n"; add_tuple_list_to_type_env ctx env pat_list typ_exp typenv
        | _ -> Printf.printf "Unspecified pat.p_desc match\n");   
        (type_exp_desc ctx env (typenv) typ_exp)

let get_argument_list typenv =
(*
  typenv -> typing environment Hash table of string * string

  Iterates through hash tables and retrieves first element to the argument list

  Returns the argument list
*)
  let arg_list = ref [] in
  Hashtbl.iter (fun a b -> ( arg_list := (!arg_list) @ [a]; () )) typenv;
  !arg_list 

(* main entry functions *)
(* this function modifies the environemnt, returns unit *)

let implementation ff ctx env (impl (*: Zelus.implementation_desc Zelus.localized*))  =
(*
    ff        ->   printinf formart  (not used in this file)
    ctx       ->   Z3 context variable
    env       ->   Z3 local environment (reference of a list of Z3 expressions)
    impl      ->   a single element from the zelus AST list
    
    Applies a specified procedure to the element in the zelus AST list
*)
      match impl.desc with
      (* Add to Z3 an equality constraint that looks like: n == (Z3 parsed version of e) *)
      | Econstdecl(f, is_static, e) -> (Printf.printf "Econstdecl %s\n" f); 
        (* constraint : f = e *)
        add_constraint !env (Boolean.mk_eq ctx (create_z3_var ctx !env f) (expression ctx !env e None));
        print_env !env
      (* For constant functions, let x=f we assign x the type x:{float z | z=f} *)
      (* Refinement type of the form: let n1:n2{e1} = e2 *)
      | Erefinementdecl(n1, n2, e1, e2) ->
      	 Printf.printf "Erefinementdecl %s %s\n" n1 n2;
         add_constraint !env (Boolean.mk_eq ctx (create_z3_var ctx !env n1) (expression ctx !env e2 None));
         z3_solve ctx env (expression ctx !env e1 None);
         print_env !env

      | Efundecl(n, { f_kind = k; f_atomic = is_atomic; f_args = p_list;
		      f_body = e; f_loc = loc }) -> (Printf.printf "Efundecl %s\n" n); 
            (Printf.printf "# of Arguments: %d\n" (List.length p_list));

            let argc = (List.length p_list) in 
            let typenv = Hashtbl.create argc in
            let local_env = ref { exp_env = ref []; var_env = Hashtbl.create 0}  in
            (List.iter (pattern ctx !local_env (Some typenv)) p_list);
            Hashtbl.iter (fun a b -> (Printf.printf "%s:%s;" a b)) typenv;
            (* implementation_list ff ctx e; *) 
            Printf.printf "Argc: %d\n" argc;
            
  
            (* treat function body as a program and prove conditions*)
            let expr = (expression ctx !local_env e (Some typenv)) in
            add_constraint !local_env expr;
            Printf.printf "Function body expression handling: %s\n" (Expr.to_string expr);
            
            (* let f_new = { argument_constraints = [Boolean.mk_true ctx];
            variable_maps = Hashtbl.create 0;
            argument_list = ["a"];} in
            add_function n f_new; *)
            
            print_env !local_env
            
            (* function proved, add to global environment, create a Z3 function 
            and a constraint defining its return type*)
            (* List.iter print_env_list !local_env; print_newline (); *)
            
      
      | Erefinementfundecl(n, { f_kind = k; f_atomic = is_atomic; f_args = p_list;
          f_body = e; f_loc = loc }, rettype) -> (Printf.printf "Erefinementfundecl %s\n" n); 
          let argc = (List.length p_list) in 
          let typenv = Hashtbl.create argc in
          let local_env = ref { exp_env = ref []; var_env = Hashtbl.create 0} in
          let istuple = (match e.e_desc with
                          | Etuple(_) -> true
                          | _ -> false
                        ) in
          let isstream = (match e.e_desc with
                          | Elet(l, e) -> Printf.printf "Stream elet\n"; (match (List.hd l.l_eq).eq_desc with 
                            | EQeq(p, e) -> ( match e.e_desc with
                                | Eop(op, e_list) -> Printf.printf "Stream eop\n"; (
                                  match op, e_list with
                                  | Eminusgreater, [e1;e2] -> Printf.printf "Stream eminusgreater\n"; true
                                  | _ -> Printf.printf "Stream eminusgreater false\n"; false
                                  )  
                                | _ -> Printf.printf "Stream eop false\n"; false   
                            )
                            | _ -> Printf.printf "Stream eqeq false\n"; false 
                            )    
                          | _ -> Printf.printf "Stream elet false\n"; false     
                          ) in
          if not isstream then (            
          (* add function input constraints to local environment *)
          (List.iter (pattern ctx !local_env (Some typenv)) p_list);
          Hashtbl.iter (fun a b -> (Printf.printf "%s:%s;" a b)) typenv;
          (* implementation_list ff ctx e; *)


          (* Need to do:
           given function definition: let f (a:t_a{p_a}, b:t_b{p_b}...): t_f{p_f} = exp 
           Prove: (p_a & p_b & ...) -> exp:t_f{p_f}
           
           
           let b:int{b < -2} = -10 in 
           let f2 (x:int{x < 0}) : int:{f2_return >= 0} =
                let y = x*x in
                y
           in f2 b
             
            f b
            DISProve: ~((x<0) & (y=f2) -> (f2 >= 0))
            DISProve: ~(b < 0) (replace x with b)
            ( b = x ) -> (b < 0)

          *)
          (* let expr = (expression ctx env e (Some typenv)) in
          (add_constraint local_env expr;
          Printf.printf "Function body expression: %s\n" (Expr.to_string expr)); *)
          (* create function constraint to be proven *)
          let return_exp = (expression ctx !local_env rettype (Some typenv)) in
          (Printf.printf "Return type expression: %s\n" (Expr.to_string return_exp));
          let function_argument_constraints = !(!local_env.exp_env) in
          let function_variable_type_map = typenv in
          let function_argument_list = List.rev (get_argument_list( typenv )) in
          let f_new = { argument_constraints = function_argument_constraints;
                        variable_maps = function_variable_type_map;
                        argument_list = function_argument_list; 
                        creation_env = !local_env; } in
          (* adding post and pre conditions of funtion to environment *)
          add_function n f_new;
          Printf.printf "Printing function environment...\n";
          print_function_environment ();
          print_env !local_env;

          (* treat function body as a program and prove conditions*)
          (* input_var is the last variable returned by the function *)
          (* let input_var = (expression ctx !local_env e (Some typenv)) in *)
          let input_var = build_input_var ctx !local_env e (Some typenv) istuple in
          List.iter (fun input_elem -> Printf.printf "Function body expression handling: %s\n" (Expr.to_string input_elem)) input_var;
          print_env !local_env;
          
          
          (*let return_var = (get_return_type ctx local_env rettype (Some typenv)) in*)
          let return_var = build_return_var ctx !local_env n istuple in 
          List.iter (fun return_elem -> Printf.printf "Return var: %s\n" (Expr.to_string return_elem)) return_var;
          (*let input_var = (get_return_type ctx local_env e (Some typenv)) in
          Printf.printf "Return var in: %s\n" (Expr.to_string input_var);*)
          (* let ret_constraint = (Boolean.mk_eq ctx return_var input_var) in *)
          let ret_constraint = List.map2 (fun input_elem return_elem -> Boolean.mk_eq ctx return_elem input_elem) input_var return_var in
          List.iter (fun ret_elem -> Printf.printf "return definition: %s\n" (Expr.to_string ret_elem); 
                     add_constraint !local_env ret_elem) ret_constraint;
          (* add_constraint !local_env ret_constraint; *)
          print_env !local_env;
          Printf.printf "Prove constraint: %s\n" (Expr.to_string return_exp);
          
          Printf.printf "Environment before solving: \n";
          print_env !local_env;
          z3_solve ctx local_env return_exp;
          (* function proved, add to global environment, create a Z3 function 
          and a constraint defining its return type*)
          print_env !local_env
          (* if proved rename return type with function name and add to global environment *)

          (* prove conditions *)

          (* implementation ff ctx local_env e; *)
          (* List.iter print_env_list !local_env; print_newline ()
           *)
          (* if properties are proved, then add to global environment*)

          (* TODO: make verif. conditions for function here *)

          (* TODO: define functions inside function*)
          ) else (
            (* Function is a stream *)
            (* add function input constraints to local environment *)
            Printf.printf "--STREAM--\n";
            (List.iter (pattern ctx !local_env (Some typenv)) p_list);
            Hashtbl.iter (fun a b -> (Printf.printf "%s:%s;" a b)) typenv;

            (* create function constraint to be proven *)
            let return_var = build_return_var ctx !local_env n istuple in 
            let return_exp = (expression ctx !local_env rettype (Some typenv)) in
            (Printf.printf "Return type expression: %s\n" (Expr.to_string return_exp));
            let function_argument_constraints = !(!local_env.exp_env) in
            let function_variable_type_map = typenv in
            let function_argument_list = List.rev (get_argument_list( typenv )) in
            let f_new = { argument_constraints = function_argument_constraints;
                          variable_maps = function_variable_type_map;
                          argument_list = function_argument_list; 
                          creation_env = !local_env; } in
            add_function n f_new;
            Printf.printf "Printing function environment...\n";
            print_function_environment ();
            print_env !local_env;
            (* stream typing rule*)
            let base_exp = match e.e_desc with
                          | Elet(l, e) -> (match (List.hd l.l_eq).eq_desc with 
                            | EQeq(p, e) -> ( match e.e_desc with
                                | Eop(op, e_list) -> (
                                  match op, e_list with
                                  | Eminusgreater, [e1;e2] -> 
                                    (* prove stream base case *)
                                    let base_var = expression ctx (!local_env) e1 (Some typenv) in
                                    let binding_exp = Boolean.mk_eq ctx base_var (List.hd return_var) in 
                                    let proof_env = ref {exp_env = ref (binding_exp ::!(!local_env.exp_env));
                                                         var_env = (!local_env.var_env)} in
                                    z3_solve ctx proof_env return_exp;
                                    (* prove stream induction hypothesis *)
                                    Printf.printf "Processing e2\n";
                                    let fun_name = (match e2.e_desc with 
                                                    | Eapp({ app_inline = i; app_statefull = r }, e, e_list) -> (operator_expression_to_string e)
                                    ) in
                                    Printf.printf "Function name: %s \n" fun_name;
                                    let stream_application = Hashtbl.find !function_space fun_name in
                                    let stream_app_arg = List.hd stream_application.argument_list in
                                    let argument_relation_exp = Boolean.mk_eq ctx base_var ( create_z3_var ctx (stream_application.creation_env) stream_app_arg) in
                                    let fun_relation_exp = Boolean.mk_eq ctx (List.hd return_var) (create_z3_var ctx (stream_application.creation_env) (Printf.sprintf "%s_return" fun_name)) in
                                    let concatenate_envs = [argument_relation_exp; fun_relation_exp] @ !(stream_application.creation_env.exp_env) @ !(!local_env.exp_env) in
                                    let function_proof_env = ref {exp_env = ref concatenate_envs; var_env = (!local_env.var_env)} in
                                    Printf.printf "Argument relation %s - Fun relation %s\n" (Expr.to_string argument_relation_exp) (Expr.to_string fun_relation_exp); 
                                    z3_solve ctx function_proof_env return_exp; 
                                    let new_stream = {
                                      initialization_var=   base_var;
                                      application_function= fun_name;
                                      return_exp = return_exp;
                                      refinement_exp = !(!local_env.exp_env) @ [binding_exp];
                                    } in add_stream n new_stream;
                                    true

                                    (* print_function fun_name stream_application; true *)
                                    (* let fun_exp = expression ctx !local_env e2 (Some typenv) in true *)


                                )  
                            )
                          )       
          
          in Printf.printf "end\n"
          )
      | Eopen(n) -> (Printf.printf "Eopen %s\n" n)
      | Etypedecl(n, params, tydecl) -> (Printf.printf "Etypedecl %s\n" n)

(* let f x:tx y:ty z:tz = e:te *)
(* f has the type: tx -> ty -> tz -> te *)
(* to prove: assume x:tx y:ty z:tz, try to use this to prove e:te*)
(* in code, you will have something that looks like: *)
(* let f x:{float z| phi_x(z)} y:{float z| phi_y(z)} z:{float z' | phi_z(z')} = e:{float z | phi_e(z)} *)

(* Z3 constraints should look like: *)
(* (x,y,z are properly typed) -> (e is properly typed) *)
(* ([x/z]phi_x(z) & [y/z]phi_y(z) & [z/z']phi_z(z')) -> [e/z]phi_e(z) *)

(* the main entry function *)
let implementation_list ff (impl_list) (*: Zelus.implementation_desc Zelus.localized list ) : Zelus.implementation_desc Zelus.localized list*) = 
(*
    ff        ->   printinf formart  (not used in this file)
    ctx       ->   Z3 context variable
    impl_list ->   zelus program AST
    
    Creates a Z3 local environment and iterates through each argument of the AST list

    Returns the zelus program AST
*)
  print_string "Hello, this is Z3 Refinement\n";
  let cfg = [("model", "true"); ("proof", "false")] in
	let ctx = (mk_context cfg) in
  let z3env = ref {exp_env = ref []; var_env = Hashtbl.create 0} in
  List.iter (implementation ff ctx z3env) impl_list;
  impl_list
