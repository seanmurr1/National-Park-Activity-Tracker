(* Connection to DB *)
val pool : (Caqti_lwt.connection, [> Caqti_error.connect]) Caqti_lwt.Pool.t