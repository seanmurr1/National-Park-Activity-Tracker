(* 
Represents entry in counts table
Stores info about tweet counts per hour for a given national park
*)
type tweet_count = {
  date: Core.Date.t;
  hour: int;
  count: int
} 

(* Creates all tables in DB *)
val create : unit -> (unit, unit) result Lwt.t

(* Updates all tables for all supported parks *)
val update_db : unit -> (unit, unit) result Lwt.t

(* 
Gets all raw db info for a given park
Logs errors
*)
val get_park : string -> (tweet_count list * tweet_count list, unit) result Lwt.t