xquery version "3.1";

import module namespace app="http://exist.jmmc.fr/searchftt/apps/searchftt/templates" at "app.xql";
import module namespace jmmc-tap="http://exist.jmmc.fr/jmmc-resources/tap" at "/db/apps/jmmc-resources/content/jmmc-tap.xql";


(: TODO move next local function into jmmc:vizier module :)


declare function local:getTables($vizierTablePrefix as xs:string){
let $query := "
SELECT
  *
FROM
  TAP_SCHEMA.tables
WHERE
  table_name LIKE '"||$vizierTablePrefix||"%'
"

let $votable := jmmc-tap:tap-adql-query("http://tapvizier.cds.unistra.fr/TAPVizieR/tap/sync", $query, -1)
let $trs := $votable//*:TR
(: schema_name	table_name	table_type	description	utype	nrows :)
let $colidx := map:merge( for $e at $pos in $votable//*:FIELD/@name return map:entry($e, $pos) )
return
  map:merge((
    for $tr in $trs
      return
        map:entry($tr/*[$colidx?table_name], map:merge(( map:for-each($colidx, function ($col, $pos){map:entry($col, data($tr/*[$pos]))}) )) )
  ))
};

(:
 : Return as a map for every requested catalogs with ra,dec,name if found
 :  or a map{$cat:($ra,$dec) for multiple table names.
 :)
declare function local:getNameOrCoordColnames($vizierTableIds as xs:string*){
let $in := string-join($vizierTableIds!concat("'",normalize-space(.),"'"),",")

let $ucds4cols := map{
  "ra":('pos.eq.ra;meta.main','pos.eq.ra')
  ,"dec":('pos.eq.dec;meta.main','pos.eq.dec')
  ,"name": 'meta.id;meta.main'
  }
(:  get col_names ordered by ucds for every table ids :)
let $query := "
SELECT
  table_name, column_name, ucd
FROM
  TAP_SCHEMA.columns
WHERE
  table_name IN ("||$in||")
    AND
  ucd IN ("|| string-join($ucds4cols?* ! concat("'",.,"'") , ", ")||")
ORDER BY
  ucd DESC
"

let $trs-vot := jmmc-tap:tap-adql-query("http://tapvizier.cds.unistra.fr/TAPVizieR/tap/sync", $query, -1)
let $trs := $trs-vot//*:TR

(: group by table names and use head() to get first column that matches the ucds :)
return
  map:merge((
    for $trg in $trs group by $table := ($trg/*:TD)[1]
      return
        map:merge(for $col in map:keys($ucds4cols) return map:entry($col, head( $trg[./*[3]=$ucds4cols($col)]/*[2] ) ))
  ))
};

declare function local:getNamesOrCoords($tableId as xs:string)
{
    let $colinfo := local:getNameOrCoordColnames($tableId)
    (: let $log := util:log("info", "Searching idorcoord cols in '"|| $tableId ||"' with '"||serialize($colinfo,map {"method": "adaptive"})||"'") :)

    let $query := if ( exists($colinfo?name)) then
          <query>SELECT {$colinfo?name} FROM &quot;{$tableId}&quot;</query>
        else if (exists($colinfo?ra) and exists($colinfo?dec))  then
          <query>SELECT {$colinfo?ra}, {$colinfo?dec} FROM &quot;{$tableId}&quot;</query>
        else ()

    return
        if ($query) then
          let $trs-vot := jmmc-tap:tap-adql-query("http://tapvizier.cds.unistra.fr/TAPVizieR/tap/sync", $query, app:config()?max?rows_from_vizier)
          let $trs := $trs-vot//*:TR
          return
            for $tr in $trs return string-join($tr!normalize-space(.), " ")
        else ()
};

(:
 Format identifiers as a single string
 - store it as session attribute
 - put in session info or error
 - redirect for execution
:)
let $viziertable :=request:get-parameter("viziertable",())
let $log := util:log("info", "quering VizieR for "|| $viziertable)
return
    if(empty($viziertable)) then () else
    let $identifiers := local:getNamesOrCoords($viziertable)
    let $t-link := <a href='https://vizier.cds.unistra.fr/viz-bin/VizieR-3?-source={encode-for-uri($viziertable)}'>{$viziertable} VizieR table</a>
    let $error := if(empty($identifiers)) then
            session:set-attribute('danger',<span>Sorry no coordinates or identifiers found in the <em>{$t-link}</em> <br/>
            {
              let $tables := local:getTables($viziertable)?*
              return
                (
                  "But you may try with :",
                  <ul>
                  { for $table in $tables return <li><a href="modules/viziertable.xql?viziertable={encode-for-uri($table?table_name)}">{$table?table_name}</a> - {$table?description} ({$table?nrows} rows) </li>}
                  </ul>
                )
            }
            </span>)
        else
            session:set-attribute('success',<span>Found {count($identifiers)} coordinates {"( max limit used )"[count($identifiers)=app:config()?max?rows_from_vizier]} in the <em>{$t-link}</em> VizieR Table.</span>)
    let $log := util:log("info", "identifiers found :  "|| count($identifiers))
    let $store := session:set-attribute('identifiers', string-join($identifiers, ';') )
    let $redirect := response:redirect-to(xs:anyURI("../bulk.html"))
    return <session-set>identifiers set for session {session:get-id()}</session-set>