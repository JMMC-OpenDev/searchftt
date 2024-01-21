xquery version "3.1";

import module namespace app="http://exist.jmmc.fr/searchftt/apps/searchftt/templates" at "app.xql";

(: Ask for download :)
let $headers := response:set-header("Content-Disposition",' attachment; filename="SearchFTT.csv"')

(: Get config :)
let $config := app:config()

(: Get form inputs :)
let $identifiers := request:get-parameter("identifiers",())
let $catalogs := request:get-parameter("catalogs",())

(: compute lists :)
let $res := app:searchftt-bulk-list($identifiers, $catalogs)

(: gather results :)
let $sciences-idx := $res?catalogs?*?ranking?sciences-idx
let $sciences := distinct-values(for $m in $sciences-idx return map:keys($m))

let $targets :=
    for $science in distinct-values($sciences)
        for $ranking in $res?catalogs?*?ranking
            let $science-idx := $ranking?sciences-idx($science)
            let $scores := $ranking?scores?*
            let $science-ok := for $idx in $science-idx let $score:=$scores[$idx] where $score >= $config?min?score  return $science
            return
                 if( exists($science-ok) ) then $science else ()

let $targets := distinct-values($targets)

(: output one science line by one
 - should we pu an # header ? :)
return
  string-join($targets,"&#10;")

