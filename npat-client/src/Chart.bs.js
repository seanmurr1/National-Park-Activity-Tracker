// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";

function Chart(Props) {
  var title = Props.title;
  var children = Props.children;
  return React.createElement("div", {
              style: {
                marginBottom: "32px"
              }
            }, React.createElement("b", {
                  className: "center"
                }, title), children);
}

var make = Chart;

export {
  make ,
  
}
/* react Not a pure module */
