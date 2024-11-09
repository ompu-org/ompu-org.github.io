open Js_of_ocaml
open Ompu_lib

let document = Dom_html.window##.document
let js = Js.string

let gen_id =
  let global_count = ref 0 in
  fun () ->
  let n = !global_count in
  global_count := !global_count + 1;
  Printf.sprintf "content_%d" n

(*let elem tag text =
  let e = Dom_html.createElement tag in
  e##.innerHTML := text;
  e
*)

let get_textarea () =
  match Dom_html.getElementById_coerce "text" Dom_html.CoerceTo.textarea with
  | Some textarea -> textarea
  | None ->
     Firebug.console##log (js "HOGE===");
     Firebug.console##log (Dom_html.getElementById "text");
     failwith "get_textarea"

let draw text =
(*    let display = Dom_html.getElementById_exn "display" in*)
  Abcjs.renderAbc "display" (text) |> ignore

let clearText () =
  let textarea = get_textarea () in
  textarea##.value := js"";
  draw (js"")

let addItem (text: Js.js_string Js.t) =
  let id = gen_id () in
  let notes =
      let notes = Dom_html.createDiv document in
      notes##.id := js"disp";
      notes
  in
  let div =
    let label = Dom_html.createLabel document in
    let name = "花子" in
    label##.innerText := js (name ^ ": " ^ Js.to_string ((new%js Js.date_now)##toString));
    let div = Dom_html.createDiv document in
    Dom.appendChild div label;
    div##.id := js id;
    div##setAttribute (js "data") text;
    Dom.appendChild div notes;
    div
  in
  let history = Dom_html.getElementById_exn "history" in
  Dom.appendChild history div;
  Abcjs.renderAbc notes text |> ignore

let onkeyup _event =
  let text = (get_textarea())##.value in
  draw text;
  Js._false


let post text =
  addItem text;
  clearText()



let onload _event =
  (* 現在のテキストエリアの楽譜をレンダリングする *)
  let text = (get_textarea())##.value in
  draw text;
  (* テキストエリアが書き換わったらリアルタイムでレンダリングし直す *)
  (get_textarea())##.onkeyup := Dom_html.handler onkeyup;
  (* ボタンが押されたら投稿する *)
  let button = Dom_html.getElementById_exn "ok" in
  button##.onclick := Dom_html.handler (fun _event ->
                          let text = (get_textarea())##.value in
                          post text; Js._false);
  Js._false

let () =
  Dom_html.window##.onload := Dom_html.handler onload



let () =
  let _ = clearText in
  let _ = addItem in
  let _ = gen_id  in
()
