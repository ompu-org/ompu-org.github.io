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
  let path = "https://script.google.com/macros/s/AKfycbzXwzQ-niX0v8SdnCb3o6yR7dM6yyYTnGdiFFBjzHydVv9kqrQ1-D937Dy1wBZ-uxtL2w/exec" in
  let query = Url.encode_arguments [ ("type", "save"); ("abc", abctext); ("callback", "f") ] in
  let url = !%"%s?%s" path query in
  Console.console##log (!%"jsonp: %s" url);
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

(* ===== ABC parsing for unit note length ===== *)

let rec gcd a b = if b = 0 then a else gcd b (a mod b)

let scan_int s i =
  let n = String.length s in
  let j = ref i in
  while !j < n && s.[!j] >= '0' && s.[!j] <= '9' do incr j done;
  if !j = i then None
  else Some (int_of_string (String.sub s i (!j - i)), !j)

let find_abc_field s field_char =
  let n = String.length s in
  let rec scan i =
    if i + 2 > n then None
    else if s.[i] = field_char && s.[i + 1] = ':' &&
            (i = 0 || s.[i - 1] = '\n') then begin
      let j = ref (i + 2) in
      while !j < n && s.[!j] = ' ' do incr j done;
      match scan_int s !j with
      | None -> scan (i + 1)
      | Some (num, k) ->
        if k < n && s.[k] = '/' then
          (match scan_int s (k + 1) with
           | None -> Some (num, 1)
           | Some (den, _) -> Some (num, den))
        else Some (num, 1)
    end
    else scan (i + 1)
  in
  scan 0

(* Read L: field, or infer from M: if absent *)
let get_unit_note_length text =
  match find_abc_field text 'L' with
  | Some (num, den) -> (num, den)
  | None ->
    match find_abc_field text 'M' with
    | Some (mnum, mden) ->
      let ratio = float_of_int mnum /. float_of_int mden in
      if ratio < 0.75 then (1, 16) else (1, 8)
    | None -> (1, 8)

let duration_suffix lnum lden tnum tden =
  let p = tnum * lden in
  let q = tden * lnum in
  let g = gcd p q in
  let p = p / g in
  let q = q / g in
  if q = 1 then (if p = 1 then "" else string_of_int p)
  else if p = 1 && q land (q - 1) = 0 then
    let rec slash q acc = if q <= 1 then acc else slash (q / 2) (acc ^ "/") in
    slash q ""
  else if p = 1 then "/" ^ string_of_int q
  else string_of_int p ^ "/" ^ string_of_int q

(* ===== Mobile Keyboard UI ===== *)

(* State: cursor position, note duration, octave offset *)
let last_cursor_pos = ref 0
let current_dur_num = ref 1
let current_dur_den = ref 4
let current_octave  = ref 0

let dur_btns       : Dom_html.buttonElement Js.t list  ref = ref []
let white_key_btns : Dom_html.buttonElement Js.t array ref = ref [||]
let black_key_btns : Dom_html.buttonElement Js.t array ref = ref [||]

let build_note letter sharp suffix =
  let prefix = if sharp then "^" else "" in
  let base, extra =
    if !current_octave >= 1 then
      String.lowercase_ascii letter,
      String.make (max 0 (!current_octave - 1)) '\''
    else
      String.uppercase_ascii letter,
      String.make (max 0 (- !current_octave)) ','
  in
  prefix ^ base ^ extra ^ suffix

let note_text abc_text letter sharp =
  let (lnum, lden) = get_unit_note_length abc_text in
  let suf = duration_suffix lnum lden !current_dur_num !current_dur_den in
  build_note letter sharp suf

let get_button id =
  Dom_html.getElementById_coerce id Dom_html.CoerceTo.button
  |> Option.get

let update_key_labels () =
  let text = Js.to_string (get_textarea ())##.value in
  let whites = [| "C"; "D"; "E"; "F"; "G"; "A"; "B" |] in
  let blacks = [| "C"; "D"; "F"; "G"; "A" |] in
  Array.iteri (fun i btn ->
    btn##.innerText := js (note_text text whites.(i) false)
  ) !white_key_btns;
  Array.iteri (fun i btn ->
    btn##.innerText := js (note_text text blacks.(i) true)
  ) !black_key_btns

let redraw () =
  let text = (get_textarea ())##.value in
  draw text;
  set_twbutton (Js.to_string text);
  update_key_labels ()

let onkeyup _event =
  redraw ();
  Js._false

let insert_note letter sharp =
  let ta = get_textarea () in
  let text = Js.to_string ta##.value in
  let note = note_text text letter sharp in
  let n = String.length text in
  let pos = min !last_cursor_pos n in
  ta##.value := js (String.sub text 0 pos ^ note ^ String.sub text pos (n - pos));
  last_cursor_pos := pos + String.length note;
  redraw ()

let setup_dur_buttons () =
  let durations = [("1", 1, 1); ("2", 1, 2); ("4", 1, 4); ("8", 1, 8); ("16", 1, 16)] in
  List.iter (fun (den_str, tnum, tden) ->
    let btn = get_button ("dur-" ^ den_str) in
    btn##.onclick := Dom_html.handler (fun _ ->
      List.iter (fun b ->
        b##.className := js "btn btn-outline-secondary dur-btn"
      ) !dur_btns;
      btn##.className := js "btn btn-outline-secondary dur-btn active";
      current_dur_num := tnum;
      current_dur_den := tden;
      update_key_labels ();
      Js._false
    );
    dur_btns := !dur_btns @ [btn]
  ) durations

let setup_oct_buttons () =
  let oct_down = get_button "oct-down" in
  let oct_disp = get_button "oct-disp" in
  let oct_up   = get_button "oct-up" in
  oct_down##.onclick := Dom_html.handler (fun _ ->
    if !current_octave > -2 then begin
      decr current_octave;
      oct_disp##.innerText := js (string_of_int !current_octave);
      update_key_labels ()
    end;
    Js._false
  );
  oct_up##.onclick := Dom_html.handler (fun _ ->
    if !current_octave < 2 then begin
      incr current_octave;
      oct_disp##.innerText := js (string_of_int !current_octave);
      update_key_labels ()
    end;
    Js._false
  )

let setup_piano () =
  let whites = [| "C"; "D"; "E"; "F"; "G"; "A"; "B" |] in
  white_key_btns := Array.map (fun letter ->
    let btn = get_button ("wk-" ^ letter) in
    btn##.onclick := Dom_html.handler (fun _ ->
      insert_note letter false; Js._false
    );
    btn
  ) whites;
  let blacks = [| "C"; "D"; "F"; "G"; "A" |] in
  black_key_btns := Array.map (fun letter ->
    let btn = get_button ("bk-" ^ letter) in
    btn##.onclick := Dom_html.handler (fun _ ->
      insert_note letter true; Js._false
    );
    btn
  ) blacks

let setup_keyboard () =
  setup_dur_buttons ();
  setup_oct_buttons ();
  setup_piano ();
  update_key_labels ()

(* ============================= *)

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
  (get_textarea())##.onblur := Dom_html.handler (fun _ ->
    last_cursor_pos := (get_textarea ())##.selectionStart;
    Js._false
  );
  (get_textarea())##.onclick := Dom_html.handler (fun _ ->
    last_cursor_pos := (get_textarea ())##.selectionStart;
    Js._true
  );

  (* copy button *)
  set_copybutton ();

  (* Tweetボタンの設置 *)
  set_twbutton text;
  setup_keyboard ();
  Js._false

let () =
  Dom_html.window##.onload := Dom_html.handler onload
