(**************************************************************************)
(*                                                                        *)
(*  The Zelus Hybrid Synchronous Language                                 *)
(*  Copyright (C) 2012-2016                                               *)
(*                                                                        *)
(*  Timothy Bourke                                                        *)
(*  Marc Pouzet                                                           *)
(*                                                                        *)
(*  Universite Pierre et Marie Curie - Ecole normale superieure - INRIA   *)
(*                                                                        *)
(*   This file is distributed under the terms of the CeCILL-C licence     *)
(*                                                                        *)
(**************************************************************************)
(* Abstract syntax tree after scoping *)

open Location
open Misc

type kind = S | A | C | D | AD | AS
type name = string

type 'a localized = { desc: 'a; loc: Location.location }


(** Types *)
type type_expression = type_expression_desc localized 

and type_expression_desc =
  | Etypevar of string
  | Etypeconstr of Lident.t * type_expression list
  | Etypetuple of type_expression list
  | Etypevec of type_expression * size
  | Etypefun of
      kind * bool * Ident.t option * type_expression * type_expression

and size = size_desc localized

and size_desc =
  | Sconst of int
  | Sglobal of Lident.t
  | Sname of Ident.t
  | Sop of size_op * size * size

and size_op = Splus | Sminus
		   
(** Declarations and expressions *)
type interface = interface_desc localized

and interface_desc =
  | Einter_open of name
  | Einter_typedecl of name * name list * type_decl
  | Einter_constdecl of name * type_expression
				 
and type_decl =
  | Eabstract_type
  | Eabbrev of type_expression
  | Evariant_type of name list
  | Erecord_type of (name * type_expression) list
					     
and implementation = implementation_desc localized

and implementation_desc =
  | Eopen of name
  | Etypedecl of name * name list * type_decl
  | Econstdecl of name * exp
  | Efundecl of name * funexp
			 
and funexp =
  { f_kind: kind;
    f_atomic: is_atomic;
    f_args: pattern list;
    f_body: exp;
    mutable f_env: Deftypes.tentry Ident.Env.t }
    
and is_atomic = bool
		  
and exp = 
  { mutable e_desc: desc;
    e_loc: location;
    mutable e_typ: Deftypes.typ;
    mutable e_caus: Defcaus.t list }
    
and desc =
  | Elocal of Ident.t
  | Eglobal of { lname : Lident.t; typ_instance : Deftypes.typ_instance }
  | Econst of immediate
  | Econstr0 of Lident.t
  | Elast of Ident.t
  | Eapp of app * exp * exp list
  | Eop of op * exp list
  | Etuple of exp list
  | Erecord_access of exp * Lident.t
  | Erecord of (Lident.t * exp) list
  | Etypeconstraint of exp * type_expression
  | Epresent of exp present_handler list * exp option
  | Ematch of total ref * exp * exp match_handler list
  | Elet of local * exp
  | Eseq of exp * exp
  | Eperiod of period
  | Eblock of eq list block * exp

and op =
  | Efby | Eunarypre | Eifthenelse 
  | Eminusgreater | Eup | Einitial | Edisc | Ehorizon
  | Eafter of Ident.t list | Etest | Eaccess

and immediate = Deftypes.immediate

and app = { app_inline: bool; app_statefull: bool}
				    
(* a period is an expression of the form [v] (v). E.g., 0.2 (3.4) or (4.5) *)
and period =
    { p_phase: float option;
      p_period: float }

and pattern =
    { mutable p_desc: pdesc;
      p_loc: location;
      mutable p_typ: Deftypes.typ;
      mutable p_caus: Defcaus.t list }

and pdesc =
  | Ewildpat
  | Econstpat of immediate
  | Econstr0pat of Lident.t
  | Etuplepat of pattern list
  | Evarpat of Ident.t
  | Ealiaspat of pattern * Ident.t
  | Eorpat of pattern * pattern
  | Erecordpat of (Lident.t * pattern) list
  | Etypeconstraintpat of pattern * type_expression

and eq = 
    { eq_desc: eqdesc;
      eq_loc: location;
      mutable eq_write: Deftypes.defnames }

