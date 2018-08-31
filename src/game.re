open Common;

let words = ["Logging", "Memory Store", "postgresql", "kubernetes", "terraform", "mysql", "serverless", "containerization", "scalability", "Redis", "RabbitMQ", "machine learning", "analytics", "Optimization", "CMS", "Elastic", "Algolia", "Jaws", "Timber", "Iron", "Piio"];

let spawn = ui => {
  let word = words->List.nth(Random.int(words->List.length - 1));
  let max = ui.width -. ui.calculateWidth(word);
  { text: word, x: Random.float(max), y: ui.fontSize->float_of_int, velocity: 1.5 +. Random.float(2.5) };
};

let collectAll = (state: state, ui) => {
  ui.clearInput();
  List.iter(ui.onCollect, state.words);
  { ...state, words: [], bonus: None };
};

let collect = (state: state, ui) => {
  let (captured, falling) = List.partition(w => w.text == ui.input(), state.words);
  let (crashed, remaining) = List.partition(w => w.y > ui.height, falling);
  let (baseLeft, baseRight) = state.base;

  let matchesBonus = switch(state.bonus) {
  | None => false
  | Some(_) => ui.input()->startsWithStr("manifold")
  };

  let matchesWord = List.exists(ui.input()->startsWith, remaining);

  if (captured->List.length > 0 || !(matchesBonus || matchesWord)) {
    ui.clearInput();
  };

  List.iter(word => {
    let (left, right) = (word.x, word.x +. ui.calculateWidth(word.text));

    if (!state.crashCollector.covers(max(baseLeft, left), min(baseRight, right))) {
      ui.onCrash(word);
      state.crashCollector.crash({ left, right });
    };

  }, crashed);

  List.iter(ui.onCollect, captured);

  let newWords = List.map(word => { ...word, y: word.y +. word.velocity }, remaining);

  let newWords = switch (state.ticks mod 70) {
  | 0 => newWords->List.append([ui->spawn])
  | _ => newWords
  };

  let gameOver = state.crashCollector.covers(baseLeft, baseRight);

  let newBonus = switch (state.bonus) {
  | Some(bonus) when bonus.x == ui.width => None
  | None => let flip = Random.float(1.0); Js.log(flip); flip < 0.002 ? Some(Bonus.spawn()) : None
  | Some(bonus) => Some(bonus->Bonus.tick(ui))
  };

  { ...state, words: newWords, ticks: state.ticks + 1, gameOver, bonus: newBonus };
};

let nextState = (state: state, ui) => {
  if (state.gameOver) {
    state;
  } else {
    switch(state.bonus) {
    | Some(_) when ui.input() == "manifold" => state->collectAll(ui)
    | _ => state->collect(ui)
    }
  };
};
