open Js_of_ocaml
open Ompu_lib

(*let document = Dom_html.window##.document
let js = Js.string
*)
let get_textarea () =
  match Dom_html.getElementById_coerce "text" Dom_html.CoerceTo.textarea with
  | Some textarea -> textarea
  | None -> failwith "get_textarea"

let draw text =
  Abcjs.renderAbc "display" (text) |> ignore

let onkeyup _event =
  let text = (get_textarea())##.value in
  draw text;
  Js._false

let onload _event =
  (* 現在のテキストエリアの楽譜をレンダリングする *)
  let text = (get_textarea())##.value in
  draw text;
  (* テキストエリアが書き換わったらリアルタイムでレンダリングし直す *)
  (get_textarea())##.onkeyup := Dom_html.handler onkeyup;
  Js._false

let () =
  Dom_html.window##.onload := Dom_html.handler onload
