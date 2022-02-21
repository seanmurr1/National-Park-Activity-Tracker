%%raw(`import './styles/main.css'`)

type request
type response
@new external makeXMLHttpRequest: unit => request = "XMLHttpRequest"
@send external addEventListener: (request, string, unit => unit) => unit = "addEventListener"
@get external response: request => response = "response"
@send external open_: (request, string, string) => unit = "open"
@send external send: request => unit = "send"
@send external abort: request => unit = "abort"

type hour_activity = {hour: string, gen_count: int, weekday_count: int, weekend_count: int}
type day_activity = {day: string, count: int}
type month_activity = {month: string, count: int}
type activity_data = {hour: array<hour_activity>, day: array<day_activity>, month: array<month_activity>}
type api_response = {tweets: activity_data, counts: activity_data}

type res = None | Some(api_response)

@scope("JSON") @val
external parseIntoResponse: response => api_response = "parse"

@react.component 
let make = (~name: string) => {
  let (data, setData) = React.useState(_ => None)
  Js.log(name)
  React.useEffect1(() => {
    let request = makeXMLHttpRequest()
      request->addEventListener("load", () => {
      let response = request->response->parseIntoResponse
      Js.log(response)
      setData(_ => Some(response))
    })
    request->open_("GET", "http://localhost:9000/park?name=" ++ name);
    request->send
    None
  }, [])

  switch data {
    | None => <div> {React.string("Unable to fetch data!")} </div>
    | Some(d) => 
      <div className="row"> 
        <Charts title = "Interest in Park: Tweets Made About Park" hour_data = d.counts.hour day_data = d.counts.day month_data = d.counts.month /> 
        <Charts title = "Activity in Park: Tweets Made In Park" hour_data = d.tweets.hour day_data = d.tweets.day month_data = d.tweets.month /> 
      </div>
  }

}