(* How activity is represented per hour *)
type hour_activity = {
  hour: string;
  gen_count: int;
  weekday_count: int;
  weekend_count: int
} [@@deriving yojson]

(* How activity is represented per day *)
type day_activity = {
  day: string;
  count: int
} [@@deriving yojson]

(* How activity is represented per month *)
type month_activity = {
  month: string;
  count: int
} [@@deriving yojson]

(* All activity data for a given API endpoint *)
type activity_data = {
  hour: hour_activity list;
  day: day_activity list; 
  month: month_activity list;
} [@@deriving yojson]

(* Activity data for general tweet search and tweet counts APIs *)
type response = {
  tweets: activity_data;
  counts: activity_data;
} [@@deriving yojson]

(* Get activity response for a given National Park *)
val activity_response : Dbmanager.tweet_count list * Dbmanager.tweet_count list -> Yojson.Safe.t