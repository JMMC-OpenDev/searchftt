xquery version "3.1";

(:~ This is the default application library module of the searchftt app.
 :
 : @author JMMC Tech Group
 : @see https://www.jmmc.fr
 :)

(: Module for app-specific template functions :)
module namespace app="http://exist.jmmc.fr/searchftt/apps/searchftt/templates";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";
import module namespace config="http://exist.jmmc.fr/searchftt/apps/searchftt/config" at "config.xqm";

import module namespace jmmc-tap="http://exist.jmmc.fr/jmmc-resources/tap" at "/db/apps/jmmc-resources/content/jmmc-tap.xql";
import module namespace jmmc-simbad="http://exist.jmmc.fr/jmmc-resources/simbad" at "/db/apps/jmmc-resources/content/jmmc-simbad.xql";
(:import module namespace jmmc-astro="http://exist.jmmc.fr/jmmc-resources/astro" at "/db/apps/jmmc-resources/content/jmmc-astro.xql";:) (: WARNING this module require to enable eXistDB's Java Binding :)

(: Main config to unify catalog accross their colnames  - we could try to put Simbad inside ? :)
declare variable $app:json-conf :='{
    "default":{
        "max_magV" : 15,
        "max_magK_UT" : 11,
        "max_magK_AT" : 10,
        "max_magR" : 12.5,
        "max_dist_as" : 30,
        "max_rec" : 25
    },
    "extended-cols" : [ "pmra", "pmdec", "pmde", "epoch", "cat_dist_as", "today_dist_as"],
    "samestar-dist_deg" : 2.78E-4,
    "samestar-dist_as" : 1,
    "catalogs":{
        "simcat": {
            "cat_name":"Simbad",
            "main_cat":true,
            "description": "CDS / Simbad",
            "tap_endpoint": "http://simbad.u-strasbg.fr/simbad/sim-tap/sync",
            "tap_format" : "",
            "tap_viewer" : "",
            "simbad_prefix_id" : "",
            "source_id": "basic.main_id",
            "epoch"   : 2000,
            "ra"      : "basic.ra",
            "dec"     : "basic.dec",
            "pmra"    : "basic.pmra",
            "pmdec"   : "basic.pmdec",
            "mag_k"   : "allfluxes.K",
            "mag_g"   : "allfluxes.G",
            "mag_bp"  : "",
            "mag_rp"  : "",
            "mag_v"  : "allfluxes.V",
            "mag_r"  : "allfluxes.R",
            "detail"      : { "otype_txt":"otype_txt" },
            "from"    : "basic JOIN allfluxes ON oid=oidref"
        },
        "gdr2ap": {
            "cat_name":"GDR2AP",
            "main_cat":false,
            "description": "The <a href=&apos;https://ui.adsabs.harvard.edu/abs/2022arXiv220103252F/abstract&apos;>Astrophysical Parameters from Gaia DR2, 2MASS &amp;amp; AllWISE</a>  catalog through the GAVO DC.",
            "tap_endpoint": "https://dc.zah.uni-heidelberg.de/tap/sync",
            "tap_format" : "",
            "tap_viewer" : "http://dc.g-vo.org/__system__/adql/query/form?__nevow_form__=genForm&amp;_FORMAT=HTML&amp;submit=Go&amp;query=",
            "simbad_prefix_id" : "Gaia DR2 ",
            "source_id":"gaia.dr2light.source_id",
            "epoch"   : 2015.5,
            "ra"      :"gaia.dr2light.ra",
            "dec"     :"gaia.dr2light.dec",
            "pmra"    : "pmra",
            "pmdec"   : "pmdec",
            "old_pos_others" : "(-15.5*pmra/1000.0) as delta_ra2000_as, (-15.5*pmdec/1000.0) as delta_de2000_as, (ra-15.5*pmra/3600000.0) as RA2000, (dec-15.5*pmdec/3600000.0) as de2000",
            "mag_k"   : "mag_ks",
            "mag_g"   : "mag_g",
            "mag_bp"  : "mag_bp",
            "mag_rp"  : "mag_rp",
            "detail"  : { },
            "from"    : "gaia.dr2light JOIN gdr2ap.main ON gaia.dr2light.source_id=gdr2ap.main.source_id"
        },"esagaia3": {
            "enable" : true,
            "cat_name"    : "Gaia DR3",
            "main_cat":true,
            "description" : "Gaia DR3 catalogues and cross-matched catalogues though <a href=&apos;https://www.cosmos.esa.int/web/gaia-users/archive&apos;>ESA archive center</a>.",
            "tap_endpoint" : "https://gea.esac.esa.int/tap-server/tap/sync",
            "tap_format"   : "votable_plain",
            "tap_viewer"   : "",
            "simbad_prefix_id" : "Gaia DR3 ",
            "source_id"   :"gaia.source_id",
            "epoch"   : 2016.0,
            "ra"          : "gaia.ra",
            "dec"         : "gaia.dec",
            "pmra"        : "gaia.pmra",
            "pmdec"       : "gaia.pmdec",
            "mag_k"  : "tmass.ks_m",
            "mag_g"  : "gaia.phot_g_mean_mag",
            "mag_bp" : "gaia.phot_bp_mean_mag",
            "mag_rp" : "gaia.phot_rp_mean_mag",
            "detail"      : { "tmass.h_m":"H_mag", "tmass_nb.angular_distance":"tmass_dist", "tmass.designation":"J_2MASS" },
            "from"        : "gaiadr3.gaia_source as gaia JOIN gaiaedr3.tmass_psc_xsc_best_neighbour AS tmass_nb USING (source_id) JOIN gaiaedr3.tmass_psc_xsc_join AS xjoin    ON tmass_nb.original_ext_source_id = xjoin.original_psc_source_id JOIN gaiadr1.tmass_original_valid AS tmass ON xjoin.original_psc_source_id = tmass.designation"
        },"esagaia2": {
            "cat_name"    : "Gaia DR2",
            "main_cat":false,
            "description" : "Gaia DR2 catalogues <a href=&apos;https://arxiv.org/pdf/1808.09151.pdf&apos;>with its external catalogues cross-match</a> though <a href=&apos;https://gea.esac.esa.int/archive/&apos;>ESA archive center</a>.",
            "tap_endpoint" : "https://gea.esac.esa.int/tap-server/tap/sync",
            "tap_format"   : "votable_plain",
            "tap_viewer"   : "",
            "simbad_prefix_id" : "Gaia DR2 ",
            "source_id"   :"gaia.source_id",
            "epoch"   : 2015.5,
            "ra"          : "gaia.ra",
            "dec"         : "gaia.dec",
            "pmra"        : "gaia.pmra",
            "pmdec"       : "gaia.pmdec",
            "mag_k"  : "tmass.ks_m",
            "mag_g"  : "gaia.phot_g_mean_mag",
            "mag_bp" : "gaia.phot_bp_mean_mag",
            "mag_rp" : "gaia.phot_rp_mean_mag",
            "detail"      : { "tmass.h_m":"H_mag", "tmass_nb.angular_distance":"tmass_dist", "tmass.designation":"J_2MASS" },
            "from"        : "gaiadr2.gaia_source as gaia JOIN gaiadr2.tmass_best_neighbour as tmass_nb USING (source_id) JOIN gaiadr1.tmass_original_valid as tmass ON tmass.tmass_oid = tmass_nb.tmass_oid"
        },"gsc": {
            "cat_name"    : "GSC2",
            "main_cat":true,
            "description" : "<a href=&apos;https://cdsarc.cds.unistra.fr/viz-bin/cat/I/353&apos;>The Guide Star Catalogue, Version 2.4.2 (2020)</a>",
            "tap_endpoint" : "http://tapvizier.cds.unistra.fr/TAPVizieR/tap/sync",
            "tap_format"   : "",
            "tap_viewer"   : "",
            "simbad_prefix_id" : "GSC2 ",
            "source_id"   :"GSC2",
            "epoch"   : "Epoch",
            "ra"          : "RA_ICRS",
            "dec"         : "DE_ICRS",
            "pmra"    : "pmRA",
            "pmdec"   : "pmDE",
            "mag_k"  : "Ksmag",
            "mag_r" : "rmag",
            "mag_g"  : "",
            "mag_bp" : "",
            "mag_rp" : "",
            "mag_v"  : "Vmag",
            "mag_r"  : "rmag",
            "detail"      : { },
            "from"        : "I/353/gsc242"
        }
    }
}';

