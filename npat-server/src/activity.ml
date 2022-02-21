open Core

type hour_activity = {
  hour: string;
  gen_count: int;
  weekday_count: int;
  weekend_count: int
} [@@deriving yojson]

type day_activity = {
  day: string;
  count: int
} [@@deriving yojson]

type month_activity = {
  month: string;
  count: int
} [@@deriving yojson]

type activity_data = {
  hour: hour_activity list;
  day: day_activity list; 
  month: month_activity list;
} [@@deriving yojson]

type response = {
  tweets: activity_data;
  counts: activity_data;
} [@@deriving yojson]

module StringMap = Map.Make(String)

type activity_map = int StringMap.t StringMap.t

let hours = List.init 24 ~f:(string_of_int)
let days = Day_of_week.all |> List.map ~f:(fun d -> Day_of_week.to_string d)
let months = Month.all |> List.map ~f:(fun m -> Month.to_string m)

let starting_map (keys : string list) : activity_map = 
  List.fold keys ~init:StringMap.empty ~f:(fun m k -> m |> Map.set ~key:k ~data:StringMap.empty)

let update_hour_map (t : Dbmanager.tweet_count) (m : activity_map) (filter : Date.t -> bool): activity_map = 
  let hour = string_of_int t.hour in 
  let hour_map = Map.find_exn m hour in 
  let date = Date.to_string t.date in 
  if not @@ filter t.date then m else
  match Map.find hour_map date with 
  | None -> m |> Map.set ~key:hour ~data:(hour_map |> Map.set ~key:date ~data:t.count)
  | Some(v) -> m |> Map.set ~key:hour ~data:(hour_map |> Map.set ~key:date ~data:(v + t.count))

let build_hour_map (t : Dbmanager.tweet_count list) : activity_map = 
  List.fold t ~init:(starting_map hours) ~f:(fun m t -> update_hour_map t m (fun _ -> true))

let build_hour_weekday_map (t : Dbmanager.tweet_count list) : activity_map = 
  List.fold t ~init:(starting_map hours) ~f:(fun m t -> update_hour_map t m Date.is_weekday)

let build_hour_weekend_map (t : Dbmanager.tweet_count list) : activity_map = 
  List.fold t ~init:(starting_map hours) ~f:(fun m t -> update_hour_map t m Date.is_weekend)

let get_hour_count (m : int StringMap.t) : int = 
  let num_hours = Map.length m in 
  let total = m |> Map.data |> List.fold ~init:0 ~f:(fun total v -> total + v) in 
  match num_hours with 
  | 0 -> 0 
  | h -> total / h

let get_hour_activity (gen : int StringMap.t) (weekday : int StringMap.t) (weekend : int StringMap.t) (hour : string) : hour_activity = 
  {
    hour = hour; 
    gen_count = get_hour_count gen;
    weekday_count = get_hour_count weekday;
    weekend_count = get_hour_count weekend;
    }

let get_hour_activities (gen : activity_map) (weekday : activity_map) (weekend : activity_map)  : hour_activity list = 
  gen |> Map.keys |> List.fold ~init:[] ~f:(fun lst hour -> 
    (get_hour_activity (Map.find_exn gen hour) (Map.find_exn weekday hour) (Map.find_exn weekend hour)hour) :: lst)
  
let update_day_map (t : Dbmanager.tweet_count) (m : activity_map) : activity_map = 
  let day = Day_of_week.to_string @@ Date.day_of_week t.date in 
  let day_map = Map.find_exn m day in 
  let date = Date.to_string t.date in 
  match Map.find day_map date with 
  | None -> m |> Map.set ~key:day ~data:(day_map |> Map.set ~key:date ~data:t.count)
  | Some(v) -> m |> Map.set ~key:day ~data:(day_map |> Map.set ~key:date ~data:(v + t.count))

let build_day_map (t : Dbmanager.tweet_count list) : activity_map = 
  List.fold t ~init:(starting_map days) ~f:(fun m t -> update_day_map t m)

let get_day_activity (m : int StringMap.t) (day : string) : day_activity = 
  let num_days = Map.length m in 
  let total = m |> Map.data |> List.fold ~init:0 ~f:(fun total v -> total + v) in 
  let count = if num_days = 0 then 0 else total / num_days in 
  {day = day; count = count}

let get_day_activities (m : activity_map) : day_activity list = 
  m |> Map.keys |> List.fold ~init:[] ~f:(fun lst day -> (get_day_activity (Map.find_exn m day) day) :: lst)
  
let update_month_map (t : Dbmanager.tweet_count) (m : activity_map) : activity_map = 
  let month = Month.to_string @@ Date.month t.date in 
  let month_map = Map.find_exn m month in 
  let year = string_of_int @@ Date.year t.date in 
  match Map.find month_map year with 
  | None -> m |> Map.set ~key:month ~data:(month_map |> Map.set ~key:year ~data:t.count)
  | Some(v) -> m |> Map.set ~key:month ~data:(month_map |> Map.set ~key:year ~data:(v + t.count))

let build_month_map (t : Dbmanager.tweet_count list) : activity_map = 
  List.fold t ~init:(starting_map months) ~f:(fun m t -> update_month_map t m)

let get_month_activity (m : int StringMap.t) (month : string) : month_activity = 
  let num_months = Map.length m in 
  let total = m |> Map.data |> List.fold ~init:0 ~f:(fun total v -> total + v) in 
  let count = if num_months = 0 then 0 else total / num_months in 
  {month = month; count = count}

let get_month_activities (m : activity_map) : month_activity list = 
  m |> Map.keys |> List.fold ~init:[] ~f:(fun lst month -> (get_month_activity (Map.find_exn m month) month) :: lst)

let get_activity_data (t : Dbmanager.tweet_count list) : activity_data = 
  let hour_map = t |> build_hour_map in 
  let hour_weekday_map = t |> build_hour_weekday_map in 
  let hour_weekend_map = t |> build_hour_weekend_map in 
  let hour_activities = get_hour_activities hour_map hour_weekday_map hour_weekend_map in 
  {
    hour = hour_activities |> List.sort ~compare:(fun a b -> int_of_string a.hour - int_of_string b.hour);
    day = t |> build_day_map |> get_day_activities |> List.sort ~compare:(fun a b -> (a.day |> Day_of_week.of_string |> Day_of_week.to_int) - (b.day |> Day_of_week.of_string |> Day_of_week.to_int));
    month = t |> build_month_map |> get_month_activities |> List.sort ~compare:(fun a b -> (a.month |> Month.of_string |> Month.to_int) - (b.month |> Month.of_string |> Month.to_int));
  }

let get_response ((tweets, counts) : Dbmanager.tweet_count list * Dbmanager.tweet_count list) : response = 
  {
    tweets = tweets |> get_activity_data;
    counts = counts |> get_activity_data;
  }

let activity_response (data : Dbmanager.tweet_count list * Dbmanager.tweet_count list) : Yojson.Safe.t = 
  data 
  |> get_response
  |> response_to_yojson 


