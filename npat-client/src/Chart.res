@react.component
let make = (~title, ~children) =>
  <div style={ReactDOM.Style.make(~marginBottom="32px", ())}>
    <b className="center"> {React.string(title)} </b> children
  </div>