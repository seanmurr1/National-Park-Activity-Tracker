open Core
open OUnit2 
open Lwt
open Syntax

let test_twitter_header_ = () (* TODO: test after getting .env working *)

let test_twitter_counts_uri _ = 
  let uri = Uribuilder.twitter_counts_uri "Shenandoah National Park" in 
  assert_equal "https://api.twitter.com/2/tweets/counts/recent?query=(Shenandoah National Park)OR(Shenandoah Park)OR(Shenandoah)&granularity=hour" @@ uri;;

let test_twitter_search_uri _ = 
  let* uri = Uribuilder.twitter_search_uri "Zion National Park" in 
  (assert_equal "https://api.twitter.com/1.1/search/tweets.json?q=(Zion National Park)OR(Zion Park)OR(Zion)&geocode=37.2982,-113.0263,9mi&count=100&since_id=" @@ String.sub uri ~pos:0 ~len:140) |> Lwt.return

let test_search_response1 = 
  "{
    \"search_metadata\": 
    {
      \"max_id\": 1467894159348584453
    }, 
    \"statuses\": [
      {
        \"created_at\": \"Mon Dec 06 16:30:14 +0000 2021\",
        \"id\": 1467894159348584453
      },
      {
        \"created_at\": \"Wed Dec 01 10:12:37 +0000 2021\",
        \"id\": 1465987191323070466
      }
    ]
  }" |> Yojson.Basic.from_string

let expected_search_parse1 : Tweetparser.tweet_tuple list * int =
  ([(1465987191323070466, "Zion National Park", "2021-12-01", 3); (1467894159348584453, "Zion National Park", "2021-12-06", 9);], 1467894159348584453)

let test_parse_tweet_search _ = 
  assert_equal (Error ()) @@ Tweetparser.parse_tweet_search "test" (Error());
  assert_equal (Ok expected_search_parse1) @@ Tweetparser.parse_tweet_search "Zion National Park" (Ok test_search_response1);;

let test_count_response1 = 
  "{
    \"data\": [
      {
        \"end\": \"2021-11-29T22:00:00.000Z\",
        \"start\": \"2021-11-29T21:04:00.000Z\",
        \"tweet_count\": 5
      },
      {
        \"end\": \"2021-11-29T23:00:00.000Z\",
        \"start\": \"2021-11-29T22:00:00.000Z\",
        \"tweet_count\": 1
      },
      {
        \"end\": \"2021-11-30T00:00:00.000Z\",
        \"start\": \"2021-11-29T23:00:00.000Z\",
        \"tweet_count\": 4
      }
    ],
    \"meta\": {
        \"total_tweet_count\": 10
    }
}" |> Yojson.Basic.from_string

let expected_count_parse1 : Tweetparser.count_tuple list = 
  [("Yosemite National Park", "2021-11-29", 15, 4);("Yosemite National Park", "2021-11-29", 14, 1);("Yosemite National Park", "2021-11-29", 13, 5)]

let test_parse_tweet_counts _ = 
  assert_equal (Error ()) @@ Tweetparser.parse_tweet_counts "test" (Error ());
  assert_equal (Ok expected_count_parse1) @@ Tweetparser.parse_tweet_counts "Yosemite National Park" (Ok test_count_response1);;

let test_tweet_counts _ = 
  let* res = Social.tweet_counts "Zion National Park" in 
  match res with 
  | Error () -> assert_failure "Failed API call";
  | Ok(json) -> let open Yojson.Basic.Util in 
    let data = json |> member "data" in 
    match data with 
    | `Null -> assert_failure "Failed API call";
    | data -> 
      match data |> to_list |> List.hd_exn |> member "start" with 
      | `Null -> assert_failure "Failed API call";
      | _ -> (assert_equal 0 0) |> Lwt.return;;

let test_search_tweets _ = 
  let* res = Social.search_tweets "Zion National Park" in 
  match res with 
  | Error () -> assert_failure "Failed API call";
  | Ok(json) -> let open Yojson.Basic.Util in 
    let data = json |> member "search_metadata" in 
    match data with 
    | `Null -> assert_failure "Failed API call";
    | data -> 
      match data |> member "max_id" with 
      | `Null -> assert_failure "Failed API call";
      | _ -> (assert_equal 0 0) |> Lwt.return;; 

