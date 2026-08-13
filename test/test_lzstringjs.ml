open Js_of_ocaml
open Ompu_lib

let js = Js.string

(* Regression test for the mojibake bug: Lzstringjs.compress_to_base64 /
   decompress_from_base64 operate on real JS (UTF-16) strings. Passing a raw
   OCaml (UTF-8) string in, or forgetting to convert the JS string back out
   with [Js.to_string], silently corrupts any non-ASCII text such as
   Japanese titles while leaving ASCII text untouched. *)

let japanese_title = "T:時代の風 紅の豚 フルート四重奏 Edur"

let multi_voice_abc =
  {|X:1
T:穏やかな午後
K:C
M:3/4
V:Fl name="フルート"
V:Vc name="チェロ"
[V:Fl] e3g ec| d3 g dB|
[V:Vc] c6-|  c6|
|}

let check_roundtrip name original =
  let compressed = Lzstringjs.compress_to_base64 (js original) in
  let decompressed = Lzstringjs.decompress_from_base64 compressed |> Js.to_string in
  Alcotest.(check string) name original decompressed

let test_ascii () = check_roundtrip "ascii abc roundtrips" "K:D\nM:2/4\nCDEF|"

let test_japanese_title () = check_roundtrip "japanese title roundtrips" japanese_title

let test_multi_voice_japanese () =
  check_roundtrip "multi-voice abc with japanese roundtrips" multi_voice_abc

let () =
  Alcotest.run "ompu_lib"
    [ ( "lzstringjs"
      , [ Alcotest.test_case "ascii roundtrip" `Quick test_ascii
        ; Alcotest.test_case "japanese title roundtrip" `Quick test_japanese_title
        ; Alcotest.test_case "multi-voice japanese roundtrip" `Quick
            test_multi_voice_japanese
        ] )
    ]
