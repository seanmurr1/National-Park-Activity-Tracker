@react.component
 let make = (~name: string) => {

  <div className="center">
    <h1>{React.string(name)}</h1>
  </div>
 }