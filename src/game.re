open Common;

let words = ["Messaging", "Logging", "Memory Store", "postgresql", "kubernetes", "terraform", "mysql", "serverless", "containerization", "scalability", "Redis", "RabbitMQ", "machine learning", "analytics", "Optimization", "CMS", "Elastic", "Algolia", "Jaws", "Timber", "Iron", "Piio"];

let rec spawn = ui => {
  let word = words->List.nth(Random.int(words->List.length - 1));
  let width = ui.calculateWidth(word);

  if (width > ui.width) {
    spawn(ui);
  } else {
    let max = ui.width -. width;
    { text: word, x: Random.float(max), y: 0.0, velocity: 1.5 +. Random.float(2.5) };
  }
};

let bonusCaptured = (state: state) => {
  { ...state, words: [], bonus: None, crashed: [], captured: state.words, clear: true };
};

let collect = (state: state, ui) => {
  let (captured, falling) = state.words |> List.partition(w => w.text == ui.input());
  let (crashed, remaining) = falling |> List.partition(w => w.y > ui.height);
  let (baseLeft, baseRight) = state.base;

  let crashed = crashed |> List.filter(word => {
    let (left, right) = (word.x, word.x +. ui.calculateWidth(word.text));
    state.crashCollector.crash({ left, right });
  });

  let newWords = remaining |> List.map(word => { ...word, y: word.y +. word.velocity });

  let newWords = switch (state.ticks mod 70) {
  | 0 => newWords->List.append([ui->spawn])
  | _ => newWords
  };

  let gameOver = state.crashCollector.covers(baseLeft, baseRight);

  let newBonus = switch (state.bonus) {
  | Some(bonus) when bonus.x == ui.width => None
  | None => Random.float(1.0) < 0.0015 ? Some(Bonus.spawn()) : None
  | Some(bonus) => Some(bonus->Bonus.tick(ui))
  };

  let matchesBonus = switch(newBonus) {
  | None => false
  | Some(_) => bonusWord->startsWith(ui.input())
  };

  let matchesWord = newWords |> List.exists(ui.input()->isPrefixOf);

  let clear = captured->List.length > 0 || !(matchesBonus || matchesWord);

  { ...state, clear, captured, crashed, words: newWords, ticks: state.ticks + 1, gameOver, bonus: newBonus };
};

let nextState = (state: state, ui) => {
  if (state.gameOver) {
    state;
  } else {
    switch(state.bonus) {
    | Some(_) when ui.input() == bonusWord => state->bonusCaptured
    | _ => state->collect(ui)
    }
  };
};