let test_is_allowed_park _ = 
  assert_equal true @@ Parks.is_allowed_park "Glacier National Park";
  assert_equal true @@ Parks.is_allowed_park "Yellowstone National Park";
  assert_equal false @@ Parks.is_allowed_park "Tetons";
  assert_equal false @@ Parks.is_allowed_park "Zion";;

let test_get_park_info _ = 
  let info = Parks.get_park_info "Glacier National Park" in 
  assert_equal (-7) @@ info.utc_offset;
  assert_equal "48.7596,-113.7870,22mi" @@ info.geocode;
  assert_equal ["Glacier National Park";"Glacier Park"] @@ info.aliases;
  let info = Parks.get_park_info "Zion National Park" in 
  assert_equal (-7) @@ info.utc_offset;
  assert_equal "37.2982,-113.0263,9mi" @@ info.geocode;
  assert_equal ["Zion National Park";"Zion Park";"Zion"] @@ info.aliases;;

let test_get_park _ = 
  let* res = Dbmanager.get_park "Zion National Park" in 
  match res with 
  | Error() -> assert_failure "Failed to get park data from DB";
  | Ok(_) -> (assert_equal 0 0) |> Lwt.return 

let test_create _ = 
  let* res = Dbmanager.create () in 
  match res with 
  | Error() -> assert_failure "Failed to create tables";
  | Ok() -> (assert_equal 0 0) |> Lwt.return 

let test_update_db _ = 
  let* res = Dbmanager.update_db () in 
  match res with 
  | Error() -> assert_failure "Failed to update tables";
  | Ok() -> (assert_equal 0 0) |> Lwt.return  


let test_db_data1 : Dbmanager.tweet_count list = 
  [
    {date = Date.of_string "2021-12-05"; hour = 5; count = 2};
    {date = Date.of_string "2021-11-26"; hour = 15; count = 4};
    {date = Date.of_string "2021-10-19"; hour = 19; count = 1};
    {date = Date.of_string "2021-05-05"; hour = 0; count = 2};
    {date = Date.of_string "2021-07-12"; hour = 7; count = 10};
  ]

