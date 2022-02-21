(* Tweet ID, Park Name, Date, Hour *)
(* Formatted as tuple since Caqti expects tuples to be inserted into DB *)
type tweet_tuple = int * string * string * int

(* Park Name, Date, Hour, Tweet Count *)
(* Formatted as tuple since Caqti expects tuples to be inserted into DB *)
type count_tuple = string * string * int * int

(* 
Parses JSON of tweets returned from twitter API general search into list of tuples able to be inserted into DB. 
Consolidates tweets into tuples consisting of tweet id, park name, date, and hour.
Time is adjusted to be local to given park. 
Also returns the id of the latest tweet in search (this helps to optimize further API calls)
*)
val parse_tweet_search : string -> (Yojson.Basic.t, unit) result -> (tweet_tuple list * int, unit) result 
 
(* 
Parses JSON of tweets returned from twitter API tweet count search into list of tuples able to be inserted into DB. 
Consolidates tweets into tuples consisting of park name, date, hour, and count.
Time is adjusted to be local to given park. 
*)
val parse_tweet_counts : string -> (Yojson.Basic.t, unit) result -> (count_tuple list, unit) result 
 