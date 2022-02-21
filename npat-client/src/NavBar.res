module NavButton = {
  @react.component
  let make = (~name: string, ~selected: string, ~linkTo: string) => {
    let style = if selected == name {
      ReactDOM.Style.make(~backgroundColor="#efefef", ~padding="1ex", ())
    } else {
      ReactDOM.Style.make(~backgroundColor="#39D99F", ~padding="1ex", ())
    }

    <div style={style} onClick={_ => RescriptReactRouter.push(linkTo)}> {React.string(name)} </div>
  }
}

module Title = {
  @react.component
  let make = () => {
    let style = {ReactDOM.Style.make(~backgroundColor="#DEFFF3", ~padding="1ex", ())} 

    <div style={style}> {React.string("National Park Activity Tracker")} </div>
  }
}

@react.component
 let make = () => {
   let url = RescriptReactRouter.useUrl()

   let selected = switch url.path {
   | list{"park", ..._} => "Park Activity Tracker"
   | _ => "Home"
   }

  <div className="nav-bar">
  <div className="nav-button"><NavButton name="Home" selected={selected} linkTo="/" /></div>
  <div className="title"><Title /></div>
  </div>
 }