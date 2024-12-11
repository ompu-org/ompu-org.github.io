open Js_of_ocaml

let document = Dom_html.document
let js = Js.string

let set_id_class elem id_opt class_opt attrs_opt =
  Option.iter (fun id -> elem##.id := js id) id_opt;
  Option.iter (fun cls -> elem##.className := js cls) class_opt;
  Option.iter (fun attrs ->
      List.iter (fun (k,v) -> elem##setAttribute k v) attrs) attrs_opt


let div ?id ?class_ ?attrs children =
  let elem = Dom_html.createDiv document in
  set_id_class elem id class_ attrs;
  List.iter (fun child -> Dom.appendChild elem child) children;
  elem

let p ?id ?class_ ?attrs text =
  let elem = Dom_html.createP document in
  set_id_class elem id class_ attrs;
  elem##.innerText := text;
  elem

let canvas ?id ?class_ ?attrs () =
  let elem = Dom_html.createCanvas document in
  set_id_class elem id class_ attrs;
  elem

let button ?id ?class_ ?attrs text =
  let elem = Dom_html.createButton document in
  set_id_class elem id class_ attrs;
  elem##.innerText := text;
  elem
