// One row per term: how many token exchanges were granted and denied.
type outcome = Granted | Denied

type row = {term: string, granted: int, denied: int, last: outcome, seq: int}

type t = {rows: array<row>, seq: int}

let empty = {rows: [], seq: 0}

let record = (log, term, outcome) => {
  let seq = log.seq + 1
  let bump = row =>
    switch outcome {
    | Granted => {...row, granted: row.granted + 1, last: outcome, seq}
    | Denied => {...row, denied: row.denied + 1, last: outcome, seq}
    }
  let rows = switch log.rows->Array.find(row => row.term == term) {
  | Some(_) => log.rows->Array.map(row => row.term == term ? bump(row) : row)
  | None => log.rows->Array.concat([bump({term, granted: 0, denied: 0, last: outcome, seq})])
  }
  {rows, seq}
}

// Most recent activity first.
let recent = log => log.rows->Array.toSorted((a, b) => Int.toFloat(b.seq - a.seq))
