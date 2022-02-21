open Core
open Lwt
open Syntax

(* 
Represents entry in counts table
Stores info about tweet counts per hour for a given national park
*)
type tweet_count = {
  date: Core.Date.t;
  hour: int;
  count: int
} 

(* Get connection to DB *)
let pool = Dbconnection.pool

(* 
Parses weird Caqti error to string if needed. Otherwise, pass on OK
This is called after a query is executed to determine result of Caqti call
*)
let or_error_string res =
  match%lwt res with
  | Ok x -> Ok x |> Lwt.return
  | Error e -> Error (Caqti_error.show e) |> Lwt.return

(* Query to create counts table: hold info about tweet counts per hour for a given park *)
let create_counts_query = 
  Caqti_request.exec 
    Caqti_type.unit
    {| 
      CREATE TABLE IF NOT EXISTS counts (
      park VARCHAR(50) NOT NULL,
      date VARCHAR(10) NOT NULL,
      hour INT NOT NULL,
      count INT NOT NULL,
      PRIMARY KEY (park, date, hour, count)
      )
    |}

(* Query to create tweets table: store tweets about a given park posted in that park *)
let create_tweets_query = 
  Caqti_request.exec 
    Caqti_type.unit
    {| 
      CREATE TABLE IF NOT EXISTS tweets (
      id bigint NOT NULL,
      park VARCHAR(50) NOT NULL,
      date VARCHAR(10) NOT NULL,
      hour INT NOT NULL,
      PRIMARY KEY (id, park)
      )
    |}

(* Query to create max_tweet table: store max_id of tweet to optimize further API search calls*)
let create_max_tweet_query = 
  Caqti_request.exec 
    Caqti_type.unit
    {| 
      CREATE TABLE IF NOT EXISTS max_tweet (
      park VARCHAR(50) NOT NULL,
      id bigint NOT NULL,
      PRIMARY KEY (park)
      )
    |}

let create_tweets (module C : Caqti_lwt.CONNECTION) =
    C.exec create_tweets_query ()

let create_counts (module C : Caqti_lwt.CONNECTION) =
    C.exec create_counts_query ()

let create_max_tweet (module C : Caqti_lwt.CONNECTION) =
    C.exec create_max_tweet_query ()

(* 
Create all database tables 
Not the most refactored code; however, this is only called when tables are dropped and need to be created again
*)
let create () : (unit, unit) Core.result Lwt.t =
  let* res = Caqti_lwt.Pool.use create_tweets pool |> or_error_string in 
  match res with 
  | Error e -> Logs.info (fun log -> log "%s" e); Error () |> Lwt.return
  | Ok() -> 
    let* res = Caqti_lwt.Pool.use create_counts pool |> or_error_string in 
    match res with 
    | Error e -> Logs.info (fun log -> log "%s" e); Error () |> Lwt.return
    | Ok() -> 
      let* res = Caqti_lwt.Pool.use create_max_tweet pool |> or_error_string in 
      match res with 
      | Error e -> Logs.info (fun log -> log "%s" e); Error () |> Lwt.return
      | Ok() -> Ok() |> Lwt.return
    

(* Query to insert tuple into count table *)
let insert_count_query = 
  Caqti_request.exec 
    Caqti_type.(tup4 string string int int)
    "INSERT INTO counts VALUES (?, ?, ?, ?) ON CONFLICT DO NOTHING"

(* Query to insert tuple into tweets table *)
let insert_tweet_query = 
  Caqti_request.exec 
    Caqti_type.(tup4 int string string int)
    "INSERT INTO tweets VALUES (?, ?, ?, ?) ON CONFLICT DO NOTHING"

(* Query to update tuple in max_tweet table *)
let update_max_tweet_query = 
  Caqti_request.exec 
    Caqti_type.(tup2 string int)
    "INSERT INTO max_tweet VALUES (?, ?) ON CONFLICT (park) DO UPDATE SET id = EXCLUDED.id"

(* Updates max_tweet entry for a given park with new max_id *)
let update_max_tweet (park_name : string) (max_id : int) : (unit, string) Core.result Lwt.t =
  let update_max tuple (module C : Caqti_lwt.CONNECTION) = 
    C.exec update_max_tweet_query tuple
  in
  Caqti_lwt.Pool.use (update_max (park_name, max_id)) pool |> or_error_string

(* Adds new tweets to db for a given park *)
let update_tweets (tweets : (int * string * string * int) list) : (unit, string) Core.result Lwt.t =
  let add_tweet tuple (module C : Caqti_lwt.CONNECTION) = 
    C.exec insert_tweet_query tuple
  in
  Lwt_list.fold_left_s (fun res tweet ->
    match res with 
    | Error e -> Error e |> Lwt.return
    | Ok() -> Caqti_lwt.Pool.use (add_tweet tweet) pool |> or_error_string
    ) (Ok()) tweets

