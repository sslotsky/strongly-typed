open Common;
open Canvas;

type hot;

[@bs.deriving abstract]
type parcelModule = {
  hot: option(hot)
};

[@bs.val] external parcelModule: parcelModule = "module";
[@bs.send] external accept: (hot, unit) => unit = "accept";

switch (parcelModule->hotGet) {
| Some(h) => h->accept()
| _ => Js.log("We are not hot")
};


let words = ["Logging", "Memory Store", "postgresql", "kubernetes", "terraform", "mysql", "serverless", "containerization", "scalability", "Redis", "RabbitMQ", "machine learning", "analytics", "Optimization", "CMS", "Elastic", "Algolia", "Jaws", "Timber", "Iron", "Piio"];

let nextState = (state, ui) => {
  let (captured, falling) = List.partition(w => w.text == ui.input(), state.words);
  let (crashed, remaining) = List.partition(w => w.y > ui.height, falling);

  if (List.length(captured) > 0 || !List.exists(startsWith(ui.input()), remaining)) {
    ui.clearInput();
  };

  state.words = List.fold_left((words, word) => {
    if (word->List.mem(captured) || word->List.mem(crashed)) {
      words;
    } else {
      word.y = word.y +. 1.5;
      List.append(words, [word]);
    };
  }, [], state.words);

  if (state.ticks mod 90 == 0) {
    let word = List.nth(words, Random.int(List.length(words) - 1));
    let max = ui.width -. ui.calculateWidth(word);
    state.words = List.append(state.words, [{ text: word, x: Random.float(max), y: float_of_int(ui.fontSize) }]);
  };

  state.ticks = state.ticks + 1;
  state;
};

let initialState = {
  words: [],
  ticks: 0
};

paint(initialState, nextState);