open Js_of_ocaml
open Js

let compress_to_base64 str =
  Unsafe.meth_call (Unsafe.pure_js_expr "LZString") "compressToBase64"
    [|Unsafe.inject str; |]

let decompress_from_base64 str =
  Unsafe.meth_call (Unsafe.pure_js_expr "LZString") "decompressFromBase64"
    [|Unsafe.inject str; |]

let compress_to_utf16 str =
  Unsafe.meth_call (Unsafe.pure_js_expr "LZString") "compressToUTF16"
    [|Unsafe.inject str; |]

let decompress_from_utf16 str =
  Unsafe.meth_call (Unsafe.pure_js_expr "LZString") "decompressFromUTF16"
    [|Unsafe.inject str; |]
