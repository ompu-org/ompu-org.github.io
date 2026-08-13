(* Capture the sibling Promise module before [open Js_of_ocaml], since some
   js_of_ocaml versions ship their own Promise module that would otherwise
   shadow it below and make this file's Promise.t incompatible with the
   Ompu_lib.Promise.t expected by callers such as bin/list.ml. *)
module Local_promise = Promise

open Js_of_ocaml
module Promise = Local_promise

class type response = object
  method json : _ Promise.t Js.meth
  method text : Js.js_string Js.t Promise.t Js.meth
end

let fetch (url : string) : _ Js.t Promise.t =
  Js.Unsafe.fun_call (Js.Unsafe.js_expr "fetch") [|Js.Unsafe.inject url|]

let fetch_json (url : string) : _ Js.t Promise.t =
  fetch url |> Promise.bind (fun res -> res##json)

let fetch_text (url : string) : Js.js_string Js.t Promise.t =
  fetch url |> Promise.bind (fun res -> res##text)
