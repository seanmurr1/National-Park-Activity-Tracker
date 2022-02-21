(* 
Obtains JSON response from Twitter API.
Calls Twitter's tweet count API to obtain counts of 
tweets related to a given national park per hour.
Does not restrict location. This is meant to obtain
info regarding general activity about a park, worldwide.
*)
val tweet_counts : string -> (Yojson.Basic.t, unit) Core.result Lwt.t

(* 
Obtains JSON response from Twitter API.
Calls Twitter's recent tweet search API to recent
tweets related to a given national park, that
were posted within that park.
*)
val search_tweets : string -> (Yojson.Basic.t, unit) Core.result Lwt.t