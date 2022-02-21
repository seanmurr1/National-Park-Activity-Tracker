(* Information regarding a park, used for querying Twitter API and updating DB *)
type park_info = {
  utc_offset: int;
  geocode: string;
  aliases : string list;
}

(* List of currently supported National Parks *)
val parks : string list

(* Checks if a given string is included in the list of currently supported parks *)
val is_allowed_park : string -> bool

(* 
Obtains park info for a given park
Assumes valid park name will be passed 
*)
val get_park_info : string -> park_info