let expected_activity_response1 = 
  "{
  \"tweets\": {
    \"hour\": [
      {
        \"hour\": \"0\",
        \"gen_count\": 2,
        \"weekday_count\": 2,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"1\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"2\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"3\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"4\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"5\",
        \"gen_count\": 2,
        \"weekday_count\": 0,
        \"weekend_count\": 2
      },
      {
        \"hour\": \"6\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"7\",
        \"gen_count\": 10,
        \"weekday_count\": 10,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"8\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"9\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"10\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"11\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"12\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"13\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"14\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"15\",
        \"gen_count\": 4,
        \"weekday_count\": 4,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"16\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"17\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"18\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"19\",
        \"gen_count\": 1,
        \"weekday_count\": 1,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"20\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"21\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"22\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"23\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      }
    ],
    \"day\": [
      {
        \"day\": \"SUN\",
        \"count\": 2
      },
      {
        \"day\": \"MON\",
        \"count\": 10
      },
      {
        \"day\": \"TUE\",
        \"count\": 1
      },
      {
        \"day\": \"WED\",
        \"count\": 2
      },
      {
        \"day\": \"THU\",
        \"count\": 0
      },
      {
        \"day\": \"FRI\",
        \"count\": 4
      },
      {
        \"day\": \"SAT\",
        \"count\": 0
      }
    ],
    \"month\": [
      {
        \"month\": \"Jan\",
        \"count\": 0
      },
      {
        \"month\": \"Feb\",
        \"count\": 0
      },
      {
        \"month\": \"Mar\",
        \"count\": 0
      },
      {
        \"month\": \"Apr\",
        \"count\": 0
      },
      {
        \"month\": \"May\",
        \"count\": 2
      },
      {
        \"month\": \"Jun\",
        \"count\": 0
      },
      {
        \"month\": \"Jul\",
        \"count\": 10
      },
      {
        \"month\": \"Aug\",
        \"count\": 0
      },
      {
        \"month\": \"Sep\",
        \"count\": 0
      },
      {
        \"month\": \"Oct\",
        \"count\": 1
      },
      {
        \"month\": \"Nov\",
        \"count\": 4
      },
      {
        \"month\": \"Dec\",
        \"count\": 2
      }
    ]
  },
  \"counts\": {
    \"hour\": [
      {
        \"hour\": \"0\",
        \"gen_count\": 2,
        \"weekday_count\": 2,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"1\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"2\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"3\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"4\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"5\",
        \"gen_count\": 2,
        \"weekday_count\": 0,
        \"weekend_count\": 2
      },
      {
        \"hour\": \"6\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"7\",
        \"gen_count\": 10,
        \"weekday_count\": 10,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"8\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"9\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"10\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"11\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"12\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"13\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"14\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"15\",
        \"gen_count\": 4,
        \"weekday_count\": 4,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"16\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"17\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"18\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"19\",
        \"gen_count\": 1,
        \"weekday_count\": 1,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"20\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"21\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"22\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      },
      {
        \"hour\": \"23\",
        \"gen_count\": 0,
        \"weekday_count\": 0,
        \"weekend_count\": 0
      }
    ],
    \"day\": [
      {
        \"day\": \"SUN\",
        \"count\": 2
      },
      {
        \"day\": \"MON\",
        \"count\": 10
      },
      {
        \"day\": \"TUE\",
        \"count\": 1
      },
      {
        \"day\": \"WED\",
        \"count\": 2
      },
      {
        \"day\": \"THU\",
        \"count\": 0
      },
      {
        \"day\": \"FRI\",
        \"count\": 4
      },
      {
        \"day\": \"SAT\",
        \"count\": 0
      }
    ],
    \"month\": [
      {
        \"month\": \"Jan\",
        \"count\": 0
      },
      {
        \"month\": \"Feb\",
        \"count\": 0
      },
      {
        \"month\": \"Mar\",
        \"count\": 0
      },
      {
        \"month\": \"Apr\",
        \"count\": 0
      },
      {
        \"month\": \"May\",
        \"count\": 2
      },
      {
        \"month\": \"Jun\",
        \"count\": 0
      },
      {
        \"month\": \"Jul\",
        \"count\": 10
      },
      {
        \"month\": \"Aug\",
        \"count\": 0
      },
      {
        \"month\": \"Sep\",
        \"count\": 0
      },
      {
        \"month\": \"Oct\",
        \"count\": 1
      },
      {
        \"month\": \"Nov\",
        \"count\": 4
      },
      {
        \"month\": \"Dec\",
        \"count\": 2
      }
    ]
  }
}" |> Yojson.Safe.from_string

let test_activity_response _ =
  assert_equal expected_activity_response1 @@ Activity.activity_response (test_db_data1, test_db_data1);; 

let api_tests = 
  "API Library Function Tests" >: test_list [
    "Uribuilder: Twitter Search Uri" >:: OUnitLwt.lwt_wrapper test_twitter_search_uri;
    "Uribuilder: Twitter Counts Uri" >:: test_twitter_counts_uri;
    "Parks: Is Allowed Park" >:: test_is_allowed_park;
    "Parks: Get Park Info" >:: test_get_park_info;
    "Tweetparser: Parse Tweet Search" >:: test_parse_tweet_search;
    "Tweetparser: Parse Tweet Counts" >:: test_parse_tweet_counts;
    "Social: Tweet Counts" >:: OUnitLwt.lwt_wrapper test_tweet_counts;
    "Social: Search Tweets" >:: OUnitLwt.lwt_wrapper test_search_tweets;
    "Dbmanager: Create" >:: OUnitLwt.lwt_wrapper test_create;
    "Dbmanager: Update DB" >:: OUnitLwt.lwt_wrapper test_update_db;
    "Dbmanager: Get Park" >:: OUnitLwt.lwt_wrapper test_get_park;
    "Activity: Activity Response" >:: test_activity_response;
  ]

let series = 
  "API Tests" >::: [
    api_tests;
  ]

let () = 
  run_test_tt_main series
