open Core
open Lwt
open Syntax
open Cohttp
open Cohttp_lwt_unix

(* 
Obtains JSON response from Twitter API.
Calls Twitter's tweet count API to obtain counts of 
tweets related to a given national park per hour.
Does not restrict location. This is meant to obtain
info regarding general activity about a park, worldwide.
*)
let tweet_counts (park_name : string) : (Yojson.Basic.t, unit) Core.result Lwt.t= 
  Client.get ~headers:Uribuilder.twitter_header (Uri.of_string @@ Uribuilder.twitter_counts_uri park_name) >>= fun (resp, body) ->
  let code = resp |> Response.status |> Code.code_of_status in
  match code with 
  | 200 -> let* resp_string = body |> Cohttp_lwt.Body.to_string in
      let json = resp_string |> Yojson.Basic.from_string in Lwt.return(Ok(json))
  | _ -> Logs.info (fun log -> log "API failed searching tweet counts for %s with code %d" park_name code); Lwt.return(Error(()))

(* 
Obtains JSON response from Twitter API.
Calls Twitter's recent tweet search API to recent
tweets related to a given national park, that
were posted within that park.
*)
let search_tweets (park_name : string) : (Yojson.Basic.t, unit) Core.result Lwt.t = 
  let* uri = Uribuilder.twitter_search_uri park_name in 
  Client.get ~headers:Uribuilder.twitter_header (Uri.of_string @@ uri) >>= fun (resp, body) ->
  let code = resp |> Response.status |> Code.code_of_status in 
  match code with 
  | 200 -> let* resp_string = body |> Cohttp_lwt.Body.to_string in 
      let json = resp_string |> Yojson.Basic.from_string in Lwt.return(Ok(json))
  | _ -> Logs.info (fun log -> log "API failed searching recent tweets for %s with code %d" park_name code); Lwt.return(Error(()))