declare variable $app:conf := parse-json($app:json-conf);

(:~
 : Build a map with default value comming from given config or overidden by user params.
 : Caller will use it as $max?keyname to retrieve $conf?max_keyname or max_keyname parameter
 : map will be populated by  keyname_info entries so we can display overriden param.
 : @return a map with default or overriden values to use in the application.
:)
declare function app:defaults() as map(*){
    map:entry("max", map:merge(
        for $key in map:keys($app:conf?default) where starts-with($key, "max")
            let $map-max-key:=replace($key, "max_", "")
            let $map-info-key:=$map-max-key||"_info"
            let $param := try{ xs:double( request:get-parameter($key, "") ) }catch * { () }
            let $conf := xs:double($app:conf?default($key))
            let $mapinfo:= if( exists($param) and ( $param != $conf)) then <mark title="overridden by user : default conf is {$conf}">{$param}</mark> else $conf
            let $mapvalue:= if( exists($param) ) then $param else $conf
            return ( map:entry($map-max-key, $mapvalue), map:entry($map-info-key, $mapinfo))
    ))
};

declare %templates:wrap function app:dyn-nav-li($node as node(), $model as map(*), $identifiers as xs:string*) {
    let $toggle-classes := map{ "extcats" : "extended catalogs", "extcols" : "extended columns", "extquery" : "queries", "exttable" : "hide table", "extorphan" : "hide orphan", "extdebug" : "debug" }
    return
        <li class="nav-link">{
            map:for-each( $toggle-classes, function ($k, $label) {
                <div class="form-check form-check-inline form-switch nav-orange">
                    <input class="form-check-input" type="checkbox" onClick='$(".{$k}").toggleClass("d-none");'/><label class="form-check-label">{$label}</label>
                </div>
            })
        }</li>[exists($identifiers)]
};


