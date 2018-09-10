open Common;

let connectRight = (a, b) => {
  { left: a.left, right: max(a.right, b.right) };
};

let crashSite = (left, right) => {
  let sites = ref([]);

  let covers = (x, y) => sites^ |> List.exists(site => site.left <= x && site.right >= y);

  let insert = site => {
    let (leftSide, rightSide) = sites^ |> List.partition(s => s.left <= site.left);
    let (overlap, rest) = rightSide |> List.partition(s => s.left <= site.right);

    let rightSide = switch(overlap) {
    | [] => [site, ...rightSide]
    | _ => let closest = overlap->List.rev->List.hd; [site->connectRight(closest), ...rest]
    }

    let site = rightSide->List.hd;

    let leftSide = switch (leftSide->List.rev) {
    | [s, ...rest] when s.right >= site.left => [s->connectRight(site), ...rest]->List.rev
    | _ => leftSide->List.append([site])
    };

    sites := switch (rightSide->List.tl) {
    | tail => leftSide->List.append(tail)
    | exception Failure(_) => leftSide
    };
  };

  let crash = site => {
    let site = { left: max(site.left, left), right: min(site.right, right) };
    if (!covers(site.left, site.right)) {
      insert(site);
      true;
    } else {
      false;
    };
  };


  let percentCovered = (x, y) => {
    let (x, y) = (min(x, y), max(x, y));
    let amountCovered = sites^ |> List.fold_left((sum, site) => {
      sum +. (min(site.right, y) -. max(site.left, x))
    }, 0.0);

    100.0 *. amountCovered /. (y -. x);
  };

  { crash, sites: () => sites^, covers, percentCovered };
};
