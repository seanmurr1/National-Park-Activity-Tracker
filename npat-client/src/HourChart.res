@react.component
let make = (~data) => {
  open Recharts
  
  <Chart title="Activity by Hour">
  <ResponsiveContainer height={Px(400.)} width={Px(900.)}>
    <BarChart
      barCategoryGap={Px(1.)}
      margin={"top": 5, "right": 30, "bottom": 5, "left": 20}
      data>
      <CartesianGrid strokeDasharray="3 3" />
      <XAxis dataKey="hour" />
      <YAxis />
      <Bar name="Any Given Day" dataKey="gen_count" fill="#71ECFF" stackId="a" />
      <Bar name="Weekdays" dataKey="weekday_count" fill="#71FF89" stackId="b" />
      <Bar name="Weekends" dataKey="weekend_count" fill="#FF71E1" stackId="c" />
      <Tooltip />
      <Legend align=#center iconType=#square />
    </BarChart>
  </ResponsiveContainer>
  </Chart>
  

}