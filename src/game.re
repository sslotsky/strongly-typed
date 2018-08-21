open Common;

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
  if (!state.gameOver) {
    let (captured, falling) = List.partition(w => w.text == ui.input(), state.words);
    let (crashed, remaining) = List.partition(w => w.y > ui.height, falling);

    if (captured->List.length > 0 || !List.exists(ui.input()->startsWith, remaining)) {
      ui.clearInput();
    };

    state.words = List.fold_left((words, word) => {
      if (word->List.mem(captured) || word->List.mem(crashed)) {
        words;
      } else {
        word.y = word.y +. 1.5;
        words->List.append([word]);
      };
    }, [], state.words);

    List.iter(word => {
      state.crashCollector.crash({ left: word.x, right: word.x +. ui.calculateWidth(word.text) });
    }, crashed);

    if (state.ticks mod 90 == 0) {
      let word = words->List.nth(Random.int(words->List.length - 1));
      let max = ui.width -. ui.calculateWidth(word);
      state.words = state.words->List.append([{ text: word, x: Random.float(max), y: ui.fontSize->float_of_int }]);
    };

    state.ticks = state.ticks + 1;

    if (state.crashCollector.covers(30.0, 570.0)) {
      state.gameOver = true;
    };
  };

  state;
};
