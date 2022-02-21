module ParkButton = {
  @react.component
  let make = (~name: string) => {
    let linkTo = "/park/" ++ name ++ " National Park"
    <div className="park-button" onClick={_ => RescriptReactRouter.push(linkTo)}> {React.string(name)} </div>
  }
}

@react.component 
let make = () => {
  <div>
  <div className="row">
    <ParkButton name = "Acadia" />
    <ParkButton name = "Shenandoah" /> 
    <ParkButton name = "Joshua Tree" />
    <ParkButton name = "Grand Teton" />
  </div>
  <div className="row">
    <ParkButton name = "Death Valley" /> 
    <ParkButton name = "Mount Rainier" />
    <ParkButton name = "Yellowstone" />
    <ParkButton name = "Zion" /> 
  </div>
  <div className="row">
    <ParkButton name = "Yosemite" />
    <ParkButton name = "Glacier" /> 
  </div>
  </div>

}