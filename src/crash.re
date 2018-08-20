open Common;

let crashSite = () => {
  let sites = ref([]);

  let crash = site => {
    let (leftSide, rightSide) = List.partition(s => s.left <= site.left, sites^);

    let rightSide = switch(rightSide) {
    | [s] when site.right >= s.left => [{ left: site.left, right: max(site.right, s.right) }]
    | [s, ...rest] when site.right >= s.left => List.append([{ left: site.left, right: max(site.right, s.right) }], rest)
    | _ => [site, ...rightSide]
    };

    let site = List.hd(rightSide);

    let leftSide = switch (List.rev(leftSide)) {
    | [s] when s.right >= site.left => [{ left: s.left, right: max(site.right, s.right) }]
    | [s, ...rest] when s.right >= site.left => List.append(List.rev(rest), [{ left: s.left, right: max(site.right, s.right) }])
    | _ => List.append(leftSide, [site])
    };

    sites := switch (List.tl(rightSide)) {
    | tail => List.append(leftSide, tail)
    | exception Failure(_) => leftSide
    };
  };

  { crash, sites: () => sites^ };
};
