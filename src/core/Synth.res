// WebAudio building blocks for theme sounds; nothing ships as an audio file.
type ctx
type node
type param

@new external makeContext: unit => ctx = "AudioContext"
@get external currentTime: ctx => float = "currentTime"
@get external destination: ctx => node = "destination"
@send external createOscillator: ctx => node = "createOscillator"
@send external createGain: ctx => node = "createGain"
@send external createBiquadFilter: ctx => node = "createBiquadFilter"
@send external createBufferSource: ctx => node = "createBufferSource"
@send external resume: ctx => promise<unit> = "resume"
@send external connect: (node, node) => node = "connect"
@send external start: (node, float) => unit = "start"
@send external stop: (node, float) => unit = "stop"
@set external setType: (node, string) => unit = "type"
@set external setBuffer: (node, 'buffer) => unit = "buffer"
@get external frequency: node => param = "frequency"
@get external detune: node => param = "detune"
@get external gain: node => param = "gain"
@get external q: node => param = "Q"
@send external setValueAtTime: (param, float, float) => unit = "setValueAtTime"
@send external linearRampToValueAtTime: (param, float, float) => unit = "linearRampToValueAtTime"
@send
external exponentialRampToValueAtTime: (param, float, float) => unit =
  "exponentialRampToValueAtTime"

let noiseBuffer: (ctx, float) => 'buffer = %raw(`(ctx, seconds) => {
  const buffer = ctx.createBuffer(1, Math.floor(ctx.sampleRate * seconds), ctx.sampleRate)
  const data = buffer.getChannelData(0)
  for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1
  return buffer
}`)

let context: ref<option<ctx>> = ref(None)

// Must be called from a user gesture (browsers start audio suspended).
let unlock = () =>
  switch context.contents {
  | Some(ctx) => ctx->resume->ignore
  | None => context := Some(makeContext())
  }

let play = f =>
  switch context.contents {
  | Some(ctx) => f(ctx)
  | None => ()
  }

let envelope = (ctx, ~at, ~attack=0.005, ~duration, ~volume) => {
  let amp = ctx->createGain
  amp->gain->setValueAtTime(0.0001, at)
  amp->gain->exponentialRampToValueAtTime(volume, at +. attack)
  amp->gain->exponentialRampToValueAtTime(0.0001, at +. duration)
  amp
}

let tone = (ctx, ~kind, ~from, ~to_, ~at, ~duration, ~volume) => {
  let osc = ctx->createOscillator
  osc->setType(kind)
  let t = ctx->currentTime +. at
  osc->frequency->setValueAtTime(from, t)
  osc->frequency->exponentialRampToValueAtTime(to_, t +. duration)
  let amp = ctx->envelope(~at=t, ~duration, ~volume)
  osc->connect(amp)->connect(ctx->destination)->ignore
  osc->start(t)
  osc->stop(t +. duration)
}

// A plucked double course (mandolin-ish): two detuned saws through a
// closing lowpass.
let pluck = (ctx, ~freq, ~at=0.0, ~duration=0.9, ~volume=0.08, ~cents=6.0) => {
  let t = ctx->currentTime +. at
  let filter = ctx->createBiquadFilter
  filter->setType("lowpass")
  filter->q->setValueAtTime(4.0, t)
  filter->frequency->setValueAtTime(freq *. 8.0, t)
  filter->frequency->exponentialRampToValueAtTime(freq *. 1.2, t +. duration *. 0.6)
  let amp = ctx->envelope(~at=t, ~attack=0.003, ~duration, ~volume)
  filter->connect(amp)->connect(ctx->destination)->ignore
  [-.cents, cents]->Array.forEach(detuneCents => {
    let osc = ctx->createOscillator
    osc->setType("sawtooth")
    osc->frequency->setValueAtTime(freq, t)
    osc->detune->setValueAtTime(detuneCents, t)
    osc->connect(filter)->ignore
    osc->start(t)
    osc->stop(t +. duration)
  })
}

let noise = (ctx, ~at=0.0, ~duration, ~volume, ~from, ~to_) => {
  let t = ctx->currentTime +. at
  let src = ctx->createBufferSource
  src->setBuffer(noiseBuffer(ctx, duration))
  let filter = ctx->createBiquadFilter
  filter->setType("lowpass")
  filter->frequency->setValueAtTime(from, t)
  filter->frequency->exponentialRampToValueAtTime(to_, t +. duration *. 0.9)
  let amp = ctx->envelope(~at=t, ~duration, ~volume)
  src->connect(filter)->connect(amp)->connect(ctx->destination)->ignore
  src->start(t)
}

// Equal temperament from MIDI note numbers.
let midi = note => 440.0 *. Math.pow(2.0, ~exp=(Int.toFloat(note) -. 69.0) /. 12.0)
