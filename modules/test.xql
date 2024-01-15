xquery version "3.1";
import module namespace app="http://exist.jmmc.fr/searchftt/apps/searchftt/templates" at "app.xql";


<test>
{
    for $param in request:get-parameter-names() order by $param
        return <parameter><name>{$param}</name>{for $v in request:get-parameter($param,()) return <value>{$v}</value>}</parameter>
    ,

    let $identifiers := request:get-parameter("identifiers",())
    let $catalogs := request:get-parameter("catalogs",())
    let $config := app:config()
    let $res := app:searchftt-bulk-list($identifiers, $catalogs)

    (: res structure :
        - $res?identifiers-map : map {$identifier : id-info}
        - $res?catalogs :
            map { $res?$catalogName :
                map {
                    "error" : htmlerror
                    "votable":$votable
                      or
                    "votable":$votable
                    "html" : $html
                    "targets-map" : map {$identifier : id-info}
                    "ranking : map {
                        "error": $error
                        "query" : $query
                        "sciences-idx" : map { $science-id : array{ $pos-idx } }
                        "input-params" : array { $colnames }
                        "inputs" : array { $colvalues_of_colnames }
                        "ftaos" : array { [ft1, ao1], ... [ftn, aon] }
                        "scores" : array { $scores }
                        }
                    }
                }
    :)

    let $sciences := $res?identifiers-map
    let $scores := $res?catalogs?*?ranking?scores
    let $targets-map := $res($catalogs)?targets-map
    let $ftaos := $res?catalogs?*?ranking?ftaos
    let $fts  := for $ftao in $ftaos?* group by $ft := ($ftao?*)[1] return $ft
    let $aos  := for $ftao in $ftaos?* group by $ao := ($ftao?*)[2] return $ao

    return
        (
            $catalogs,
            <count-scores/>,
            count($scores),
            <count-ftaos/>,
            count($ftaos),
            <scores/>,
            serialize($scores, map {"method": "adaptive"}),
            <ftaos/>,
            serialize($ftaos, map {"method": "adaptive"}),
            <sciences/>,
            serialize($sciences, map {"method": "json"}),
            <targets-map/>,
            serialize($targets-map, map {"method": "json"}),
            <fts/>,
            $fts,
            <aos/>,
            $aos,
            (: : )
             serialize($res, map {"method": "json"}),
            ( : :)
            ()
        )

}
</test>