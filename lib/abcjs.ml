open Js_of_ocaml
open Js

let renderAbc elem abc_string =
  Unsafe.meth_call (Unsafe.pure_js_expr "ABCJS") "renderAbc" [|Unsafe.inject elem; Unsafe.inject abc_string |]
