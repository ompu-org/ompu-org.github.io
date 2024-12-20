open Js_of_ocaml

let post_url ?link ?hashtag text =
  let params =
    (Option.to_list @@ Option.map (fun tag -> ("hashtags", tag)) hashtag)
    @ (Option.to_list @@ Option.map (fun link -> ("url", link)) link)
    @ [("text", text)]
  in
  let sparam = Url.encode_arguments params in
  Printf.sprintf "https://twitter.com/intent/tweet?%s" sparam

let post_button ?link ?hashtag text button_text =
  let url = post_url ?link ?hashtag text in
  Printf.sprintf {|<a target="_blank" href="%s" class="twitter-share-button">%s</a><script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>|} url button_text
