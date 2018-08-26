open Common;

let crashSite = () => {
  let sites = ref([]);

  let crash = site => {
    let (leftSide, rightSide) = List.partition(s => s.left <= site.left, sites^);
    let (overlap, rest) = List.partition(s => s.left <= site.right, rightSide);

    let rightSide = switch(overlap) {
    | [] => [site, ...rightSide]
    | _ => let closest = overlap->List.rev->List.hd; [{ left: site.left, right: max(site.right, closest.right) }, ...rest]
    }

    let site = List.hd(rightSide);

    let leftSide = switch (leftSide->List.rev) {
    | [s, ...rest] when s.right >= site.left => rest->List.rev->List.append([{ left: s.left, right: max(site.right, s.right) }])
    | _ => leftSide->List.append([site])
    };

    sites := switch (List.tl(rightSide)) {
    | tail => leftSide->List.append(tail)
    | exception Failure(_) => leftSide
    };
  };

  let covers = (x, y) => List.exists(site => site.left <= x && site.right >= y, sites^);

  let percentCovered = (x, y) => {
    let (x, y) = (min(x, y), max(x, y));
    let amountCovered = List.fold_left((sum, site) => {
      sum +. (min(site.right, y) -. max(site.left, x))
    }, 0.0, sites^);

    100.0 *. amountCovered /. (y -. x);
  };

  { crash, sites: () => sites^, covers, percentCovered };
};