declare %templates:wrap function app:form($node as node(), $model as map(*), $identifiers as xs:string*, $format as xs:string*) {
    let $max := app:defaults()("max")
    let $params :=  for $p in request:get-parameter-names()[.!="identifiers"] return <input type="hidden" name="{$p}" value="{request:get-parameter($p,' ')}"/>
    return
    (
    <div>
        <h1>GRAVITY-wide: finding off-axis fringe tracking targets.</h1>
        <p>This newborn tool is in its first versions and is subject to various changes in its early development phase.</p>
        <h2>Underlying method:</h2>
        <p>
            You can query one or several Science Targets. For each of them, suitable ringe Tracker Targets will be given using following research methods: <br/>
            <ul>
                <li>Main catalogs<ul>{ for $cat in $app:conf?catalogs?* where $cat?main_cat return <li><b>{$cat?cat_name}</b>&#160;{parse-xml("<span>"||$cat?description||"</span>")}</li>}</ul></li>
                {if ( false() = $app:conf?catalogs?*?main_cat ) then <li>Additionnal catalogs (use toggle button in the menu to get result tables)<ul>{ for $cat in $app:conf?catalogs?* where not($cat?main_cat) return <li><b>{$cat?cat_name}</b>&#160;{parse-xml("<span>"||$cat?description||"</span>")}</li>}</ul></li> else ()}
            </ul>
            Each query is performed within {$max?dist_as_info}&apos;&apos; of the Science Target.
            A magnitude filter is applied on every Fringe Tracker Targets according to the best limits offered in P110
            for <b>UT (MACAO) OR AT (NAOMI)</b>  respectively <b>( K &lt; {$max?magK_UT_info} AND V &lt; {$max?magV_info} ) OR ( K &lt; {$max?magK_AT_info} AND R&lt;{$max?magR_info} )</b>.
            When missing, the V and R magnitudes are computed from the Gaia G, Grb and Grp magnitudes.
            The user must <b>refine its target selection</b> to take into account <a href="https://www.eso.org/sci/facilities/paranal/instruments/gravity/inst.html">VLTI Adaptive Optics specifications</a> before we offer a configuration selector in a future release.
        </p>
        <p>
            <ul>
                <li>Enter comma separated names ( SearchFTT will try to resolve it using <a href="http://simbad.u-strasbg.fr">Simbad</a> ) or coordinates (RA +/-DEC in degrees J2000), in the TextBox below.</li>
                <li>Move your pointer to the column titles of the result tables to get the column descriptions.</li>
                <li>To send a target to <a href="https://www.jmmc.fr/getstar">Aspro2</a> (already open), click on the icon in the <a href="https://www.jmmc.fr/getstar">GetStar</a> column, then press "Send Votable".</li>
                <li>Please <a href="http://www.jmmc.fr/feedback">fill a report</a> for any question or remark.</li>
            </ul>
        </p>
        <form>
            <div class="p-3 input-group mb-3 ">
                <input type="text" class="form-control" placeholder="Science identifiers (comma separated)" aria-label="Science identifiers (comma separated)" aria-describedby="b2"
                id="identifiers" name="identifiers" value="{$identifiers}" required=""/>
                <button class="btn btn-outline-secondary" type="submit" id="b2"><i class="bi bi-search"/></button>
            </div>
            {$params}
        </form>
    </div>
    ,
    if (exists($identifiers)) then (
        app:searchftt-list($identifiers, $max),
        <script type="text/javascript">
        $(document).ready(function() {{
        $('.datatable').DataTable( {{
            "paging": false,"searching":false,"info": false,"order": []
        }});

        }});
        </script>

        ) else ()
    )
};

(:~
 : Resolve name using simbad or forge the same response if coordinates are detected.
 :
 : @param $name-or-coords name or coordinates
 : @return an xml node with name and coordinates
 :)
declare function app:resolve-by-name($name-or-coords) {
    if (matches($name-or-coords, "[a-z]", "i"))
    then
        jmmc-simbad:resolve-by-name($name-or-coords)
    else
        let $coord := $name-or-coords => replace( "\+", " +") => replace ("\-", " -")
        let $t := for $e in tokenize($coord, " ")[string-length(.)>0]  return $e
        return <s position-only="y"><name>{normalize-space($name-or-coords)}</name><ra>{$t[1]}</ra><dec>{$t[2]}</dec><pmra>0.0</pmra><pmdec>0.0</pmdec></s>
};


declare function app:searchftt-list($identifiers as xs:string, $max as map(*) ) {

    let $fov_deg := 3 * $max?dist_as div 3600

    let $ids := distinct-values($identifiers ! tokenize(., ",") ! tokenize(., ";")!normalize-space(.))[string-length()>0]
    let $count := count($ids)
    let $lis :=
        for $id at $pos in $ids
        let $log := util:log("info", <txt>loop {$pos} / {$count}</txt>)
        let $s := app:resolve-by-name($id)
        let $simbad-link := if($s/@position-only) then <a target="_blank" href="http://simbad.u-strasbg.fr/simbad/sim-coo?Coord={encode-for-uri($id)}&amp;CooEpoch=2000&amp;CooEqui=2000&amp;Radius={$app:conf?samestar-dist_as}&amp;Radius.unit=arcsec">{$id}</a> else <a target="_blank" href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($id)}">{$id}</a>
        let $ra := $s/ra let $dec := $s/dec
        let $info := if(exists($s/ra))then
                <ul class="list-group">
                    {
                        for $cat in $app:conf?catalogs?* (: where $cat?enable = true() :) order by $cat?main_cat descending return
                            <li class="list-group-item d-flex justify-content-between align-items-start {if($cat?main_cat) then () else "extcats d-none"}">
                                <div class="ms-2 me-auto">{app:search($id, $max, $s, $cat)}</div>
                            </li>
                    }
                </ul>
            else
                <div>Can&apos;t get position from Simbad, please check your identifier.</div>
        let $state := if(exists($info//table)) then "success" else if(exists($s/ra)) then "warning" else "danger"
        let $orphan := if (exists($info//table)) then () else "extorphan"
        return
            <div class="{$orphan}"><ul class="p-1 list-group">
                <li class="list-group-item list-group-item-{$state}">
                    <div class="">
                        <div class="row">
                            <div class="col"><b>{$simbad-link}</b>
                            <br/>ICRS coord. [deg] (ep=J2000) : {$ra}&#160;{$dec}
                            <br/>Proper motions [mas/yr] : {$s/pmra}&#160;{$s/pmdec}
                            <br/>
                            {
                                for $e in $info//*[@data-found-targets]
                                let $count := data($e/@data-found-targets)
                                let $class := if ($count > 0) then "success" else "warning"
                                return (
                                    <span class="btn btn-{$class} "><span class="badge rounded-pill bg-dark">{$count}</span>&#160;{data($e/@data-src-targets)}</span>, "&#160;"
                                    )
                            }
                            </div>
                                { if (count($ids) < 20 and exists($s/ra)) then
                                    <div class="col d-flex flex-row-reverse">
                                        <div id="aladin-lite-div{$pos}" style="width:200px;height:200px;"></div>
                                        <script type="text/javascript">
                                            var aladin = A.aladin('#aladin-lite-div{$pos}', {{survey: "P/2MASS/H", fov:{$fov_deg}, target:"{$id}" }});
                                        </script>
                                    </div>
                                    else ()
                                }
                        </div>
                        <div class="row exttable">
                            { $info }
                        </div>
                    </div>
                </li>
            </ul></div>

    let $merged-table :=
        <table class="table table-light datatable">
            <thead><th>Science</th>{($lis//thead)[1]//th}</thead>
            {
                for $table in $lis//table
                    for $tr in $table//tr[td]
                        return <tr><td>{data($table/@data-science)}</td>{$tr/td}</tr>
            }
        </table>

    return
        <div>
            <script type="text/javascript" src="https://aladin.u-strasbg.fr/AladinLite/api/v2/latest/aladin.min.js" charset="utf-8"></script>
            <ul class="nav nav-tabs" id="myTab" role="tablist">
                <li class="nav-item" role="presentation">
                    <button class="nav-link active" id="home-tab" data-bs-toggle="tab" data-bs-target="#home-tab-pane" type="button" role="tab" aria-controls="home-tab-pane" aria-selected="true">Result list</button>
                </li>
                <li class="nav-item" role="presentation">
                    <button class="nav-link" id="profile-tab" data-bs-toggle="tab" data-bs-target="#profile-tab-pane" type="button" role="tab" aria-controls="profile-tab-pane" aria-selected="false">Merged table</button>
                </li>
            </ul>
            <div class="tab-content" id="myTabContent">
            <div class="tab-pane fade show active" id="home-tab-pane" role="tabpanel" aria-labelledby="home-tab" tabindex="0">{$lis}</div>
            <div class="tab-pane fade" id="profile-tab-pane" role="tabpanel" aria-labelledby="profile-tab" tabindex="0">{$merged-table}</div>
            </div>
        </div>
};

declare function app:search($id, $max, $s, $cat) {
   	let $log := util:log("info", "searching single ftt in "||$cat?cat_name||" ...")
	let $query := app:build-query($id, (), $max, $cat)
    let $votable := try{if(exists(request:get-parameter("dry", ()))) then <error>dry run : remote query SKIPPED ! </error> else jmmc-tap:tap-adql-query($cat?tap_endpoint,$query, $max?rec, $cat?tap_format) }catch * {util:log("error", serialize($err:value)), $err:value}
    let $votable-url := jmmc-tap:tap-adql-query-uri($cat?tap_endpoint,$query, $max?rec, $cat?tap_format)
    let $query-code := <div class="extquery d-none"><pre><br/>{data($query)}</pre><a target="_blank" href="{$votable-url}">get original votable</a></div>
	let $src := if ($cat?tap_viewer)  then <a class="extquery d-none" href="{$cat?tap_viewer||encode-for-uri($query)}">View original votable</a> else ()
    let $log := util:log("info", "done")
    return

    if(exists($votable//*:TABLEDATA/*)) then
        let $detail_cols := for $e in (array:flatten($app:conf?extended-cols), $cat?detail?*) return lower-case($e) (: values correspond to column names given by AS ...:)
        let $field_names := for $e in $votable//*:FIELD/@name return lower-case($e)
        let $source_id_idx := index-of($field_names, "source_id")
        let $tr-count := count($votable//*:TABLEDATA/*)
        return
        <div class="table-responsive">
            <table class="table table-light datatable" data-found-targets="{$tr-count}" data-src-targets="{$cat?cat_name}" data-science="{$s/name}">
                <thead><tr>
                    {for $f at $cpos in $votable//*:FIELD return
                        if ($cpos != $source_id_idx) then
                            let $title := if("cat_dist_as"=$f/@name) then "Distance computed moving science star to the catalog epoch using its proper motion"
                                else if("j2000_dist_as"=$f/@name) then "Distance computed moving candidates to J2000"
                                else if("today_dist_as"=$f/@name) then "Distance computed moving science star and candidates to current year epoch"
                                else $f/*:DESCRIPTION
                            let $name := if(starts-with($f/@name, "computed_")) then replace($f/@name, "computed_", "") else data($f/@name)
                            let $name :=  replace($name, "j_2mass", "2MASS&#160;J")
                            let $name :=if (ends-with($name, "_as")) then replace($name, "_as", "") else data($name)
                            let $unit :=if (ends-with($f/@name, "_as")) then "[arcsec]" else if(starts-with($f/@name, "computed_")) then "(computed)" else if (data($f/@unit)) then "["|| $f/@unit ||"]" else ()

                            return
                            <th title="{$title}">{if($field_names[$cpos]=$detail_cols) then attribute {"class"} {"d-none extcols table-primary"} else ()}{$name} &#160; {$unit}</th>
                        else
                            <th><span class="badge rounded-pill bg-dark">{$tr-count}</span>&#160;Simbad&#160;link&#160;for&#160;<u>{$cat?cat_name}</u></th>
                    }
                    <th>GetStar</th>
                </tr></thead>
                {
                    for $tr in $votable//*:TABLEDATA/* return
                        <tr>{
                            let $simbad_id := $cat?simbad_prefix_id||$tr/*[$source_id_idx]
                            let $simbad := jmmc-simbad:resolve-by-name($simbad_id)
                            let $target_link := if ($simbad/ra) then <a href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($simbad_id)}">{replace($simbad/name," ","&#160;")}</a> else
                                let $ra := $tr/*[index-of($field_names, "ra")]
                                let $dec := $tr/*[index-of($field_names, "dec")]
                                return <a href="http://simbad.u-strasbg.fr/simbad/sim-coo?Coord={$ra}+{$dec}&amp;CooEpoch=2000&amp;CooEqui=2000&amp;Radius={$app:conf?samestar-dist_as}&amp;Radius.unit=arcsec" title="Using coords because Simbad does't know : {$simbad_id}">{replace($simbad_id," ","&#160;")}</a>
                            let $getstar-url := "https://apps.jmmc.fr/~sclws/getstar/sclwsGetStarProxy.php?star="||encode-for-uri($simbad/name)
                            let $getstar-link := if ($simbad/ra) then <a href="{$getstar-url}" target="_blank"><i class="bi bi-box-arrow-up-right"></i></a>  else "-"
                            return
                                (
                                    <td>{$target_link}</td>,
                                    for $td at $cpos in $tr/* where $cpos != 1 return
                                        element {"td"} {attribute {"class"} {if( $field_names[$cpos]=$detail_cols ) then "d-none extcols table-primary" else ()},try { let $d := xs:double($td) return format-number($d, "0.###") } catch * { if(string-length($td)>1) then data($td) else "-" }},
                                    <td>{$getstar-link}<!--{$getstar-votable//*:TABLEDATA/*:TR/*:TD[121]/text()}--></td>
                                )
                        }</tr>
                }
            </table>

            <span class="extdebug d-none">{serialize($votable//*:COOSYS[1])}</span> {$query-code}
            {$src}
        </div>
    else
        <div>
            {
                if ( $votable//*:INFO[@name="QUERY_STATUS" and @value="ERROR"] ) then let $anchor := "error-"||util:uuid() return
                    (<a id="{$anchor}" href="#{$anchor}" class="text-danger" onclick='$(".extdebug").toggleClass("d-none");'>Sorry, an error occured executing the query. {$votable//*:INFO[@name='QUERY_STATUS' and @value='ERROR']}</a>
                    ,<code class="extdebug d-none"><br/>{serialize($votable)}</code>)
                else
                    <span>Sorry, no fringe traking star found for <b>{$s/name/text()} in {$cat?cat_name}</b>.</span>
            }
            {$query-code}
            {$src}
        </div>
};

declare %templates:wrap function app:bulk-form($node as node(), $model as map(*), $identifiers as xs:string*, $format as xs:string*, $catalogs as xs:string*) {
    let $defaults := app:defaults()
    let $max := $defaults("max")
    let $params :=  for $p in request:get-parameter-names() where not ( $p=("identifiers", "catalogs") ) return <input type="hidden" name="{$p}" value="{request:get-parameter($p,' ')}"/>
    let $default-catalogs := for $cat in $app:conf?catalogs?* order by $cat?main_cat descending return $cat?cat_name
    let $user-catalogs := request:get-parameter("catalogs", ())
    let $cats-params := for $catalog in $default-catalogs
        return
            <div class="form-check form-check-inline">
                { element input { attribute class {"form-check-input"}, attribute type {"checkbox"}, attribute name {"catalogs"}, attribute value {$catalog}, if (empty($user-catalogs) or $catalog=$user-catalogs) then attribute checked {"true"}  else ()} }
                <label class="form-check-label">{$catalog}</label>
            </div>
    let $user-catalogs := if( exists($user-catalogs) ) then $user-catalogs else $default-catalogs
    return
    (
    <div>
        <h1>Bulk form!</h1>
        <p>This new form provide an efficient way to query a large number of targets.</p>
        <form method="post">
            <div class="p-3 input-group mb-3 ">
                <input type="text" class="form-control" placeholder="Science identifiers or coordinates (comma separated), e.g : 0 0, 4.321 6.543, HD123, HD234 " aria-label="Science identifiers (comma separated)" aria-describedby="b2"
                id="identifiers" name="identifiers" value="{$identifiers}" required=""/>
                <button class="btn btn-outline-secondary" type="submit" id="b2"><i class="bi bi-search"/></button>
            </div>
            {$params},{$cats-params}
        </form>
    </div>
    ,
    if (exists($identifiers)) then (
        app:searchftt-bulk-list($identifiers, $max, $user-catalogs),
        <script type="text/javascript">
        $(document).ready(function() {{
        $('.datatable').DataTable( {{
            "paging": false,"searching":false,"info": false,"order": []
        }});

        }});
        </script>

        ) else ()
    )
};

declare function app:searchftt-bulk-list($identifiers as xs:string*, $max as map(*), $catalogs-to-query as xs:string* ) {

    let $fov_deg := 3 * $max?dist_as div 3600

    let $ids := distinct-values($identifiers ! tokenize(., ",") ! tokenize(., ";")!normalize-space(.))[string-length()>0]

    let $map := for $id in $ids return map{$id: app:resolve-by-name($id)}
    let $cols := $map?*[1]/* ! name(.)
    let $th := <tr> {$cols ! <th>{.}</th>}</tr>
    let $trs := for $star in $map?*
        return <tr> {for $col in $cols return <td>{data($star/*[name(.)=$col])}</td> } </tr>

    let $table := <table class="table table-light datatable">
        <thead>{$th}</thead>
        {$trs}
        </table>
    let $votable := app:table2votable($table, "targets")
    let $targets :=<div><h3>Your { count($table//tr[td]) } targets </h3>{$table}</div>

    let $res-tables :=  for $cat-name in $catalogs-to-query
        let $cat := $app:conf?catalogs?*[?cat_name=$cat-name]
        where exists($cat)
        return
            app:bulk-search($votable, $max, $cat )

    return
        (<script type="text/javascript" src="https://aladin.u-strasbg.fr/AladinLite/api/v2/latest/aladin.min.js" charset="utf-8"></script>
        , $res-tables
        , $targets
        ,<code class="extdebug d-none"><br/>{serialize($votable)}</code>
        )
};


declare function app:bulk-search($input-votable, $max, $cat) {
	let $log := util:log("info", "searching bulk ftt in "||$cat?cat_name||" ...")
    let $query := app:build-query((), $input-votable, $max, $cat)
    let $query-code := <div class="extquery d-none"><pre><br/>{data($query)}</pre></div>
    let $max-rec := $max?rec * count($input-votable//*:TR) * 10
    let $votable := <error>SKIPPED</error>
    let $votable := try{if(exists(request:get-parameter("dry", ()))) then <error>dry run : remote query SKIPPED ! </error> else jmmc-tap:tap-adql-query($cat?tap_endpoint,$query, $input-votable, $max-rec, $cat?tap_format)}catch * {<a><error>{$err:description}</error>{$err:value}</a>}

    let $log := util:log("info", "done")
    let $table := if($votable/error or $votable//*:INFO[@name="QUERY_STATUS" and @value="ERROR"])
         then
            <div class="alert alert-danger" role="alert">
                Error trying to get votable.<br/>
                <pre>{data($votable)}</pre>
            </div>
        else
            <table class="table table-light table-bordered datatable">
                <thead><tr>{for $field in $votable//*:FIELD return <th title="{$field/*:DESCRIPTION}">{data($field/@name)}</th>}</tr></thead>
                {for $trs in $votable//*:TR return <tr>{for $td in $trs/*:TD return <td>{data($td)}</td>}</tr>}
            </table>

    return
        <div class="{if($cat?main_cat) then () else "extcats d-none"}">
        <h3>{$cat?cat_name} ({count($table//tr[td])})</h3>
        {$table}
        {<code class="extdebug d-none"><br/>{serialize($votable)}</code>}
        {$query-code}
        </div>
};

declare function app:build-query($identifier, $votable, $max, $cat as map(*)){
    let $votname := if($votable) then $votable//*:TABLE/@name else ()
    let $s := if($votname)  then $votname else app:resolve-by-name($identifier)
    let $ra := if($votname) then $votname||".my_ra" else $s/ra
    let $dec := if($votname) then $votname||".my_dec" else $s/dec
    let $pmra := if($votname) then $votname||".my_pmra" else try{ xs:double($s/pmra) } catch * {0}
    let $pmdec := if($votname) then $votname||".my_pmdec" else try{ xs:double($s/pmdec) } catch * {0}
    let $upload-from := if($votname) then "TAP_UPLOAD."||$votname|| " as " ||$votname||", " else ()
    let $science-name-col := if($votname) then $votname||".my_name as science, " else ()
    let $order-by := if($votname) then "science," else ()

    (: We could have built query with COALESCE to replace missing pmra by 0, but:
        GAVO does not support it inside a formulae and VizieR forbid it  :(

        TODO simplify distance computation if we do not have any pm info ?
    :)
    let $distance_J2000 := <dist_as>DISTANCE(
        POINT( 'ICRS', {$cat?ra} - ( ({$cat?epoch}-2000.0) * {$cat?pmra} ) / 3600000.0, {$cat?dec} - ( ( {$cat?epoch}-2000.0) * {$cat?pmdec} ) / 3600000.0  )
        ,POINT( 'ICRS', {$ra}, {$dec} )
        )*3600.0 as j2000_dist_as</dist_as>

    let $distance_catalog := <dist_as>DISTANCE(
        POINT('ICRS', {$cat?ra}, {$cat?dec})
        ,POINT('ICRS', {$ra}-((2000.0-{$cat?epoch})*{$pmra})/3600000.0, {$dec}-((2000.0-{$cat?epoch})*{$pmdec})/3600000.0 )
        )*3600.0 as cat_dist_as</dist_as>

    let $vmag := $cat?mag_v
    let $rmag := $cat?mag_r
    let $computed_prefix := if($vmag and $rmag ) then () else "computed_"

    let $v_filter := if ($vmag) then $vmag else <text>( {$cat?mag_g } - ( -0.0176 - 0.00686* ({$cat?mag_bp } - {$cat?mag_rp } ) - 0.1732*( {$cat?mag_bp } - {$cat?mag_rp })*( {$cat?mag_bp } - {$cat?mag_rp }) ) )</text>
    let $r_filter := if ($rmag) then $rmag else <text>( {$cat?mag_g } - ( 0.003226 + 0.3833* ({$cat?mag_bp } - {$cat?mag_rp } ) - 0.1345*( {$cat?mag_bp } - {$cat?mag_rp })*( {$cat?mag_bp } - {$cat?mag_rp }) ) )</text>
    let $max-mag-filters := <text>( ({$cat?mag_k }&lt;{$max?magK_UT} AND {$v_filter}&lt;{$max?magV}) OR ({$cat?mag_k }&lt;{$max?magK_AT} AND {$r_filter}&lt;{$max?magR}) )</text>

    (: escape catalogs with / inside  (VizieR case):)
    let $from := if(contains($cat?from, "/")) then '"'||$cat?from||'"' else $cat?from

    let $numerical_epoch := try{let $num := xs:double($cat?epoch) return true() }catch*{false()}
    let $ra_in_cat := if($numerical_epoch) then <ra>{$ra}-((2000.0-{$cat?epoch})*{$pmra})/3600000.0</ra> else $ra
    let $dec_in_cat := if($numerical_epoch) then <dec>{$dec}-((2000.0-{$cat?epoch})*{$pmdec})/3600000.0</dec> else $dec

    (:
    no significant changes in the result / leved commented
    let $current-year :=  year-from-date(current-date())
    let $distance_today := <dist_as>DISTANCE(
        POINT( 'ICRS', {$cat?ra} - ( ({$cat?epoch}-{$current-year}) * {$cat?pmra} ) / 3600000.0, {$cat?dec} - ( ( {$cat?epoch}-{$current-year}) * {$cat?pmdec} ) / 3600000.0  ),
        POINT( 'ICRS', {$ra}-((2000.0-{$current-year})*{$pmra})/3600000.0, {$dec}-((2000.0-{$current-year})*{$pmdec})/3600000.0 )
        )*3600.0 as today_dist_as</dist_as>
    :)

    let $mags := string-join((
        <m>{$cat?mag_k} as mag_ks</m>
        ,<m>{$cat?mag_g} as mag_g</m>[$cat?mag_g]
        ,<m>{$v_filter} as {$computed_prefix}mag_v</m>
        ,<m>{$r_filter} as {$computed_prefix}mag_r</m>
        ,map:for-each( $cat?detail, function ($i, $j) { $i || ' AS ' ||$j})
        ), ", ")

    let $positions :=    for $tr in subsequence($votable//*:TR,1,2000)
        return
            <position>CONTAINS( POINT('ICRS', {$tr/*:TD[2]}, {$tr/*:TD[3]}), CIRCLE('ICRS', {$cat?ra}, {$cat?dec}, {$max?dist_as}/3600.0) ) = 1</position>

    let $positional-xmatch := if($votname)
    then
        <position>CONTAINS( POINT('ICRS', {$ra_in_cat}, {$dec_in_cat}), CIRCLE('ICRS', {$cat?ra}, {$cat?dec}, {$max?dist_as}/3600.0) ) = 1</position>
        (: <positions>{string-join(("", $positions), " OR ")}</positions> :)
    else
        <position>CONTAINS( POINT('ICRS', {$ra_in_cat}, {$dec_in_cat}), CIRCLE('ICRS', {$cat?ra}, {$cat?dec}, {$max?dist_as}/3600.0) ) = 1</position>

    let $comments := string-join((""), "&#10;")

    (: TODO
        refactor bulk queries:
            move positional_max next to the first join
    :)

    let $query := <text>{$comments}
    SELECT
        {$science-name-col}
        {$cat?source_id} as source_id,
        {$distance_J2000},
        {$distance_catalog},
        {$cat?ra} as ra, {$cat?dec} as dec,
        {$cat?pmra}, {$cat?pmdec},
        {$cat?epoch} as epoch,
        {$mags}
    FROM
        {$upload-from} {$from}
    WHERE
        {$positional-xmatch}
            AND
        {$max-mag-filters}
    ORDER BY
        {$order-by} j2000_dist_as
    </text>
    return
        $query
};


declare function app:table2votable($table, $name){
    <VOTABLE xmlns="http://www.ivoa.net/xml/VOTable/v1.3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.4" xsi:schemaLocation="http://www.ivoa.net/xml/VOTable/v1.3 http://www.ivoa.net/xml/VOTable/v1.3">
        <RESOURCE type="input">
            <TABLE name="{$name}">
                {
                    let $tds := ($table//*:tr[*:td])[1]/*:td
                    for $col at $pos in $table//*:th
                        let $type := try{ let $a := xs:double($tds[$pos]) return "double"} catch * {"char"}
                        let $arraysize := if($type="char") then "*" else "1"
                        return <FIELD datatype="{$type}" arraysize="{$arraysize}" name="my_{$col}"/>
                }
                <DATA>
                    <TABLEDATA>
                        { for $tr in $table//*:tr[*:td] return <TR>{for $td in $tr/*:td return <TD>{data($td)}</TD>}</TR> }
                    </TABLEDATA>
                </DATA>
            </TABLE>
        </RESOURCE>
    </VOTABLE>
};

