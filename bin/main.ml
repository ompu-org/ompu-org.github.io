open Js_of_ocaml
open Ompu_lib
module Jsonp = Js_of_ocaml_lwt.Jsonp
open Js

let js = Js.string

let get_params () : (string * string) list = Url.Current.arguments
let query params = List.assoc_opt "q" params


let get_textarea () =  match Dom_html.getElementById_coerce "text" Dom_html.CoerceTo.textarea with
  | Some textarea -> textarea
  | None -> failwith "get_textarea"

let copy_button =
  Dom_html.getElementById_coerce "copy" Dom_html.CoerceTo.a
  |> Option.get

let tw_button =
  Dom_html.getElementById_coerce "tweet" Dom_html.CoerceTo.a
  |> Option.get

let draw text =
  let options = [("responsive", js"resize")] in
  Abcjs.renderAbc "display" (text) options |> ignore;
  Abcjs.renderMidi "midi" text

let tw_url text =
  let hashtag = "ompuOrg" in
  let body = Printf.sprintf "譜面をみる → " in
  let link =
    let query =
      Url.encode_arguments [("q", text)]
    in
    let base = "www.ompu.org" in
    "https://" ^ base ^ "?" ^ query
  in
  Tweet_button.post_url ~link ~hashtag body

let fetch url = Jsonp.call url

let save_storage abctext =
  Firebug.console##log (Printf.sprintf "save storage : %s" abctext);
  let url = Printf.sprintf "https://script.google.com/macros/s/AKfycbwG34ku1-gMygQHpbfzyf9dBPiMWKNCEOBMXRrlc0ghjpKiW_-iovtr1neyqr19RgTbxw/exec?type=save&abc=%s&callback=f" abctext in
  fetch url
  |> ignore

let navigator = Unsafe.pure_js_expr "navigator"

let onclick_copy abctext _event =
  ignore @@ (navigator##.clipboard##writeText abctext);
  save_storage abctext;
  Js._false

let set_copybutton abctext =
  copy_button##.onclick := Dom_html.handler (onclick_copy abctext)

let set_twbutton abctext =
  let link = tw_url abctext in
  tw_button##.href := (js link)

let onkeyup _event =
  let text = (get_textarea())##.value in
  draw text;
  set_twbutton (Js.to_string text);
  Js._false

let default_text = {|K:D
Q:"Allegro" 1/4=152
M:2/4
L.a2(fa L.^g2)(^gf| L.a2)(a^g fdfg |L.a2)(fa L.^g2)(^gf|L.e2)(ed e4)|
|}

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

  (* copy button *)
  save_storage text;
  set_copybutton text;

  (* Tweetボタンの設置 *)
  set_twbutton text;
  Js._false

let () =
  Dom_html.window##.onload := Dom_html.handler onload
