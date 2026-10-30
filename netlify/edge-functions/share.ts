// Link previews: crawlers (Slack, iMessage, X) never run the game, so put the
// ?theme= card's title, description and image into the HTML they fetch.
import type { Config, Context } from "@netlify/edge-functions";

type Card = { title: string; description: string; image: string };

const site: Card = {
  title: "Strongly Typed",
  description:
    "A typing game in three flavors: sow seeds on a pollinator lawn, call tunes at a late-night gig, or fire orders in a smokehouse kitchen.",
  image: "/og/strongly-typed.png",
};

const themes: Record<string, Card> = {
  garden: {
    title: "Pollinator Lawn · Strongly Typed",
    description:
      "Autumn leaves are falling, each one carrying a native seed. Type a plant's name to sow it before it lands.",
    image: "/og/garden.png",
  },
  gig: {
    title: "The Gig · Strongly Typed",
    description:
      "The set list is coming down from the rafters. Type each tune's title to call it before it hits the stage, and don't make the drummer throw a cymbal.",
    image: "/og/gig.png",
  },
  kitchen: {
    title: "Low & Slow · Strongly Typed",
    description:
      "Tickets are coming off the rail. Type each order to fire it before it hits the pass and the coals go cold.",
    image: "/og/kitchen.png",
  },
};

export const cardFor = (theme: string | null): Card =>
  (theme !== null && Object.hasOwn(themes, theme) ? themes[theme] : site);

const escape = (value: string) =>
  value
    .replaceAll("&", "&amp;")
    .replaceAll('"', "&quot;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");

export const tags = (card: Card, url: URL) => {
  const image = new URL(card.image, url.origin).href;
  const meta = [
    ["property", "og:type", "website"],
    ["property", "og:site_name", "Strongly Typed"],
    ["property", "og:title", card.title],
    ["property", "og:description", card.description],
    ["property", "og:url", url.href],
    ["property", "og:image", image],
    ["property", "og:image:width", "1200"],
    ["property", "og:image:height", "630"],
    ["name", "description", card.description],
    ["name", "twitter:card", "summary_large_image"],
    ["name", "twitter:title", card.title],
    ["name", "twitter:description", card.description],
    ["name", "twitter:image", image],
  ];
  return meta
    .map(([attr, key, value]) => `<meta ${attr}="${key}" content="${escape(value)}" />`)
    .join("\n    ");
};

export const withCard = (html: string, card: Card, url: URL) =>
  html
    .replace(/<title>[^<]*<\/title>/, `<title>${escape(card.title)}</title>`)
    .replace("</head>", `  ${tags(card, url)}\n  </head>`);

export default async (request: Request, context: Context) => {
  const response = await context.next();
  if (!response.headers.get("content-type")?.includes("text/html")) return response;
  const url = new URL(request.url);
  const html = withCard(await response.text(), cardFor(url.searchParams.get("theme")), url);
  const headers = new Headers(response.headers);
  headers.delete("content-length");
  return new Response(html, { status: response.status, headers });
};

export const config: Config = { path: "/" };
