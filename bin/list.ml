open Js_of_ocaml
open Ompu_lib
open Js
module List = Stdlib.List

let js = Js.string

type content = {
    id: js_string t;
    abc: js_string t;
    datetime: float;
}

let contents_div =
  Dom_html.getElementById_coerce "contents" Dom_html.CoerceTo.div
  |> Option.get

let _testdiv =
  Dom_html.getElementById_coerce "test" Dom_html.CoerceTo.div
  |> Option.get

(* こういうやつをつくる
        <div class="col">
          <div class="card shadow-sm">
            <svg class="card-img-top" width="100%" height="225">
              <div id="[ID]"></div>
            </svg>
            <div class="card-body">
              <p class="card-text">aaaabc</p>
              <div class="d-flex justify-content-between align-items-center">
                <div class="btn-group">
                  <button type="button" class="btn btn-sm btn-outline-secondary">View</button>
                  <button type="button" class="btn btn-sm btn-outline-secondary">♡</button>
                </div>
                <small class="text-body-secondary">9 mins</small>
              </div>
            </div>
          </div>
        </div>
*)
let content cont =
  let open Html_util in
  let id, abctext, _datetime = Js.to_string cont.id, cont.abc, cont.datetime in
  let canvas = div ~id [] in
  div ~class_:"col" [
      div ~class_:"card shadow-sm" [
          div ~class_:"card-img-top" ~attrs:[] [ canvas ];
          div ~class_:"card-body" [
              p ~class_:"card-text" (abctext);
              div ~class_:"d-flex justify-content-between align-items-center" [
                  div ~class_:"btn-group" [
                      button ~class_:"btn btn-sm btn-outline-secondary" (js "View");
                      button ~class_:"btn btn-sm btn-outline-secondary" (js "♡");
                    ]
                ]
            ]
        ]
    ]

(* {"data": [{"datetime":111111, "user": "Taro", "abc":"AaBC"}]} みたいな形式 *)
let parse json =
  let open Js.Optdef in
  let (>>=) = Js.Optdef.bind in
  let rec sequence = function
    | [] -> return []
    | m :: ms ->
       m  >>= fun x ->
       sequence ms >>= fun xs ->
       return (x :: xs)
  in
  begin
    json##.data >>= fun contents ->
    Js.to_array contents
    |> Array.to_list
    |> List.map (fun c ->
           c##.datetime >>= fun datetime ->
           c##.abc >>= fun abc ->
(*           c##.id >>= fun id ->*)
           let id = js (string_of_float datetime) in (*一旦時刻をidとする*)
           Firebug.console##log datetime;
           Firebug.console##log abc;
           return {id; datetime; abc}
         )
    |> sequence
  end
  |> fun o -> Optdef.get o (fun () -> failwith "parse")

let showAbc div abctext =
  let options = [("responsive", js"resize")] in
  Abcjs.renderAbc div (abctext) options |> ignore

let find () =
  let url = "https://script.google.com/macros/s/AKfycbyHMIhVOJ9u97WVqm29tQuQPQwpJLJuwCZD5sm6TWCPvzpPH1LWamWYbmQkB1BfU6mxQw/exec?type=load" in
  Fetch.fetch_json url
  |> Promise.then_ (fun json ->
         let contents = parse json in
         let cont0 = List.hd contents in
         showAbc "display" cont0.abc;
         contents
  )

let onload _event =
  find ()
  |> Promise.then_ (fun contents ->
         contents_div##.innerHTML := js"";
         List.iter (fun (cont) ->
             Dom.appendChild contents_div (content cont);
             showAbc cont.id cont.abc
           ) contents)
  |> ignore;
  Js._false

let () =
  Dom_html.window##.onload := Dom_html.handler onload
