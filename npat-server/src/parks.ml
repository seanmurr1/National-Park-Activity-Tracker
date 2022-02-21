open Core

(* Information regarding a park, used for querying Twitter API and updating DB *)
type park_info = {
  utc_offset: int;
  geocode: string;
  aliases : string list;
}

(* List of currently supported National Parks *)
let parks = [
  "Glacier National Park";
  "Shenandoah National Park";
  "Acadia National Park";
  "Yellowstone National Park";
  "Mount Rainier National Park";
  "Zion National Park";
  "Yosemite National Park";
  "Death Valley National Park";
  "Grand Teton National Park";
  "Joshua Tree National Park"
]

(* Checks if a given string is included in the list of currently supported parks *)
let is_allowed_park (park_name : string) : bool = 
  List.mem parks park_name ~equal:String.(=)

module StringMap = Map.Make(String)

(* Map to hold park info for each supported national park *)
let park_map = 
  StringMap.empty
  |> Map.set ~key:"Glacier National Park" 
    ~data:{
      utc_offset = (-7); 
      geocode = "48.7596,-113.7870,22mi"; 
      aliases = ["Glacier National Park";"Glacier Park"]}
  |> Map.set ~key:"Shenandoah National Park"
    ~data:{
      utc_offset = (-5);
      geocode = "38.4755,-78.4535,10mi";
      aliases = ["Shenandoah National Park";"Shenandoah Park";"Shenandoah"]
    }
  |> Map.set ~key:"Acadia National Park"
    ~data:{
      utc_offset = (-5);
      geocode = "44.3386,-68.2733,5mi";
      aliases = ["Acadia National Park";"Acadia Park";"Acadia"]
    }
  |> Map.set ~key:"Yellowstone National Park"
    ~data:{
      utc_offset = (-7);
      geocode = "44.4280,-110.5885,33mi";
      aliases = ["Yellowstone National Park";"Yellowstone Park";"Yellowstone"]
    }
  |> Map.set ~key:"Mount Rainier National Park"
    ~data:{
      utc_offset = (-8);
      geocode = "46.8800,-121.7269,11mi";
      aliases = ["Mount Rainier National Park";"Mount Rainier Park";"Mount Rainier";"Rainier"]
    }
  |> Map.set ~key:"Zion National Park"
    ~data:{
      utc_offset = (-7);
      geocode = "37.2982,-113.0263,9mi";
      aliases = ["Zion National Park";"Zion Park";"Zion"]
    }
  |> Map.set ~key:"Yosemite National Park"
    ~data:{
      utc_offset = (-8);
      geocode = "37.8651,-119.5383,20mi";
      aliases = ["Yosemite National Park";"Yosemite Park";"Yosemite"]
    }
  |> Map.set ~key:"Death Valley National Park"
    ~data:{
      utc_offset = (-8);
      geocode = "36.5054,-117.0794,41mi";
      aliases = ["Death Valley National Park";"Death Valley Park";"Death Valley"]
    }
  |> Map.set ~key:"Grand Teton National Park"
    ~data:{
      utc_offset = (-7);
      geocode = "43.7904,-110.6818,13mi";
      aliases = ["Grand Teton National Park";"Grand Teton Park";"Grand Teton";"Tetons"]
    }
  |> Map.set ~key:"Joshua Tree National Park"
    ~data:{
      utc_offset = (-8);
      geocode = "33.8734,-115.9010,20mi";
      aliases = ["Joshua Tree National Park";"Joshua Tree Park";"Joshua Tree"]
    }

(* 
Obtains park info for a given park
Assumes valid park name will be passed 
*)
let get_park_info (park_name : string) : park_info = 
  Map.find_exn park_map park_name
  

