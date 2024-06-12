xquery version "3.1";

import module namespace app="http://exist.jmmc.fr/searchftt/apps/searchftt/templates" at "app.xql";


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
(: let $log := util:log("info", "sciences : " || string-join($sciences)) :)

(: rebuil association using resolved(or not) name instead of str_source_ids:)
let $targetInfos := map:merge((
    for $science in distinct-values($sciences)
        let $all-ftaos := array{ for $cat in $res?catalogs?*
            return
            try{ let $ranking := $cat?ranking
            let $targets-map := $cat?targets-map
            let $science-idx := $ranking?sciences-idx($science)
            let $scores := $ranking?scores?*
            let $science-idx := for $idx in $science-idx let $score:=$scores[$idx] where $score >= $config?min?score  order by $score descending return $idx

            let $science-ftaos :=
                for $idx at $pos in $science-idx
                let $ftao := $ranking?ftaos?*[position()=$idx]

                where  $pos <= $config?max?rank
                (: use resolved name of str_source_id values :)
                return array{ $targets-map($ftao?*[1])/name/text(), $targets-map($ftao?*[2])/name/text() }

            return $science-ftaos
            }catch *{
                () (: ignore cat without match :)
            }
        }
        (: limit science object with the one that have a solution :)
        where count($all-ftaos?*)>0
        (: get distinct fts and aos (this are str_source_ids resolved by targets-maps) :)
        (: don't consider science as AO or FT or themself waiting for a new SCGroup in Aspro :)
        let $science-fts  := for $ftao in $all-ftaos?* group by $ft := $ftao?*[1] where not ($science=$ft) return $ft
        let $science-aos  := for $ftao in $all-ftaos?* group by $ao := $ftao?*[2] where not ($science=$ao) return $ao
        return
            map:entry($science, map{ "ft-ids": $science-fts, "ao-ids": $science-aos})
    ))

let $fts-ids := $targetInfos?*?ft-ids
let $aos-ids := $targetInfos?*?ao-ids

(: prepare maps for Aspro2 sources description :)
let $all-identifiers := distinct-values( ( map:keys($targetInfos), $fts-ids, $aos-ids) )
let $targets-map := map:merge(($res?catalogs?*?targets-map, $res?identifiers-map)) (: last given map has the highest priority in this implementation :)
let $aspro-cols := $app:conf?aspro-cols

(: Ask for download using proper header and a suffix in filename :)
let $headers := response:set-header("Content-Disposition",' attachment; filename="SearchFTT_'|| app:getFileSuffix($identifiers) ||'.asprox"')

return

<a:observationSetting xmlns:a="http://www.jmmc.fr/aspro-oi/0.1" xmlns:tm="http://www.jmmc.fr/jmcs/models/0.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <schemaVersion>2018.04</schemaVersion>
    <!--Remove to propose coordinates refresh (may be part of a form parameter to add it) <targetVersion>2019.09</targetVersion>-->
    <name>SearchFTT generated</name>
    <description>This file has been generated by SearchFTT for
    {
        string-join(
        for $param in request:get-parameter-names() order by $param
        return
            for $v in request:get-parameter($param,()) return $param ||'='||encode-for-uri($v)
            ,"&amp;")
    }
    </description>
    <when>
        <date>{replace(current-date(),"Z","")}</date>
        <nightRestriction>true</nightRestriction>
        <atmosphereQuality>Average</atmosphereQuality>
    </when>
    {<!--<interferometerConfiguration>
        <name>VLTI Period 113</name>
        <minElevation>45.0</minElevation>
    </interferometerConfiguration>
    -->}
    <instrumentConfiguration>
        <name>GRAVITY</name>{
        <!--<stations>A0 G1 J2 J3</stations>
        <pops></pops>
        <instrumentMode>MEDIUM-COMBINED</instrumentMode>
        <samplingPeriod>60.0</samplingPeriod>
        <acquisitionTime>600.0</acquisitionTime>
        -->}
    </instrumentConfiguration>
    {
        for $targets in $targets-map?* group by $name := $targets/name/text()
            where $name=$all-identifiers
            let $target-id := app:genTargetIds($name)
            return
                let $target := $targets[1] return
                <target id="{$target-id}">
                    <name>{$name}</name>
                    <RA>{data($target/ra)}</RA>
                    <DEC>{data($target/dec)}</DEC>
                    <EQUINOX>2000.0</EQUINOX>
                    { let $ids := (
                        if($target/name != $target/user_identifier) then $target/user_identifier else ()
                        )
                        return if ($ids) then <IDS>{string-join($ids,", ")}</IDS> else ()
                    }
                    {if(empty($target/@fake-target)) then (<PMRA>{data($target/pmra)}</PMRA>,<PMDEC>{data($target/pmdec)}</PMDEC>)
                    else $target/*[name()=$aspro-cols?*]}
                </target>
                (: <PARALLAX>376.6801</PARALLAX>
                    <PARA_ERR>0.4526</PARA_ERR>
                    <IDS>2RXF J064508.6-164240,* alf CMa B,2E 1730,2RE J064509-164243,2RE J0645-164,8pc 379.21B,ADS 5423 B,BD-16 1591B,CCDM J06451-1643BC,CSI-16 1591 3,EGGR 49,GEN# +1.00048915B,GJ 244 B,H 0643-16,HD 48915B,IDS 06408-1635 B,RE J0645-16,RE J0645-164,RE J064509-164243,UBV 6710,WD 0642-163,WD 0643-16,WD 0642-16,WD 0642-166,Zkh 92,[BM83] X0642-166,1E 064255-1639.3,1ES 0642-16.6,2E 0642.9-1638,2EUVE J0645-16.7,EUVE J0645-16.7,WDS J06451-1643BC,** AGC 1BC,Gaia DR2 2947050466531873024,NAME Sirius C,NAME Sirius B,1RXS J064509.3-164241,1E 064255-1639.4,RX J0645.1-1642,NAME Sirius BC</IDS>
                    <OBJTYP>*,WD*,UV,X,**</OBJTYP>
                    <SPECTYP>DA1.9</SPECTYP>
                    <FLUX_V>8.0</FLUX_V>
                    <FLUX_R>8.0</FLUX_R>
                    <FLUX_H>8.0</FLUX_H>
                    <FLUX_K>8.0</FLUX_K>
                    <configuration>
                        <HAMin>-12.0</HAMin>
                        <HAMax>12.0</HAMax>
                        <aoSetup>NAOMI_BRIGHT</aoSetup>
                        <fringeTrackerMode>FringeTrack GRAVITY</fringeTrackerMode>
                    </configuration>
                :)
    }
    <targetUserInfos>
        <group id="JMMC_AO">
            <name>AO Star</name>
            <category>[OB]</category>
            <description>Group indicating stars used by the Adaptive Optics system</description>
            <color>#F781BF</color>
        </group>
        <group id="JMMC_FT">
            <name>FT Star</name>
            <category>[OB]</category>
            <description>Group gathering stars used by the Fringe Tracking system</description>
            <color>#75C147</color>
        </group>
        <group id="JMMC_GUIDE">
            <name>Guide Star</name>
            <category>[OB]</category>
            <description>Group indicating stars used by the telescope guiding</description>
            <color>#5BAFD6</color>
        </group>
        <groupMembers>
            <groupRef>JMMC_AO</groupRef>
            <targets>{ string-join(app:genTargetIds($aos-ids), " ") }</targets>
        </groupMembers>
        <groupMembers>
            <groupRef>JMMC_FT</groupRef>
            <targets>{ string-join(app:genTargetIds($fts-ids), " ") }</targets>
        </groupMembers>
        {
            map:for-each($targetInfos, function ($science,$science-map){
                let $science-fts:=$science-map?ft-ids[not(.=$science)]
                let $science-aos:=$science-map?ao-ids[not(.=$science)]
                return
                    <targetInfo>
                        <targetRef>{app:genTargetIds($science)}</targetRef>
                        <groupMembers>
                            <groupRef>JMMC_AO</groupRef>
                            <targets>{string-join(app:genTargetIds($science-aos), " ")}</targets>
                        </groupMembers>
                        <groupMembers>
                            <groupRef>JMMC_FT</groupRef>
                            <targets>{string-join(app:genTargetIds($science-fts), " ")}</targets>
                        </groupMembers>
                    </targetInfo>
            })

        }

    </targetUserInfos>
    <variant>
        <stations>UT1 UT2 UT3 UT4</stations>
    </variant>
</a:observationSetting>