open Core

(* Connection URL to database *)
(* let connection_url = "postgresql://localhost:5432/NPAT?user=postgres&password=soccermaster4459" *)

let connection_url = "postgres://npat_admin:S0ccer00!@npat-pgsql.postgres.database.azure.com/postgres?sslmode=require"

(* Create connection to PostgreSQL database *)
let pool =
  match Caqti_lwt.connect_pool ~max_size:10 (Uri.of_string connection_url) with
  | Ok pool -> pool
  | Error err -> failwith (Caqti_error.show err)
