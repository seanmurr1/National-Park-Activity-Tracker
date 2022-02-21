@react.component
let make = (~data) => {
  open Recharts

  <Chart title="Activity by Month">
  <ResponsiveContainer height={Px(400.)} width={Px(900.)}>
    <BarChart
      barCategoryGap={Px(1.)}
      margin={"top": 5, "right": 30, "bottom": 5, "left": 20}
      data>
      <CartesianGrid strokeDasharray="3 3" />
      <XAxis dataKey="month" />
      <YAxis />
      <Bar name="Value" dataKey="count" fill="#FFA664" stackId="a" />
      <Tooltip />
      <Legend align=#center iconType=#square />
    </BarChart>
  </ResponsiveContainer>
  </Chart>

}