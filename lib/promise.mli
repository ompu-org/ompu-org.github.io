type 'a t

val resolve : 'a -> 'a t

val all : 'a t array -> 'a array t

val then_ : ('a -> 'b) -> 'a t -> 'b t

val bind : ('a -> 'b t) -> 'a t -> 'b t
