@react.component
let make = (~title: string, ~hour_data, ~day_data, ~month_data) => {
  <div>
    <h1 className="center"> {React.string(title)} </h1>
    <br/>
    <HourChart data = hour_data />
    <br/>
    <DayChart data = day_data />
    <br/>
    <MonthChart data = month_data />
    <br/>
  </div>

}