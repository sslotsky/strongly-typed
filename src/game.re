open Common;

let words = ["Messaging", "Logging", "Memory Store", "postgresql", "kubernetes", "terraform", "mysql", "serverless", "containerization", "scalability", "Redis", "RabbitMQ", "machine learning", "analytics", "Optimization", "CMS", "Elastic", "Algolia", "Jaws", "Timber", "Iron", "Piio"];
let bonusWord = "manifold";

let spawn = ui => {
  let word = words->List.nth(Random.int(words->List.length - 1));
  let max = ui.width -. ui.calculateWidth(word);
  { text: word, x: Random.float(max), y: 0.0, velocity: 1.5 +. Random.float(2.5) };
};

let bonusCaptured = (state: state, ui) => {
  ui.clearInput();
  List.iter(ui.onCollect, state.words);
  { ...state, words: [], bonus: None };
};

let collect = (state: state, ui) => {
  let (captured, falling) = state.words |> List.partition(w => w.text == ui.input());
  let (crashed, remaining) = falling |> List.partition(w => w.y > ui.height);
  let (baseLeft, baseRight) = state.base;

  let matchesBonus = switch(state.bonus) {
  | None => false
  | Some(_) => bonusWord->startsWith(ui.input())
  };

  let matchesWord = remaining |> List.exists(ui.input()->isPrefixOf);

  if (captured->List.length > 0 || !(matchesBonus || matchesWord)) {
    ui.clearInput();
  };

  crashed |> List.iter(word => {
    let (left, right) = (word.x, word.x +. ui.calculateWidth(word.text));

    if (!state.crashCollector.covers(max(baseLeft, left), min(baseRight, right))) {
      ui.onCrash(word);
      state.crashCollector.crash({ left, right });
    };

  });

  captured |> List.iter(ui.onCollect);

  let newWords = remaining |> List.map(word => { ...word, y: word.y +. word.velocity });

  let newWords = switch (state.ticks mod 70) {
  | 0 => newWords->List.append([ui->spawn])
  | _ => newWords
  };

  let gameOver = state.crashCollector.covers(baseLeft, baseRight);

  let newBonus = switch (state.bonus) {
  | Some(bonus) when bonus.x == ui.width => None
  | None => Random.float(1.0) < 0.002 ? Some(Bonus.spawn()) : None
  | Some(bonus) => Some(bonus->Bonus.tick(ui))
  };

  { ...state, words: newWords, ticks: state.ticks + 1, gameOver, bonus: newBonus };
};

let nextState = (state: state, ui) => {
  if (state.gameOver) {
    state;
  } else {
    switch(state.bonus) {
    | Some(_) when ui.input() == bonusWord => state->bonusCaptured(ui)
    | _ => state->collect(ui)
    }
  };
};
