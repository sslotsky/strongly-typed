// One row per resource: granted and denied token exchanges, newest first.
@react.component
let make = (~log: Audit.t, ~copy: Theme.logCopy) => {
  let rows = Audit.recent(log)
  <aside className="audit" ariaLabel={copy.title}>
    <header className="audit__header">
      <span className="audit__title"> {copy.title->React.string} </span>
      <span className="audit__count"> {`${Int.toString(log.seq)} events`->React.string} </span>
    </header>
    <div className="audit__columns">
      <span> {copy.subject->React.string} </span>
      <span className="audit__num"> {copy.granted->React.string} </span>
      <span className="audit__num"> {copy.denied->React.string} </span>
    </div>
    {Array.length(rows) == 0
      ? <p className="audit__empty"> {copy.empty->React.string} </p>
      : <ol className="audit__rows">
          {rows
          ->Array.map(row => {
            let outcome = switch row.last {
            | Granted => "granted"
            | Denied => "denied"
            }
            let latest = row.seq == log.seq ? " audit__row--latest" : ""
            <li key={row.term} className={`audit__row audit__row--${outcome}${latest}`}>
              <span key={Int.toString(row.seq)} className="audit__flash" />
              <span className="audit__term">
                <span className="audit__dot" title={outcome} />
                {row.term->React.string}
              </span>
              <span className="audit__num audit__granted">
                {row.granted->Int.toString->React.string}
              </span>
              <span className="audit__num audit__denied">
                {row.denied->Int.toString->React.string}
              </span>
            </li>
          })
          ->React.array}
        </ol>}
  </aside>
}
