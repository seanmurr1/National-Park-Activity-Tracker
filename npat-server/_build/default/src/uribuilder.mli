(* Get full URI for calling Twitter tweet counts API *)
val twitter_counts_uri : string -> string 

(* Get full URI for calling Twitter recent search API*)
val twitter_search_uri : string -> string Lwt.t

(* Authorization header to call Twitter API endpoints *)
val twitter_header : Cohttp.Header.t