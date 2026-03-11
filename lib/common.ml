
let option_or x y =
  match x, y with
  | Some a, _ -> Some a
  | None, y -> y
