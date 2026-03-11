open Js_of_ocaml
open Ompu_lib
open Common
module Jsonp = Js_of_ocaml_lwt.Jsonp
open Js
module List = Stdlib.List

let js = Js.string

let get_params () : (string * string) list = Url.Current.arguments
let query params = List.assoc_opt "q" params
let zquery params = List.assoc_opt "z" params


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
  let compressed = Lzstringjs.compress_to_base64 text in
  let hashtag = "ompuOrg" in
  let body = Printf.sprintf "譜面をみる → " in
  let link =
    let query =
      Url.encode_arguments [("z", compressed)]
    in
    let base = "www.ompu.org" in
    "https://" ^ base ^ "?" ^ query
  in
  Tweet_button.post_url ~link ~hashtag body

let fetch url = Jsonp.call url

let save_storage abctext =
  let url = Printf.sprintf "https://script.google.com/macros/s/AKfycbwG34ku1-gMygQHpbfzyf9dBPiMWKNCEOBMXRrlc0ghjpKiW_-iovtr1neyqr19RgTbxw/exec?type=save&abc=%s&callback=f" abctext in
  fetch url
  |> ignore

let navigator = Unsafe.pure_js_expr "navigator"

let zquery_of_abc abctext =
  let compressed = Lzstringjs.compress_to_base64 abctext in
  Url.encode_arguments [("z", compressed)]

let get_location_url () =
  Dom_html.window##.location##.href
  |> Js.to_string

let set_address_bar zquery =
  let path = "/?" ^ zquery in
  Console.console##log (Printf.sprintf "set_address_bar '%s'" path);
  let empty = object%js end in (* {} *)
  Dom_html.window##.history##pushState empty (Js.string "") (Js.Opt.return (Js.string path))

let onclick_copy _event =
  let abctext = (get_textarea())##.value |> Js.to_string in
  let zquery = zquery_of_abc abctext in
  set_address_bar zquery;
  let url = get_location_url () in
  ignore @@ (navigator##.clipboard##writeText url);
  save_storage abctext;
  Js._false

let set_copybutton () =
  copy_button##.onclick := Dom_html.handler (onclick_copy)

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
    let ps = get_params () in
    option_or
      (zquery ps |> Option.map Lzstringjs.decompress_from_base64)
      (query ps)
    |> Option.value ~default:default_text
  in
  (get_textarea())##.value := js text;
  (* 現在のテキストエリアの楽譜をレンダリングする *)
  draw (js text);

  (* テキストエリアが書き換わったらリアルタイムでレンダリングし直す *)
  (get_textarea())##.onkeyup := Dom_html.handler onkeyup;

  (* copy button *)
  set_copybutton ();

  (* Tweetボタンの設置 *)
  set_twbutton text;
  Js._false

let () =
  Dom_html.window##.onload := Dom_html.handler onload
