type destination;

[@bs.deriving abstract]
type audioContext = {
  destination: destination
};

type buffer;

[@bs.deriving abstract]
type source = {
  mutable buffer: buffer
};

type httpResponse;

[@bs.deriving abstract]
type httpRequest = {
  mutable onload: unit => unit,
  mutable responseType: string,
  response: httpResponse
};

[@bs.new] external audioContext: unit => audioContext = "AudioContext";
[@bs.new] external request: unit => httpRequest = "XMLHttpRequest";
[@bs.send] external openRequest: (httpRequest, string, string, bool) => unit = "open";
[@bs.send] external sendRequest: (httpRequest, unit) => unit = "send";
[@bs.send] external decode: (audioContext, httpResponse, buffer => unit) => unit = "decodeAudioData";
[@bs.send] external createBufferSource: (audioContext, unit) => source = "createBufferSource";
[@bs.send] external connect: (source, destination) => unit = "connect";
[@bs.send] external start: (source, int) => unit = "start";

let loadSound = (ctx, filename) => {
  Js.Promise.make((~resolve, ~reject as _) => {
    let req = request();
    req->openRequest("GET", filename, true);
    req->responseTypeSet("arraybuffer");

    req->onloadSet(() => {
      ctx->decode(req->responseGet, buffer => {
        resolve(. buffer);
      });
    });

    req->sendRequest();
  });
};
