xquery version "3.1";

import module namespace app="http://exist.jmmc.fr/searchftt/apps/searchftt/templates" at "app.xql";

(: This module filters inputs to identifiers that get one or more results for given constraints
    batch approach can then be done looking at sources with results using next principle:

    stilts tcat icmd='addcol pos concat(ra,\"\ \",dec) ; keepcols "pos"' in=example_quasars_forJMMC_n3000_with_stars.fits omode=out ofmt="csv(header=false)" | split -l 500 -d - batch.
    for batch in batch.* ; do echo "Processind $batch ..." ; curl -F inputfile=@${batch} "http://localhost:8080/exist/apps/searchftt/modules/outputfile.xql?min_score=0.1&max_rank=3" >> inputlist.csv ; echo "done"; done

    visit web site and upload inputlist.csv
 :)

(: Ask for download :)
let $headers := response:set-header("Content-Disposition",' attachment; filename="SearchFTT.csv"')

(: Get config :)
let $config := app:config()

(: Get form inputs :)
let $identifiers := request:get-parameter("identifiers",())
let $identifiers := if(exists($identifiers)) then $identifiers else replace(request:get-parameter("inputfile",()),"&#10;",";")
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
  string-join(("",$targets),"&#10;")

