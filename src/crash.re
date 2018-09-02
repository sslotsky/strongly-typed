open Common;

let crashSite = () => {
  let sites = ref([]);

  let crash = site => {
    let (leftSide, rightSide) = sites^ |> List.partition(s => s.left <= site.left);
    let (overlap, rest) = rightSide |> List.partition(s => s.left <= site.right);

    let rightSide = switch(overlap) {
    | [] => [site, ...rightSide]
    | _ => let closest = overlap->List.rev->List.hd; [{ left: site.left, right: max(site.right, closest.right) }, ...rest]
    }

    let site = rightSide->List.hd;

    let leftSide = switch (leftSide->List.rev) {
    | [s, ...rest] when s.right >= site.left => rest->List.rev->List.append([{ left: s.left, right: max(site.right, s.right) }])
    | _ => leftSide->List.append([site])
    };

    sites := switch (rightSide->List.tl) {
    | tail => leftSide->List.append(tail)
    | exception Failure(_) => leftSide
    };
  };

  let covers = (x, y) => sites^ |> List.exists(site => site.left <= x && site.right >= y);

  let percentCovered = (x, y) => {
    let (x, y) = (min(x, y), max(x, y));
    let amountCovered = sites^ |> List.fold_left((sum, site) => {
      sum +. (min(site.right, y) -. max(site.left, x))
    }, 0.0);

    100.0 *. amountCovered /. (y -. x);
  };

  { crash, sites: () => sites^, covers, percentCovered };
};