and eqdesc =
  | EQeq of pattern * exp
  (* [p = e] *)
  | EQder of Ident.t * exp * exp option * exp present_handler list
  (* [der n = e [init e0] [reset p1 -> e1 | ... | pn -> en]] *)
  | EQinit of Ident.t * exp
  (* [init n = e0 *)
  | EQnext of Ident.t * exp * exp option
  (* [next n = e] *)
  | EQpluseq of Ident.t * exp
  (* [n += e] *)
  | EQautomaton of is_weak * state_handler list * state_exp option
  | EQpresent of eq list block present_handler list * eq list block option
  | EQmatch of total ref * exp * eq list block match_handler list
  | EQreset of eq list * exp
  | EQemit of Ident.t * exp option
  | EQblock of eq list block
  | EQpar of eq list (* eq1 and ... and eqn *)
  | EQseq of eq list (* eq1 before ... before eqn *)
  | EQforall of forall_handler (* forall i in ... do ... initialize ... done *)

and total = bool

and is_next = bool

and is_weak = bool

and 'a block =
    { b_vars: vardec list;
      b_locals: local list;
      b_body: 'a;
      b_loc: location;
      mutable b_env: Deftypes.tentry Ident.Env.t;
      mutable b_write: Deftypes.defnames }

and vardec =
    { vardec_name: Ident.t; (* its name *)
      vardec_default: Deftypes.constant default option;
      (* either an initial or a default value *)
      vardec_combine: Lident.t option; (* an optional combination function *)
      vardec_loc: location;
    }

and 'a default =
  | Init of 'a | Default of 'a


and local = 
    { l_eq: eq list;
      mutable l_env: Deftypes.tentry Ident.Env.t;
      l_loc: location }

and state_handler = 
    { s_loc: location;
      s_state: statepat; 
      s_body: eq list block; 
      s_trans: escape list;
      mutable s_env: Deftypes.tentry Ident.Env.t;
      mutable s_reset: bool } 

and statepat = statepatdesc localized 

and statepatdesc = 
    | Estate0pat of Ident.t 
    | Estate1pat of Ident.t * Ident.t list

and state_exp = state_exdesc localized 

and state_exdesc = 
    | Estate0 of Ident.t
    | Estate1 of Ident.t * exp list

and escape = 
    { e_cond: scondpat; 
      e_reset: bool; 
      e_block: eq list block option;
      e_next_state: state_exp;
      mutable e_env: Deftypes.tentry Ident.Env.t;
      mutable e_zero: bool } 

and scondpat = scondpat_desc localized

and scondpat_desc =
    | Econdand of scondpat * scondpat
    | Econdor of scondpat * scondpat
    | Econdexp of exp
    | Econdpat of exp * pattern
    | Econdon of scondpat * exp

and is_on = bool

and 'a match_handler =
    { m_pat: pattern;
      m_body: 'a;
      mutable m_env: Deftypes.tentry Ident.Env.t;
      m_reset: bool; (* the handler is reset on entry *)
      mutable m_zero: bool; (* the handler is done at a zero-crossing instant *)
    }

(* the body of a present handler *)
and 'a present_handler =
    { p_cond: scondpat;
      p_body: 'a;
      mutable p_env: Deftypes.tentry Ident.Env.t;
      mutable p_zero: bool }

(* the body of a for loop *)
(* for(all|seq) [id in e..e | id in e[at id] | id out id]+
 *   local id [and id]*
 *   do eq and ... and eq
 *   [init
 *     [[id = e with g] | [last id = e]]
 *     [and [[id = e with g] | [last id = e]]]*
 *   done *)
and forall_handler =
  { for_index: indexes_desc localized list;
    for_init: init_desc localized list;
    for_body: eq list block;
    mutable for_in_env: Deftypes.tentry Ident.Env.t;
    (* def names from [id in e | id in e1..e2] *)
    mutable for_out_env: Deftypes.tentry Ident.Env.t;
    (* def (left) names from [id ou id'] *) }

and indexes_desc =
  | Einput of Ident.t * exp
  | Eoutput of Ident.t * Ident.t
  | Eindex of Ident.t * exp * exp

and init_desc =
  | Einit_last of Ident.t * exp
  | Einit_value of Ident.t * exp * Lident.t option
					 

