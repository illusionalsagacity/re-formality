open Ppxlib
open Ast_helper

(* Wrap a function expression with Function$ constructor and res.arity attribute
   to mark it as uncurried with the given arity. This is the standard approach
   used by ReScript PPXs to generate uncurried functions. *)
let fn ~loc ~arity fx =
  let arity_attr : Parsetree.attribute =
    { attr_name = { txt = "res.arity"; loc = Location.none }
    ; attr_payload =
        PStr [ Str.eval (Exp.constant (Pconst_integer (string_of_int arity, None))) ]
    ; attr_loc = loc
    }
  in
  Exp.construct
    ~loc
    ~attrs:[ arity_attr ]
    { txt = Longident.Lident "Function$"; loc = Location.none }
    (Some fx)
;;

(* Wrap a type with function$ and arity marker for uncurried function types *)
let ty ~loc ~arity t_arg =
  let encode_arity_string arity = "Has_arity" ^ string_of_int arity in
  let arity_type =
    Typ.variant
      ~loc
      [ { prf_loc = loc
        ; prf_attributes = []
        ; prf_desc = Rtag ({ txt = encode_arity_string arity; loc }, true, [])
        }
      ]
      Closed
      None
  in
  Typ.constr ~loc { txt = Longident.Lident "function$"; loc } [ t_arg; arity_type ]
;;

(* The res.uapp attribute is still used to mark uncurried function applications *)
let uapp : Parsetree.attribute =
  { attr_name = { txt = "res.uapp"; loc = Location.none }
  ; attr_payload = PStr []
  ; attr_loc = Location.none
  }
;;
