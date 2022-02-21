# Welcome to NPAT (National Park Activity Tracker)

This project comprises a web app (front end and backend) written in flavors of OCaml!

## Idea/Problem

I love the outdoors and wanted to design an app to help plan outdoor trips. It is a pain to go on a hike that is crowded with people.
So NPAT hopes to help you find the least busy time to perform an outdoor activity. Currently, it only supports 10 US National Parks. 
Activity data is measured by social media data. Currently, NPAT only tracks Twitter info:
- The number of tweets per given period of time related to a certain park is tracked
- The above, but limited to the specific geolocation of that park 

The first data-point tracks hopes to track general interest in the park, worldwide. The second data-point hopes to track actual activity (busyness) in that park.
Users are able to visualize this data over different periods of time (per hour, day, or month). 

## Front-End (Rescript)
The client-side of this app is written in Rescript-React, which compiles down to Javascript. Its main purpose is to fetch data 
from the server's API endpoint, and graph it for users.

## Back-End (OCaml)
The server-side of this app is written in plain OCaml. It utilizes the Opium library to host a web-server. It also takes advantage of many other
libraries to deal with JSON, asynchronous operations, etc. 
It interfaces with a PostgreSQL database hosted on Microsoft Azure. The Database is updated periodically throughout the day.

## How to run it

### Prerequisites
- Have a valid version of `opam` and `OCaml` installed
- Have `npm` installed
- Run `npm install -g bs-platform` to install Rescript compiler
  - Run `bsb -version` to check that it is installed

### Starting the Server
- `cd` into the `npat-server` folder 
- Run `opam install .` to install all dependencies listed in the `dune` file.
- Now, run `dune build` and everything will be built.
- You may run `dune test` to run all included back-end tests. Be aware that it takes about 20 seconds to run due to updating/accessing the database.
- After running `dune test`, you may run `bisect-ppx-report html` to generate a bisect test coverage file. This will be found in `npat-server/_coverage/index.html`. Open this file in your browser of choice and look at the test coverage. 
- To start the server, run `dune exe --root . ./src/api.exe`
  - You will be met with a lot of logs. This just means that the DB is currently being updated.
  - The server will be run at `http://localhost:9000`

### Starting the Client
- `cd` into the `npat-client` folder 
- Run `npm install --save-dev bs-platform gentype` and `npm install --save @rescript/react`
- Run `npm install` to install all dependencies. This may take a while if it is your first time running it
- Run `npm run start:res`. This will compile all `.res` (Rescript) files to `.bs.js` (javascript)
  - You may be prompted to run `kill  5345  || rm -f .bsb.lock`. Do so if necessary.
  - After this compiles, you can exit out of this process
- Run `npm start`. This will start up the client. It may take a minute to load.
  - The client will run at `http://localhost:3000`
  - If you want interaction, make sure the server is also running in the background somewhere.

# A note on Tests
All tests are located in the backend. There is not perfect coverage since error conditions for Twitter's API and the DB 
cannot be tested confidently. All core operations are tested though.


