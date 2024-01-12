xquery version "3.1";

import module namespace app="http://exist.jmmc.fr/searchftt/apps/searchftt/templates" at "app.xql";

(: Ask for download :)
let $headers := response:set-header("Content-Disposition",' attachment; filename="SearchFTT.asprox"')

(: Get form inputs :)
let $identifiers := request:get-parameter("identifiers",())
let $catalogs := request:get-parameter("catalogs",())

(: get conf TODO REMOVE IT :)
let $config := app:config()
let $max := $config("max")

let $catalogs := if(exists($catalogs)) then $catalogs else $config?preferred?bulk_catalog
let $res := app:searchftt-bulk-list($identifiers, $max, $catalogs)

(: res structure :
    - $res?identifiers-map : map {$identifier : id-info}
    - for each queried catalog :
        - $res?$catalogName :
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
:)


let $sciences-idx := $res?*?ranking?sciences-idx
let $ftaos := $res?*?ranking?ftaos
let $fts  := for $ftao in $ftaos?* group by $ft := ($ftao?*)[1] return $ft
let $aos  := for $ftao in $ftaos?* group by $ao := ($ftao?*)[2] return $ao

let $all-identifiers := distinct-values( ( for $m in $res?*?ranking?sciences-idx return map:keys($m), $fts, $aos) )

(: let $identifiers-map := map:merge( $res?identifiers-map , $res($catalogs)?targets-map ) :)
(: $res($catalogs)?targets-map, $res?identifiers-map :)

return
    (:  doc("../templates/GRAV_FT_AO.asprox")/* :)
<a:observationSetting xmlns:a="http://www.jmmc.fr/aspro-oi/0.1" xmlns:tm="http://www.jmmc.fr/jmcs/models/0.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <schemaVersion>2018.04</schemaVersion>
    <!--<targetVersion>2019.09</targetVersion>-->
    <name>SearchFTT generated</name>
    <when>
        <date>{replace(current-date(),"Z","")}</date>
        <nightRestriction>true</nightRestriction>
        <atmosphereQuality>Average</atmosphereQuality>
    </when>
    <!--<interferometerConfiguration>
        <name>VLTI Period 113</name>
        <minElevation>45.0</minElevation>
    </interferometerConfiguration>
    -->
    <instrumentConfiguration>
        <name>GRAVITY</name>
        <!--<stations>A0 G1 J2 J3</stations>
        <pops></pops>
        <instrumentMode>MEDIUM-COMBINED</instrumentMode>
        <samplingPeriod>60.0</samplingPeriod>
        <acquisitionTime>600.0</acquisitionTime>
        -->
    </instrumentConfiguration>
    {
        for $identifier in $all-identifiers
            let $target-id := app:genTargetIds($identifier)
            let $target := $res($catalogs)?targets-map($identifier)
            let $target := if($target) then $target else $res?identifiers-map($identifier)
            return
                <target id="{$target-id}">
                    <name>{$identifier}</name>
                    <RA>{data($target/ra)}</RA>
                    <DEC>{data($target/dec)}</DEC>
                    <EQUINOX>2000.0</EQUINOX>
                    <PMRA>{data($target/pmra)}</PMRA>
                    <PMDEC>{data($target/pmdec)}</PMDEC>
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
    <!--
    can be removed
    <selectedTargets>Sirius_B</selectedTargets>
    -->
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
            <targets>{ string-join(app:genTargetIds($aos), " ") }</targets>
        </groupMembers>
        <groupMembers>
            <groupRef>JMMC_FT</groupRef>
            <targets>{ string-join(app:genTargetIds($fts), " ") }</targets>
        </groupMembers>
        {
            for $science in map:keys($sciences-idx)
            let $indices := $sciences-idx($science)
            let $s_fts := $fts[$indices=position()]
            let $s_aos := $aos[$indices=position()]

            return
                <targetInfo>
                    <targetRef>{app:genTargetIds($science)}</targetRef>
                    <groupMembers>
                        <groupRef>JMMC_AO</groupRef>
                        <targets>{string-join(app:genTargetIds($s_aos), " ")}</targets>
                    </groupMembers>
                    <groupMembers>
                        <groupRef>JMMC_FT</groupRef>
                        <targets>{string-join(app:genTargetIds($s_fts), " ")}</targets>
                    </groupMembers>
                </targetInfo>
        }
    </targetUserInfos>
    <variant>
        <stations>UT1 UT2 UT3 UT4</stations>
    </variant>
</a:observationSetting>


