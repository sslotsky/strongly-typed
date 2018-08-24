open Common;

let words = ["Logging", "Memory Store", "postgresql", "kubernetes", "terraform", "mysql", "serverless", "containerization", "scalability", "Redis", "RabbitMQ", "machine learning", "analytics", "Optimization", "CMS", "Elastic", "Algolia", "Jaws", "Timber", "Iron", "Piio"];

let spawn = ui => {
  let word = words->List.nth(Random.int(words->List.length - 1));
  let max = ui.width -. ui.calculateWidth(word);
  { text: word, x: Random.float(max), y: ui.fontSize->float_of_int, velocity: 1.5 +. Random.float(2.5) };
};

let nextState = (state, ui) => {
  if (state.gameOver) {
    state;
  } else {
    let (captured, falling) = List.partition(w => w.text == ui.input(), state.words);
    let (crashed, remaining) = List.partition(w => w.y > ui.height, falling);
    let (baseLeft, baseRight) = state.base;

    if (captured->List.length > 0 || !List.exists(ui.input()->startsWith, remaining)) {
      ui.clearInput();
    };

    List.iter(word => {
      let (left, right) = (word.x, word.x +. ui.calculateWidth(word.text));

      if (!state.crashCollector.covers(max(baseLeft, left), min(baseRight, right))) {
        ui.onCrash(word);
      };

      state.crashCollector.crash({ left, right });
    }, crashed);

    List.iter(ui.onCollect, captured);

    let newWords = List.map(word => { ...word, y: word.y +. word.velocity }, remaining);

    let newWords = switch (state.ticks mod 70) {
      | 0 => newWords->List.append([ui->spawn])
      | _ => newWords
    };

    let gameOver = state.crashCollector.covers(baseLeft, baseRight);

    { ...state, words: newWords, ticks: state.ticks + 1, gameOver };
  };
};
