open Core
open Cohttp
open Lwt
open Syntax

let twitter_bearer = "AAAAAAAAAAAAAAAAAAAAAK9ZWAEAAAAAj1PppVh5iqeCw4I5Ht9a%2BjOGU%2FQ%3D3HxIPanebUly1OOlomBXhhdlwOsAd80syuZLCYW4tUf0B5DKAA"
let twitter_counts_base = "https://api.twitter.com/2/tweets/counts/recent"
let twitter_search_base = "https://api.twitter.com/1.1/search/tweets.json"
let twitter_header = Header.add (Header.init ()) "Authorization" ("Bearer " ^ twitter_bearer)

(* Obtains string to append to API call to limit search to specific geographic location of given park *)
let get_geocode (park_name : string) : string = 
  let park_info = park_name |> Parks.get_park_info in 
  "&geocode=" ^ park_info.geocode

(* Obtains string to append to API call to query for tweets related to a specific park and its aliases *)
let get_query (park_name : string) : string = 
  let aliases = (park_name |> Parks.get_park_info).aliases in 
  aliases |> List.map ~f:(fun alias -> "(" ^ alias ^ ")") |> String.concat ~sep:"OR"

(* Connection to DB *)
let pool = Dbconnection.pool

(* Query to get max tweet id for given park from max_tweet table *)
let get_max_id_query = 
  Caqti_request.collect
    Caqti_type.string 
    Caqti_type.(tup2 string int)
    "SELECT * FROM max_tweet WHERE park = ?"

(* 
Gets max tweet id for a given park 
logs errors
*)
let get_max_id (park_name : string) : (int, unit) Core.result Lwt.t = 
  let get_counts park_name (module C : Caqti_lwt.CONNECTION) = 
    C.fold get_max_id_query (fun (_, id) acc -> id :: acc) park_name []
  in 
  let* res = Caqti_lwt.Pool.use (get_counts park_name) pool in
  match res with 
  | Error e -> Logs.info (fun m -> m "%s" (Caqti_error.show e)); Error() |> Lwt.return
  | Ok(lst) when List.length lst = 0 -> Error() |> Lwt.return
  | Ok(lst) -> Ok(lst |> List.hd_exn) |> Lwt.return

let get_since_id (park_name : string) : string Lwt.t= 
  let* id = park_name |> get_max_id in 
  match id with 
  | Error() -> "" |> Lwt.return 
  | Ok(id) -> ("&since_id=" ^ (string_of_int id)) |> Lwt.return

(* Gets URI for API call to tweet counts endpoint *)
let twitter_counts_uri (park_name : string) : string = 
  twitter_counts_base ^ "?query=" ^ (park_name |> get_query) ^ "&granularity=hour"

(* Gets URI for API call to general tweet search endpoint *)
let twitter_search_uri (park_name : string) : string Lwt.t = 
  let* max = get_since_id park_name in 
  let uri = twitter_search_base ^ "?q=" ^ (park_name |> get_query) ^ (park_name |> get_geocode) ^ "&count=100" ^ max in 
  uri |> Lwt.return
