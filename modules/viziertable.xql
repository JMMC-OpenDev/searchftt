xquery version "3.1";

import module namespace app="http://exist.jmmc.fr/searchftt/apps/searchftt/templates" at "app.xql";
import module namespace jmmc-tap="http://exist.jmmc.fr/jmmc-resources/tap" at "/db/apps/jmmc-resources/content/jmmc-tap.xql";


(: TODO move next local function into jmmc:vizier module with a more generic way to ask for more columns :)


(:
 : Return RA,DEC, names as a sequence for a single catalog
 :  or a map{$cat:($ra,$dec) for multiple table names.
 :)
declare function local:get-RADEC-colnames($vizierTableIds as xs:string*){
let $in := string-join($vizierTableIds!concat("'",normalize-space(.),"'"),",")

(:  get RA DEC col_names ordered by ucd for every table ids :)
let $query := "
SELECT
  table_name, column_name
FROM
  TAP_SCHEMA.columns
WHERE
  table_name IN ("||$in||")
    AND
  ucd IN ('pos.eq.ra;meta.main','pos.eq.dec;meta.main','pos.eq.ra','pos.eq.dec')
ORDER BY
  ucd DESC
"

let $trs-vot := jmmc-tap:tap-adql-query("http://tapvizier.cds.unistra.fr/TAPVizieR/tap/sync", $query, -1)
let $trs := $trs-vot//*:TR

let $map := map:merge((  (:
    map:entry("tables", $vizierTableIds),
    map:entry("votable", $trs-vot),
    :)
    for $trg in $trs group by $table := ($trg/*:TD)[1]
        return
            if (count($trg) = 2) then (: assume RA DEC or main RA main DEC:)
                map:entry( $table, data($trg/*:TD[2]) )
            else map:entry($table,"error")
    ))
return if(count($vizierTableIds)) then $map?* else $map
};

declare function local:getCoords($tableId as xs:string)
{
    let $radec := local:get-RADEC-colnames($tableId)

    return
        if (count($radec)!=2) then (: throw error :) () else

    let $query := <query>SELECT {$radec[1]}, {$radec[2]} FROM &quot;{$tableId}&quot;</query>
    let $trs-vot := jmmc-tap:tap-adql-query("http://tapvizier.cds.unistra.fr/TAPVizieR/tap/sync", $query, app:config()?max?rows_from_vizier)
    let $trs := $trs-vot//*:TR
    return
        for $tr in $trs return string-join($tr!normalize-space(.), " ")
};

(:
 Format identifiers as a single string
 - store it as session attribute
 - put in session info or error
 - redirect for execution
:)
let $viziertable :=request:get-parameter("viziertable",())
let $log := util:log("info", "queriing VizieR for "|| $viziertable)
return
    if(empty($viziertable)) then () else
    let $identifiers := local:getCoords($viziertable)
    let $t-link := <a href='https://vizier.cds.unistra.fr/viz-bin/VizieR-3?-source={encode-for-uri($viziertable)}'>{$viziertable}</a>
    let $error := if(empty($identifiers)) then
            session:set-attribute('danger',<span>Sorry nothing found in the <em>{$t-link}</em> VizieR table</span>)
        else
            session:set-attribute('success',<span>Found {count($identifiers)} coordinates {"( max limit used )"[count($identifiers)=app:config()?max?rows_from_vizier]} in the <em>{$t-link}</em> VizieR Table.</span>)
    let $log := util:log("info", "identifiers found :  "|| count($identifiers))
    let $store := session:set-attribute('identifiers', string-join($identifiers, ';') )
    let $redirect := response:redirect-to(xs:anyURI("../bulk.html"))
    return <session-set>identifiers set for session {session:get-id()}</session-set>