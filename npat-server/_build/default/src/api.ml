open Opium
open Lwt
open Syntax
open Core

let rec update_db () : unit Lwt.t = 
  Logs.info (fun m -> m "Starting DB update");
  let* res = Dbmanager.update_db () in 
  match res with 
  | Error() -> raise (Failure "Failed to update Database")
  | Ok() -> Logs.info (fun m -> m "Updated DB");
    let* () = Lwt_unix.sleep 3600. in 
    update_db ()

let get_park_response (park_name : string) : Response.t Lwt.t = 
  match Parks.is_allowed_park park_name with 
  | false -> "Error: this park is not supported" |> Response.of_plain_text |> Lwt.return 
  | true -> 
    let* park_data = Dbmanager.get_park park_name in 
    match park_data with 
    | Error() -> "Error: failure accessing DB" |> Response.of_plain_text |> Lwt.return 
    | Ok(data) -> 
      Activity.activity_response data 
      |> Yojson.Safe.to_string 
      |> Response.of_plain_text 
      |> Response.set_status @@ Status.of_code 200
      |> Response.add_headers [("Access-Control-Allow-Origin", "*")]
      |> Lwt.return

let park_handler req = 
  let name = Request.query "name" req in 
  match name with 
  | None -> "Error: missing name parameter" |> Response.of_plain_text |> Lwt.return 
  | Some(name) -> get_park_response name

let () = 
  Lwt.async update_db;
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Debug);
  App.empty 
  |> App.port 9000
  |> App.host "0.0.0.0"
  |> App.get "/" @@ (fun _ -> "Good Morning, api!" |> Response.of_plain_text |> Lwt.return)
  |> App.get "/park" park_handler
  |> App.run_command
;;