(* 
Attempts to add new tweets to db for a given park and update max tweet id 
deals with error handling and logs errors 
*)
let update_tweet_search (park_name : string) : (unit, unit) Core.result Lwt.t =
  let* tweet_search = park_name |> Social.search_tweets in 
  let parsed_search = tweet_search |> Tweetparser.parse_tweet_search park_name in 
  match parsed_search with 
  | Error() -> Error() |> Lwt.return 
  | Ok(tweets, max_id) -> 
    let* res1 = tweets |> update_tweets in 
    let* res2 = max_id |> update_max_tweet park_name in
    match res1, res2 with 
    | Error e1, Error e2 -> Logs.info (fun log -> log "%s\n%s" e1 e2); Error() |> Lwt.return
    | Error e, Ok() -> Logs.info (fun log -> log "%s" e); Error() |> Lwt.return
    | Ok(), Error e -> Logs.info (fun log -> log "%s" e); Error() |> Lwt.return
    | Ok(), Ok() -> Ok() |> Lwt.return

(* Adds new count rows to db for a given park *)
let update_counts (counts : Tweetparser.count_tuple list) : (unit, string) Core.result Lwt.t =
  let add_count tuple (module C : Caqti_lwt.CONNECTION) = 
    C.exec insert_count_query tuple
  in
  Lwt_list.fold_left_s (fun res count ->
    match res with 
    | Error e -> Error e |> Lwt.return
    | Ok() -> Caqti_lwt.Pool.use (add_count count) pool |> or_error_string
    ) (Ok()) counts

(* 
Adds info regarding tweet counts for a given park to the counts table 
Logs errors
*)
let update_tweet_counts (park_name : string) : (unit, unit) Core.result Lwt.t = 
  let* tweet_counts = Social.tweet_counts park_name in 
  let parsed_counts = tweet_counts |> Tweetparser.parse_tweet_counts park_name in 
  match parsed_counts with 
  | Error() -> Error() |> Lwt.return 
  | Ok(counts) -> let* res = counts |> update_counts in 
    match res with 
    | Error e -> Logs.info (fun log -> log "%s" e); Error() |> Lwt.return
    | Ok() -> Ok() |> Lwt.return 

(* Updates all tables for a given park *)
let update_park (park_name : string) : (unit, unit) Core.result Lwt.t =
  let* res1 = park_name |> update_tweet_search in 
  let* res2 = park_name |> update_tweet_counts in 
  match res1, res2 with 
  | Error _, _ -> Error() |> Lwt.return
  | _, Error _ -> Error() |> Lwt.return
  | Ok(), Ok() -> Ok() |> Lwt.return

(* Updates all tables for all supported parks *)
let update_db () : (unit, unit) Core.result Lwt.t = 
  Lwt_list.fold_left_s (fun res park -> 
    match res with 
    | Error() -> Error() |> Lwt.return
    | Ok() -> update_park park
    ) (Ok()) Parks.parks

(* Query to get all entries for a park from the counts table *)
let get_park_counts_query = 
  Caqti_request.collect 
    Caqti_type.string 
    Caqti_type.(tup4 string string int int)
    "SELECT * FROM counts WHERE park = ?"

(* Query to get all entries for a park from tweets table *)
let get_park_tweets_query = 
  Caqti_request.collect 
    Caqti_type.string 
    Caqti_type.(tup4 int string string int)
    "SELECT * FROM tweets WHERE park = ?"

(* Gets all entries from counts table related to given park *)
let get_park_counts (park_name : string) : (tweet_count list, string) Core.result Lwt.t = 
  let get_counts park_name (module C : Caqti_lwt.CONNECTION) = 
    C.fold get_park_counts_query (fun (_, date, hour, count) acc -> 
      {
        date = Date.of_string date; 
        hour = hour; 
        count = count
      } :: acc
      ) park_name []
  in 
  Caqti_lwt.Pool.use (get_counts park_name) pool |> or_error_string

(* Gets all entries from tweets table related to given park *)
let get_park_tweets (park_name : string) : (tweet_count list, string) Core.result Lwt.t = 
  let get_tweets park_name (module C : Caqti_lwt.CONNECTION) = 
    C.fold get_park_tweets_query (fun (_, _, date, hour) acc -> 
      {
        date = Date.of_string date; 
        hour = hour; 
        count = 1
      } :: acc
      ) park_name []
  in 
  Caqti_lwt.Pool.use (get_tweets park_name) pool |> or_error_string

(* 
Gets all raw db info for a given park
Logs errors
*)
let get_park (park_name : string) : (tweet_count list * tweet_count list, unit) Core.result Lwt.t =
  let* tweets = park_name |> get_park_tweets in 
  let* counts = park_name |> get_park_counts in 
  match tweets, counts with 
  | Error e1, Error e2 -> Logs.info (fun log -> log "%s\n%s" e1 e2); Error() |> Lwt.return
  | Error e, Ok _ -> Logs.info (fun log -> log "%s" e); Error() |> Lwt.return
  | Ok _, Error e -> Logs.info (fun log -> log "%s" e); Error() |> Lwt.return
  | Ok(tweets), Ok(counts) -> Ok(tweets, counts) |> Lwt.return
