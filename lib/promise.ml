open Js_of_ocaml

type 'a t

let resolve (promise : 'a) : 'a t =
  Js.Unsafe.fun_call (Js.Unsafe.js_expr "Promise.resolve") [|Js.Unsafe.inject promise|]

let all (promises : 'a t array) : 'a array t =
  Js.Unsafe.fun_call (Js.Unsafe.js_expr "Promise.all") [|Js.Unsafe.inject promises|]

let then_ (f : 'a -> 'b) (promise : 'a t) : 'b t =
  Js.Unsafe.meth_call promise "then" [|Js.Unsafe.inject f|]

let bind (f : 'a -> 'b t) (promise : 'a t) : 'b t =
  Js.Unsafe.meth_call promise "then" [|Js.Unsafe.inject f|]
