type word = {
  text: string,
  mutable x: float,
  mutable y: float
};

type state = {
  mutable words: list(word),
  mutable ticks: int,
};

let startsWith = (input, word) => word.text->Js.Re.test(("^" ++ input)->Js.Re.fromString);