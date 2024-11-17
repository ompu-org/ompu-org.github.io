open Js_of_ocaml
open Js

let renderAbc elem abc_string options =
  let options =
    List.map(fun (key,v) -> (key, Unsafe.inject v)) options |> Array.of_list
    |> Unsafe.obj
  in
  Unsafe.meth_call (Unsafe.pure_js_expr "ABCJS") "renderAbc" [|Unsafe.inject elem; Unsafe.inject abc_string; Unsafe.inject options |]
