open Js_of_ocaml
open Js

(* LZString operates on real JS (UTF-16) strings. Typing these as
   [js_string t] end to end (rather than leaving them polymorphic) forces
   callers to convert at the OCaml/JS boundary with [Js.string]/[Js.to_string]
   instead of accidentally feeding it a raw OCaml (UTF-8) string, which
   corrupts any non-ASCII text (e.g. Japanese titles) silently. *)

let compress_to_base64 (str : js_string t) : js_string t =
  Unsafe.meth_call (Unsafe.pure_js_expr "LZString") "compressToBase64"
    [|Unsafe.inject str; |]

let decompress_from_base64 (str : js_string t) : js_string t =
  Unsafe.meth_call (Unsafe.pure_js_expr "LZString") "decompressFromBase64"
    [|Unsafe.inject str; |]

let compress_to_utf16 (str : js_string t) : js_string t =
  Unsafe.meth_call (Unsafe.pure_js_expr "LZString") "compressToUTF16"
    [|Unsafe.inject str; |]

let decompress_from_utf16 (str : js_string t) : js_string t =
  Unsafe.meth_call (Unsafe.pure_js_expr "LZString") "decompressFromUTF16"
    [|Unsafe.inject str; |]
