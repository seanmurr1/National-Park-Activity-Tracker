%%raw(`import './App.css';`)

@module("./logo.svg") external logo: string = "default"

@react.component
let make = () => {
  let url = RescriptReactRouter.useUrl()

  let component = switch url.path {
  | list{"park", name} => 
    let fullName = Js.String2.split(Js.String2.replaceByRe(name, %re("/%20/"), " "), "%20")[0] ++ " National Park"
    <div> <Subtitle name = fullName /> <Park name = name /> </div>
  | list{} => <div> <Subtitle name = "Select a National Park Below!" /> <LandingPage /> </div>
  | _ => <div> {React.string("Route not found")} </div>
  }

  <div> <NavBar /> {component} </div>
}
