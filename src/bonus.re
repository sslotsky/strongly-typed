open Common;

[@bs.scope "Math"][@bs.val] external pi: float = "PI"; 

let tau = 2.0 *. pi;

let tick = (bonus: bonus, ui: ui) => {
  ...bonus,
  x: bonus.x == ui.width ? 0.0 : bonus.x +. 1.0,
  offsetY: bonus.amplitude->float_of_int *. sin(tau *. 0.02 *. bonus.x)
};

let spawn = () => {
  x: 0.0,
  startY: 60.0,
  offsetY: 0.0,
  amplitude: 30
};
