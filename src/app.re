[%%raw "require('./assets/app.css')"];

type route =
  | NotFound
  | Play
  | Examples;

type state = { route: route };

type action =
  | RouteUpdate(route);

let component = ReasonReact.reducerComponent("App");

let getRoute = (url: ReasonReact.Router.url) => {
  switch (url.path) {
  | [] => Play
  | ["examples"] => Examples
  | _ => NotFound
  }
};

let renderRoute = route => switch(route) {
| NotFound => <h1>(ReasonReact.string("not found"))</h1> 
| Play => <Play />
| Examples => <Examples />
};

let make = _ => {
  ...component,
  initialState: () => { route: ReasonReact.Router.dangerouslyGetInitialUrl()->getRoute },
  reducer: (action, _) => {
    switch action {
    | RouteUpdate(r) => ReasonReact.Update({ route: r })
    }
  },
  didMount: self => {
    let watcherId = ReasonReact.Router.watchUrl(url => {
      [%debugger];
      RouteUpdate(url->getRoute) |> self.send;
    });
    self.onUnmount(() => ReasonReact.Router.unwatchUrl(watcherId));
  },
  render: self => renderRoute(self.state.route)
};
