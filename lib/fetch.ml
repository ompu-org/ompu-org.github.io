open Js_of_ocaml

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
