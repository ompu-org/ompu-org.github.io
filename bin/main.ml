open Js_of_ocaml
open Ompu_lib

let js = Js.string

let get_params () : (string * string) list = Url.Current.arguments
let query params = List.assoc_opt "q" params

let get_textarea () =
  match Dom_html.getElementById_coerce "text" Dom_html.CoerceTo.textarea with
  | Some textarea -> textarea
  | None -> failwith "get_textarea"

let draw text =
  let options = [("responsive", js"resize")] in
  Abcjs.renderAbc "display" (text) options |> ignore;
  Abcjs.renderMidi "midi" text

let tw_btn text =
  let button_text = "この楽譜をツイートする" in
  let hashtag = "ompuOrg" in
  let body = Printf.sprintf "譜面をみる → " in
  let link =
    let query =
      Url.encode_arguments [("q", text)]
    in
    let base = "www.ompu.org" in
    "https://" ^ base ^ "?" ^ query
  in
  Tweet_button.post_button ~link ~hashtag body button_text

let set_twbutton abctext =
  (Dom_html.getElementById_exn "tweet")##.innerHTML := js (tw_btn abctext)

let onkeyup _event =
  let text = (get_textarea())##.value in
  draw text;
  set_twbutton (Js.to_string text);
  Js._false

let default_text = "(FAd6)| (=cAE6) | (FAdc edBc) | A4 E4|"

let onload _event =
  let text =
    match query (get_params ()) with
    | None -> default_text
    | Some q -> q
  in
  (get_textarea())##.value := js text;
  (* 現在のテキストエリアの楽譜をレンダリングする *)
  draw (js text);

  (* テキストエリアが書き換わったらリアルタイムでレンダリングし直す *)
  (get_textarea())##.onkeyup := Dom_html.handler onkeyup;

  (* Tweetボタンの設置 *)
  set_twbutton text;
  Js._false

let () =
  Dom_html.window##.onload := Dom_html.handler onload
