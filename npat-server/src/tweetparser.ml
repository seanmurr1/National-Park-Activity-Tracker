open Core

(* Tweet ID, Park Name, Date, Hour *)
(* Formatted as tuple since Caqti expects tuples to be inserted into DB *)
type tweet_tuple = int * string * string * int

(* Park Name, Date, Hour, Tweet Count *)
(* Formatted as tuple since Caqti expects tuples to be inserted into DB *)
type count_tuple = string * string * int * int

(* Example value of "created_at" for a tweet returned by search API: "Wed Dec 01 18:36:40 +0000 2021" *)
(* Every tweet is returned with its time in UTC +0000 *)

let get_hour (created_at : string) : int = 
  created_at |> String.sub ~pos:11 ~len:2 |> int_of_string

let get_year (created_at : string) : string = 
  created_at |> String.sub ~pos:26 ~len:4

let get_month (created_at : string) : string = 
  created_at 
  |> String.sub ~pos:4 ~len:3 
  |> Month.of_string 
  |> Month.to_int 
  |> string_of_int

let get_day (created_at : string) : string = 
  created_at |> String.sub ~pos:8 ~len:2

(* Parses date into string from created_at attribute of a JSON tweet response *)
let get_date (created_at : string) : string = 
  let year = created_at |> get_year in 
  let month = created_at |> get_month in 
  let day = created_at |> get_day in 
  year ^ "-" ^ month ^ "-" ^ day

(* Adjusts time to local time for a given park based off of its timezone (UTC offset) *)
let get_date_and_hour_adjusted (park_name : string) (date : string) (hour : int) : string * int = 
  let park_info = Parks.get_park_info park_name in 
  match (hour + park_info.utc_offset) with 
  | h when h < 0 -> (date |> Date.of_string |> Fn.flip Date.add_days (-1) |> Date.to_string, h + 24)
  | h when h > 23 -> (date |> Date.of_string |> Fn.flip Date.add_days 1 |> Date.to_string, h - 24)
  | h -> (date, h)

(* 
Parses single JSON tweet object into tuple compatible with DB 
Adjusts to local time for park
*)
let parse_tweet (park_name : string) (tweet : Yojson.Basic.t) : tweet_tuple = 
  let open Yojson.Basic.Util in 
  let id = tweet |> member "id" |> to_int in 
  let created_at = tweet |> member "created_at" |> to_string in
  let (date, hour) = get_date_and_hour_adjusted park_name (created_at |> get_date) (created_at |> get_hour) in 
  (id, park_name, date, hour)

(* Parses list of JSON tweets into list of tuples compatible with DB *)
let parse_tweets (park_name : string) (tweets : Yojson.Basic.t list) : tweet_tuple list = 
  List.fold_left tweets ~init:[] ~f:(fun accum tweet -> (tweet |> parse_tweet park_name) :: accum)

(* 
Parses JSON of tweets returned from twitter API general search into list of tuples able to be inserted into DB. 
Consolidates tweets into tuples consisting of tweet id, park name, date, and hour.
Time is adjusted to be local to given park. 
Also returns the id of the latest tweet in search (this helps to optimize further API calls)
*)
let parse_tweet_search (park_name : string) (search_result : (Yojson.Basic.t, unit) result) : (tweet_tuple list * int, unit) result = 
  match search_result with 
  | Error _ -> Error()
  | Ok(search_result) -> let open Yojson.Basic.Util in 
      let max_id = search_result |> member "search_metadata" |> member "max_id" |> to_int in 
      let tweets = search_result |> member "statuses" |> to_list in 
      let parsed_tweets = tweets |> parse_tweets park_name in 
      Ok(parsed_tweets, max_id)

(* 
Parses single JSON tweet count object into tuple compatible with DB 
Adjusts time to timezone for given park
*)
let parse_count (park_name : string) (data : Yojson.Basic.t) : count_tuple = 
  let open Yojson.Basic.Util in 
  let date_raw = data |> member "start" |> to_string in
  let date = date_raw |> String.sub ~pos:0 ~len:10 in 
  let hour = date_raw |> String.sub ~pos:11 ~len:2 |> int_of_string in 
  let (date_a, hour_a) = get_date_and_hour_adjusted park_name date hour in
  let count = data |> member "tweet_count" |> to_int in 
  (park_name, date_a, hour_a, count)

(* Parses list of JSON tweet count objects into list of tuples compatible with DB *)
let parse_counts (park_name : string) (tweet_counts : Yojson.Basic.t list) : count_tuple list = 
  List.fold_left tweet_counts ~init:[] ~f:(fun accum count -> (count |> parse_count park_name) :: accum)

(* 
Parses JSON of tweets returned from twitter API tweet count search into list of tuples able to be inserted into DB. 
Consolidates tweets into tuples consisting of park name, date, hour, and count.
Time is adjusted to be local to given park. 
*)
let parse_tweet_counts (park_name : string) (search_result : (Yojson.Basic.t, unit) result) : (count_tuple list, unit) result = 
  match search_result with 
  | Error _ -> Error(())
  | Ok(search_result) -> let open Yojson.Basic.Util in 
      let tweet_counts = search_result |> member "data" |> to_list in 
      let parsed_counts = tweet_counts |> parse_counts park_name in 
      Ok(parsed_counts)



