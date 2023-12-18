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
import module namespace jmmc-ws="http://exist.jmmc.fr/jmmc-resources/ws" at "/db/apps/jmmc-resources/content/jmmc-ws.xql";

(:import module namespace jmmc-astro="http://exist.jmmc.fr/jmmc-resources/astro" at "/db/apps/jmmc-resources/content/jmmc-astro.xql";:) (: WARNING this module require to enable eXistDB's Java Binding :)

(: DEV HINTS:
    - prefer lower_case colnames since some backend rewrite to lower case input colnames
    - we could refactor with a map that would store column names so we replace and avoid use of error prone strings searching for come columns
    - we could extend the default map (and rename it to config ? ) so we can store more than max values and associate for each of them more metadata : desc, displayorder...)

   FUTURE IDEAS/TODOS :
    - present ft/ao tuples in the science table with a wait to keep only the best one so we can transmit them to Aspro2
    - add a constraint on tmass_dist so we avoid wrong GAIA Xmatches
    - show table overflow reaching max_result_table_rows !
    - add units in table
    - use cookies to store user defined values
    - move magnitude field names to standart notation https://vizier.cds.unistra.fr/vizier/catstd/catstd.htx
    - do chunk of long votables before quering TAP
    - accept file for long list of identifiers (and support coord+pm when simbad does not resolv it)
:)



(: Main config to unify catalog accross their colnames or simbad :)
declare variable $app:json-conf :='{
    "default":{
        "max_magV" : 15,
        "max_magK_UT" : 11,
        "max_magK_AT" : 10,
        "max_magR" : 12.5,
        "max_dist_as" : 30,
        "max_declinaison" : 40,
        "max_rec" : 25,
        "max_result_table_rows" : 1000
    },
    "extended-cols" : [ "pmra", "pmdec", "pmde", "epoch", "cat_dist_as", "today_dist_as"],
    "samestar-dist_deg" : 2.78E-4,
    "samestar-dist_as" : 1,
    "catalogs":{
        "simcat": {
            "cat_name":"Simbad",
            "main_cat":true,
            "bulk"    : true,
            "description": "<a href=&apos;http://simbad.u-strasbg.fr/&apos;>CDS / Simbad</a>",
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
            "cat_name"     : "Gaia DR3",
            "main_cat"     : true,
            "bulk"         : true,
            "description"  : "Gaia DR3 catalogues and cross-matched catalogues though <a href=&apos;https://www.cosmos.esa.int/web/gaia-users/archive&apos;>ESA archive center</a>.",
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
            "from"  :
                [
                    "gaiadr3.gaia_source_lite as gaia",
                    "gaiaedr3.tmass_psc_xsc_best_neighbour AS tmass_nb USING (source_id) JOIN gaiaedr3.tmass_psc_xsc_join AS xjoin ON tmass_nb.original_ext_source_id = xjoin.original_psc_source_id JOIN gaiadr1.tmass_original_valid AS tmass ON xjoin.original_psc_source_id = tmass.designation"
                ]
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
    let $toggle-classes := map{ "extcats" : "extended catalogs", "extcols" : "extended columns", "extquery" : "queries", "exttable" : "hide tables", "extorphan" : "hide orphans", "extdebug" : "debug" }
    return
        <li class="nav-link">{
            map:for-each( $toggle-classes, function ($k, $label) {
                <div class="form-check form-check-inline form-switch nav-orange">
                    <input class="form-check-input" type="checkbox" onClick='$(".{$k}").toggleClass("d-none");'/><label class="form-check-label">{$label}</label>
                </div>
            })
        }</li>[exists($identifiers)]
};

declare function app:datatable-script(){
    <script type="text/javascript">
        var formatTable = true; // TODO enhance table metadata so we rely on it and limit formating on some columns
        $(document).ready(function() {{
        $('.datatable').DataTable( {{
            /* */
            "aoColumnDefs": [
            {{
                "targets": '_all',
                "mRender": function ( data, type, row ) {{
                    if(type == "display" &amp;&amp; formatTable ){{
                        fdata=parseFloat(Number(data))
                        if(isNaN(fdata) || data % 1 == 0){{
                            return data;
                        }}
                        return fdata.toFixed(3);
                    }}
                    return data;
                }}
            }},
            ],
            "paging": false,"scrollX": true,"scrollY": 600, "scrollResize": true,"scrollCollapse": true,
            "searching":true,"info": false,"order": [],
            "dom": 'Bfrtip',
            "buttons": ['pageLength', 'colvis','csv','copy'  ],
            "lengthMenu": [
                [10, 25, 50, 100, -1],
                [10, 25, 50, 100, "All"]],
            "iDisplayLength": 25
        }});

        }});
    </script>
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
            Each query is performed within {$max?dist_as_info}&apos;&apos; of the Science Target below the max declinaison of {$max?declinaison_info}°.
            A magnitude filter is applied on every Fringe Tracker Targets according to the best limits offered in P110
            for <b>UT (MACAO) OR AT (NAOMI)</b>  respectively <b>( K &lt; {$max?magK_UT_info} AND V &lt; {$max?magV_info} ) OR ( K &lt; {$max?magK_AT_info} AND R&lt;{$max?magR_info} )</b>.
            When missing, the V and R magnitudes are computed from the Gaia G, Grb and Grp magnitudes.
            The user must <b>refine its target selection</b> to take into account <a href="https://www.eso.org/sci/facilities/paranal/instruments/gravity/inst.html">VLTI Adaptive Optics specifications</a> before we offer a configuration selector in a future release.
        </p>
        <p>
            <ul>
                <li>Enter semicolon separated names ( SearchFTT will try to resolve it using <a href="http://simbad.u-strasbg.fr">Simbad</a> ) or coordinates (RA +/-DEC in degrees J2000), in the TextBox below.</li>
                <li>Move your pointer to the column titles of the result tables to get the column descriptions.</li>
                <li>To send a target to <a href="https://www.jmmc.fr/getstar">Aspro2</a> (already open), click on the icon in the <a href="https://www.jmmc.fr/getstar">GetStar</a> column, then press "Send Votable".</li>
                <li>Please <a href="http://www.jmmc.fr/feedback">fill a report</a> for any question or remark.</li>
            </ul>
        </p>
        <form>
            <div class="p-3 input-group mb-3 ">
                <input type="text" class="form-control" placeholder="Science identifiers (semicolon separator) e.g : 0 0; 4.321 6.543; HD123; HD234" aria-label="Science identifiers (semicolon separator)" aria-describedby="b2"
                id="identifiers" name="identifiers" value="{$identifiers}" required=""/>
                <button class="btn btn-outline-secondary" type="submit" id="b2"><i class="bi bi-search"/></button>
            </div>
            {$params}
        </form>
    </div>
    ,
    if (exists($identifiers)) then ( app:searchftt-list($identifiers, $max), app:datatable-script() ) else ()
    )
};

declare %private function app:fake-target($coords) {
    let $coord := $coords => replace( "\+", " +") => replace ("\-", " -")
    let $t := for $e in tokenize($coord, " ")[string-length(.)>0]  return $e
        return <target position-only="y"><user_identifier>{normalize-space($coords)}</user_identifier><name>{normalize-space($coords)}</name><ra>{$t[1]}</ra><dec>{$t[2]}</dec><pmra>0.0</pmra><pmdec>0.0</pmdec></target>
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
        app:fake-target($name-or-coords)
};

(:~
 : Resolve names using simbad or forge the same response if coordinates are detected.
 :
 : @param $name-or-coords name or coordinates
 : @return a map of identifier with associated target element (see jmmc-simbad:resolve-by-name or app:fake-target format)
 :)
declare function app:resolve-by-names($name-or-coords) {
    let  $names := $name-or-coords[matches(., "[a-z]", "i")]
    let $coords := $name-or-coords[not(matches(., "[a-z]", "i"))] (: should we check for :)

    let $map := map:merge((
        for $c in $coords return map:entry($c, app:fake-target($c))
        ,
        if(exists(request:get-parameter("dry", ()))) then
            ()
        else
            jmmc-simbad:resolve-by-names($names)
    ))
    return $map
};

declare function app:searchftt-list($identifiers as xs:string, $max as map(*) ) {

    let $fov_deg := 3 * $max?dist_as div 3600

    let $ids := distinct-values($identifiers ! tokenize(., ";") ! normalize-space(.))[string-length()>0]
    let $id2target := app:resolve-by-names($ids)
    let $count := count($ids)
    let $lis :=
        for $id at $pos in $ids
        let $s := map:get($id2target, $id)
        let $log := util:log("info", <txt>loop {$pos} / {$count} : {$id} {$s} </txt>)
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
        <table class="table  table-bordered table-light table-hover datatable">
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
            <table class="table table-bordered table-light table-hover datatable" data-found-targets="{$tr-count}" data-src-targets="{$cat?cat_name}" data-science="{$s/name}">
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
                    let $trs := $votable//*:TABLEDATA/*
                    (: compute simbad id adding a prefix to build a valid identifier :)
                    let $targets-ids := $trs/*[$source_id_idx]!concat($cat?simbad_prefix_id, .)
                    let $id2target := app:resolve-by-names($targets-ids)
                    for $tr in $trs return
                        <tr>{
                            let $simbad_id := $cat?simbad_prefix_id||$tr/*[$source_id_idx]
                            let $simbad := map:get($id2target, $simbad_id)

                            let $target_link := if (exists($simbad/ra/text())) then <a href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($simbad_id)}">{replace($simbad/name," ","&#160;")}</a> else
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

declare function app:get-identifiers-from-file($indentifiersFile as xs:string*){
    if (exists($indentifiersFile)) then
        for $i in distinct-values($indentifiersFile)
            (: let $log := util:log("info", "identifiersFile[" || $i || "]:"|| request:get-uploaded-file-data("indentifiersFile") ) :)
            return "a"
    else ()
};

declare %templates:wrap function app:bulk-form($node as node(), $model as map(*), $identifiers as xs:string*, $format as xs:string*, $catalogs as xs:string*, $indentifiersFile as xs:string*) {
    let $defaults := app:defaults()
    let $max := $defaults("max")
    (: was here before max-mags to convey mags parameters
        let $params :=  for $p in request:get-parameter-names() where not ( $p=("identifiers", "catalogs") ) return <input type="hidden" name="{$p}" value="{request:get-parameter($p,' ')}"/> :)

    let $max-inputs :=  for $k in ("magV","magR","magK_UT","magK_AT", "declinaison") let $v := map:get($max,$k) return
        <div class="p-2"><div class="input-group">
                <span class="input-group-text">{$k}</span>
                <input name="max_{$k}" value="{$v}" class="form-control"/>
        </div></div>
    let $default-catalogs := for $cat in $app:conf?catalogs?* where exists($cat?bulk) order by $cat?main_cat descending return $cat?cat_name
    let $user-catalogs := request:get-parameter("catalogs", ())
    let $cats-params := for $catalog in $default-catalogs
        return
            <div class="p-2"><div class="input-group">
            <div class="input-group-text">
                { element input { attribute class {"form-check-input"}, attribute type {"checkbox"}, attribute name {"catalogs"}, attribute value {$catalog}, if (empty($user-catalogs) or $catalog=$user-catalogs) then attribute checked {"true"}  else ()} }
            </div>    <span class="form-control">{$catalog}</span>
            </div></div>
    let $user-catalogs := if( exists($user-catalogs) ) then $user-catalogs else $default-catalogs
    let $identifiers-from-file := app:get-identifiers-from-file($indentifiersFile)
    return
    (
    <div>
        <h1>Bulk form for fast and efficient queries !</h1>
        <form method="post">
            <div class="d-flex p-2">
            <div class="input-group">
                <input type="text" class="form-control" placeholder="Enter your science identifiers or coordinates. Use semicolon as separator, e.g : 0 0; 4.321 6.543; HD123; HD234 " aria-label="Science identifiers (semicolon separator)" id="identifiers" name="identifiers" value="{$identifiers}"/>
            </div>
            <!--
            Disabled waiting for a solution that accept  enctype="multipart/form-data" forms ( without templating ?)
            <div class="input-group mb-2">
                <span class="input-group-text" id="indentifiersFileDesc">... or provide an input file</span>
                <input type="file" class="form-control" id="indentifiersFile"  name="indentifiersFile" aria-describedby="indentifiersFileDesc" />
            </div>
            -->
            </div>
            <div class="d-flex p-2"><div class="p-2 justify-content-end"><label class="form-check-label ">Catalogs to query:</label></div>
                {$cats-params}
            </div>

            <div class="d-flex p-2"><div class="p-2 justify-content-end">Max&#160;constraints:</div>
                {$max-inputs}
            </div>
            <div class="d-flex p-2">
                <div class="col-sm-2"><input type="submit" class="btn btn-primary"/></div>
                <div class="col-sm-2"><a href="bulk.html" class="btn btn-outline-secondary" role="button"> Reset <i class="bi bi-arrow-clockwise"></i></a></div>
            </div>
        </form>
    </div>
    ,
    if (exists($identifiers[string-length()>0])) then
        (
            app:searchftt-bulk-list($identifiers, $max, $user-catalogs),
            app:datatable-script(),
            <p><i class="bi bi-info-circle-fill"></i>&#160;<kbd>Shift</kbd> click in the column order buttons to combine a multi column sorting.</p>
        )
    else ()
    )
};

declare function app:searchftt-bulk-list($identifiers as xs:string*, $max as map(*), $catalogs-to-query as xs:string* ) {
    let $catalogs-to-query := for $cat-name in $catalogs-to-query
        where exists($app:conf?catalogs?*[?cat_name=$cat-name])
        return $cat-name

    let $ids := distinct-values($identifiers ! tokenize(., ";")!normalize-space(.))[string-length()>0]
    let $identifiers-map := app:resolve-by-names($ids)

    (: Let's build a table on top of main info so we can use it for tap votable upload later :)
    let $cols := $identifiers-map?*[1]/* ! name(.)
    let $th := <tr> {$cols ! <th>{.}</th>}</tr>
    let $trs := for $star in $identifiers-map?* order by $star
        return <tr> {for $col in $cols return <td>{data($star/*[name(.)=$col])}</td> } </tr>
    let $table := <table class="table table-bordered table-light table-hover datatable">
        <thead>{$th}</thead>
        {$trs}
        </table>
    let $votable := jmmc-tap:table2votable($table, "targets")
    (: TODO iterate and merge over chunk of
    let $votables := jmmc-tap:table2votable($table, "targets", 500) :)


    let $bulk-search-maps :=  map:merge((
        for $cat-name in $catalogs-to-query
        let $cat := $app:conf?catalogs?*[?cat_name=$cat-name]
        let $res  := app:bulk-search($votable, $max, $cat )
        return map:entry($cat-name,$res)))

    (: Rebuild the table (and votable) with a summary of what we have in the catalogs :)
	let $log := util:log("info", "prepare main merged table ... ")

    let $sci-cols :=  $identifiers-map?*[1]/* ! name(.)
    let $ftaos-cols := ("FT identifier", "AO identifier", "Score", "Rank", "Catalog", "Input (sci_Kmag, ft_Kmag, sci_ft_dist, ao_Rmag, sci_ao_dist, ft_ao_dist)")
    let $cols := ($sci-cols,$ftaos-cols)
    let $th := <tr> {$cols ! <th>{.}</th>}</tr>
    let $trs :=  for $identifier in map:keys($identifiers-map) order by $identifier
        let $science := map:get($identifiers-map, $identifier)
        return
            for $cat in $catalogs-to-query
                let $ftaos := $bulk-search-maps($cat)?ranking?ftaos
                let $scores := $bulk-search-maps($cat)?ranking?scores
                let $science-idx := $bulk-search-maps($cat)?ranking?sciences-idx?($identifier)
                let $inputs := $bulk-search-maps($cat)?ranking?inputs
            (:
                        { count( $science-idx ) } configurations :
                        <table class="table table-bordered table-light table-hover">
                            <tr><th>FT</th><th>AO</th><th>SCORE</th></tr>9.03 16.381952728829486 4.91 16.883200012527162 31.668749771423702
                            { for $idx in $science-idx return <tr><td>{$ftaos?*[$idx]?*[1]}</td><td>{$ftaos?*[$idx]?*[2]}</td><td>{$scores?*[$idx]}</td></tr> }
                        </table>
                :)
                let $ordered-science-idx := for $idx in $science-idx order by $scores?*[$idx] descending return $idx
            return
                for $idx at $pos in $ordered-science-idx
                    where $pos <= 20
                    let $ftao := $ftaos?*[$idx]?*
                    return
                        <tr>
                            {for $col in $sci-cols return <td>{data($science/*[name(.)=$col])}</td> }
                            <td>{$ftao[1]}</td>
                            <td>{$ftao[2]}</td>
                            <td>{$scores?*[$idx]}</td>
                            <td>{$pos}</td>
                            <td>{$cat}</td>
                            <td>{string-join($inputs?*[$idx], ', ')}</td>
                        </tr>

    let $table := <table class="table table-bordered table-light table-hover datatable">
        <thead>{$th}</thead>
        {$trs}
        </table>
    let $votable := jmmc-tap:table2votable($table, "targets")

    let $log := util:log("info", "DONE : main table merged")

    let $targets :=<div><h3>{ count($table//tr[td]) }/{ count($bulk-search-maps?*?ranking?scores?*) } best proposed configurations for your {count(map:keys($identifiers-map))} targets (top 20)
        <a class="btn btn-outline-secondary btn-sm" href="data:application/x-votable+xml;base64,{util:base64-encode(serialize($votable))}" type="application/x-votable+xml" download="input.vot">votable</a>&#160;
        </h3>{$table}</div>

    return
        (<script type="text/javascript" src="https://aladin.u-strasbg.fr/AladinLite/api/v2/latest/aladin.min.js" charset="utf-8"></script>
        , $targets
        ,<h2>Results per catalogs.</h2>
        ,<p>By now, the ut_flag and at_flag columns are not computed in the votable but the table below ( 1=FT, 2=AO, 3=FT or AO). <br/> Magnitudes columns colors are for
            <small class="d-inline-flex mb-3 px-2 py-1 fw-semibold bg-success bg-opacity-10 border border-success border-opacity-10 rounded-2">UT and AT compliancy</small>,
            <small class="d-inline-flex mb-3 px-2 py-1 fw-semibold bg-warning bg-opacity-10 border border-warning border-opacity-10 rounded-2">UT compliancy</small> or
            <small class="d-inline-flex mb-3 px-2 py-1 fw-semibold bg-danger bg-opacity-10 border border-danger border-opacity-10 rounded-2">not compatible / unknown</small>
        </p>
        , $bulk-search-maps?*?html
        )
};


declare function app:bulk-search($input-votable, $max, $cat) {
    let $start-time := util:system-time()
	let $log := util:log("info", "searching bulk ftt in "||$cat?cat_name||" ...")
    let $query :=  app:build-query((), $input-votable, $max, $cat)
    let $query-code := <div class="extquery d-none">{for $q in $query return <pre><br/>{data($q)}<br/></pre>}</div>
    let $max-rec := $max?rec * count($input-votable//*:TR) * 100 (: TODO show this magic value in doc :)
    let $votable := <error>SKIPPED</error>
    let $votable :=
        try{
            if(exists(request:get-parameter("dry", ())))
            then
                <error>dry run : remote query SKIPPED !</error>
            else
                if (count($query)=1) then
                    jmmc-tap:tap-adql-query($cat?tap_endpoint,$query, $input-votable, $max-rec, $cat?tap_format)
                else
                    let $input-votable2 := jmmc-tap:tap-adql-query($cat?tap_endpoint,$query[1], $input-votable, $max-rec*10000, $cat?tap_format)
                    return
                        if( $input-votable2/error or $input-votable2//*:INFO[@name="QUERY_STATUS" and @value="ERROR"] )
                        then
                            $input-votable2
                        else
                            jmmc-tap:tap-adql-query($cat?tap_endpoint,$query[2], $input-votable2, $max-rec, $cat?tap_format, "step2")
        } catch * {
            <a><error>{$err:description}</error>{$err:value}</a>
        }

    let $table := if($votable/error or $votable//*:INFO[@name="QUERY_STATUS" and @value="ERROR"])
         then
            <div class="alert alert-danger" role="alert">
                Error trying to get votable.<br/>
                <pre>{data($votable)}</pre>
                {util:log("error", data($votable))}
            </div>
        else if(not ( contains(lower-case(name($votable/*)),"votable") ) ) (: TODO throw an exception for this case on jmmc-tap side :)
        then
            <div class="alert alert-danger" role="alert">
                Error trying to get votable (maybe html ? '{lower-case(name($votable/*))}') : <br/>
                {$votable}
                {util:log("error", data($votable))}
            </div>
        else

            let $field_names := for $e in $votable//*:FIELD/@name return lower-case($e)
            let $science_idx := index-of($field_names, "science")
            let $source_id_idx := index-of($field_names, "source_id")
            let $mag_k_idx := index-of($field_names, "mag_ks")
            let $mag_v_idx := (index-of($field_names, "mag_v"),index-of($field_names, "computed_mag_v"))
            let $mag_r_idx := (index-of($field_names, "mag_r"),index-of($field_names, "computed_mag_r"))
            let $at_flag_idx := index-of($field_names, "at_flag")
            let $ut_flag_idx := index-of($field_names, "ut_flag")

            let $trs := $votable//*:TR
            (: compute simbad id adding a prefix to build a valid identifier :)
            let $targets-ids := $trs/*[$source_id_idx]!concat($cat?simbad_prefix_id, .)
            let $id2target := app:resolve-by-names($targets-ids)

            return

            <table class="table table-light table-bordered table-hover datatable exttable">
                <thead><tr>{for $field in $votable//*:FIELD return <th title="{$field/*:DESCRIPTION}">{data($field/@name)}</th>}<th title="number of stars returned for the same science target">commons</th></tr></thead>
                {
                    for $src_tr in subsequence($trs,1,$max?result_table_rows) group by $science := $src_tr/*:TD[$science_idx]
                    let $group_size := count($src_tr)
                    return for $tr in $src_tr
                    let $simbad_id := $cat?simbad_prefix_id||$tr/*[$source_id_idx]
                    let $simbad := map:get($id2target, $simbad_id)
                    let $target_link := if (exists($simbad/ra/text())) then <a href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($simbad_id)}">{replace($simbad/name," ","&#160;")}</a> else
                                let $ra := $tr/*[index-of($field_names, "ra")]
                                let $dec := $tr/*[index-of($field_names, "dec")]
                                return <a href="http://simbad.u-strasbg.fr/simbad/sim-coo?Coord={$ra}+{$dec}&amp;CooEpoch=2000&amp;CooEqui=2000&amp;Radius={$app:conf?samestar-dist_as}&amp;Radius.unit=arcsec" title="Using coords because Simbad does't know : {$simbad_id}">{replace($simbad_id," ","&#160;")}</a>
                    (: Compute flags :)
                    let $magk := number($tr/*[$mag_k_idx])
                    (: AT :)
                    let $magr := number($tr/*[$mag_r_idx])
                    let $magr_flag := if ($magr<$max?magR) then 2 else 0
                    let $at_flag  :=  if ($magk<$max?magK_AT) then $magr_flag+1 else $magr_flag
                    (: UT :)
                    let $magv := number($tr/*[$mag_v_idx])
                    let $magv_flag := if ($magv<$max?magV) then 2 else 0
                    let $ut_flag  :=  if ($magk<$max?magK_UT) then $magv_flag+1 else $magv_flag

                    return <tr>
                            {for $td at $pos in $tr/*:TD
                            return <td>{
                                switch($pos)
                                    case $source_id_idx return $target_link
                                    case $mag_k_idx return
                                        (attribute {"class"} {if ($magk<$max?magK_AT) then "table-success" else if ($magk<$max?magK_UT) then "table-warning" else "table-danger"}, data($td))
                                    case $mag_v_idx return
                                        (attribute {"class"} {if ($magv<$max?magV) then "table-success" else "table-danger"}, data($td))
                                    case $mag_r_idx return
                                        (attribute {"class"} {if ($magr<$max?magR) then "table-success" else "table-danger"}, data($td))
                                    case $at_flag_idx return
                                        $at_flag
                                    case $ut_flag_idx return
                                        $ut_flag
                                    default return data($td)
                            }</td>}
                            <td>{$group_size}</td>
                        </tr>
                }
            </table>
    let $log := util:log("info", "done ("||seconds-from-duration(util:system-time()-$start-time)||"s)")
    let $nb_rows := count($votable//*:TR)
    return map { "html":
        <div class="{if($cat?main_cat) then () else "extcats d-none"}">
        <h3>
            {$cat?cat_name} ({$nb_rows})&#160;
            <a class="btn btn-outline-secondary btn-sm" href="data:application/x-votable+xml;base64,{util:base64-encode(serialize($votable))}" type="application/x-votable+xml" download="searchftt_{$cat?cat_name}.vot">votable</a>
         </h3>
        { $table }
        {$query-code}
        {<code class="extdebug d-none"><br/>Catalog query duration : {seconds-from-duration(util:system-time()-$start-time)}s</code>}
        </div>,
        "ranking": app:get-ranking($votable,$cat,$max)
    }
};

(: Returns a ranking map or empty value if given votable has no data :)
declare function app:get-ranking($votable, $cat, $max) {
    if(empty($votable//*:TR)) then () else
        (: prepare input with every permutations :)
        let $internal-match-query := app:build_internal_query($votable, "internal", $cat, $max)
        let $res := jmmc-tap:tap-adql-query("http://tap.jmmc.fr/vollt/tap/sync", $internal-match-query, $votable, -1, "votable/td", "internal")
        let $log := util:log("info", "internal match field count = "|| count($res//*:FIELD) || " rows count = "|| count($res//*:TR) )
        let $colidx := map:merge( for $e at $pos in $res//*:FIELD/@name return map:entry(replace(lower-case($e),"computed_",""), $pos) )
        let $log := util:log("info", serialize( map:keys($colidx) => sort() ))
        (: let $log := util:log("info", serialize($res)) :)

        (: WebService ask for : [[sci_Kmag, ft_Kmag, sci_ft_dist, ao_Rmag, sci_ao_dist, ft_ao_dist]] :)
        (: at_flag_ao at_flag_ft cat_dist_as_ao cat_dist_as_ft dec_ao dec_ft epoch_ao epoch_ft j2000_dist_as_ao j2000_dist_as_ft j2024_dist_as_ao j2024_dist_as_ft
           mag_g_ao mag_g_ft mag_ks_ao mag_ks_ft mag_r_ao mag_r_ft
           mag_v_ao mag_v_ft otype_txt_ao otype_txt_ft pmdec_ao pmdec_ft pmra_ao pmra_ft ra_ao ra_ft science sep_ft_ao source_id_ao source_id_ft ut_flag_ao ut_flag_ft
        :)
        let $inputs := array{
                 for $tr at $pos in $res//*:TR
                    return array{
                        (
                        0
                        , number($tr/*:TD[$colidx?mag_ks_ft])
                        , number($tr/*:TD[$colidx?cat_dist_as_ft])
                        , number($tr/*:TD[$colidx?mag_r_ao])
                        , number($tr/*:TD[$colidx?cat_dist_as_ao])
                        , number($tr/*:TD[$colidx?sep_ft_ao])
                        )
                    }
            }

        let $scores := jmmc-ws:pyws-ut_ngs_score($inputs)

        let $log := util:log("info", "scores length : "|| count($scores?*))

        let $ftaos := array{ for $tr at $pos in $res//*:TR
                    return array{ data($tr/*:TD[$colidx?source_id_ft]), data($tr/*:TD[$colidx?source_id_ao]) }
                    }


        let $map-by-sci  := map:merge((
            for $tr at $pos in $res//*:TR group by $science := data($tr/*:TD[1])
                return map:entry($science,$pos)
        ))
        return
            map{ "sciences-idx" : $map-by-sci , "ftaos": $ftaos ,"scores": $scores, "inputs":$inputs}
};

declare function app:build_internal_query($votable, $table-name, $cat, $max){
    (: iterate on every columns except science and add a new distance :)
    let $colnames := for $f in $votable//*:FIELD/@name return lower-case($f)
    let $log := util:log("info", "colnames : " || string-join($colnames, " , "))

    let $vmag := $cat?mag_v
    let $rmag := $cat?mag_r
    let $computed_prefix := if($vmag and $rmag ) then () else "computed_"
    let $ft-filters := <text>(ft.mag_ks &lt; {max((number($max?magK_UT), number($max?magK_AT)))})</text>
    let $ao-filters := <text>(ao.{$computed_prefix}mag_r&lt;{$max?magR})</text>

    let $ftao-dist := <text>DISTANCE( POINT( 'ICRS', ft.ra, ft.dec),POINT('ICRS', ao.ra, ao.dec))*3600.0</text>
    let $dist-filter := <text>({$ftao-dist} &lt; 60)</text>

    let $internal-match := string-join((
        "SELECT",
        string-join(
            ("ft.science as science",
            $ftao-dist || " as sep_ft_ao",
            for $c in $colnames[not(.="science")] return for $type in ("ft", "ao") return  string-join( ($type, ".", $c, " as ", $c, "_"[exists($c)], $type) )
            ),", "),
        " FROM TAP_UPLOAD."||$table-name||" as ft , TAP_UPLOAD."||$table-name||" as ao ",
        " WHERE " || $ft-filters || " AND " || $ao-filters || " AND " || $dist-filters
        ),"&#10;")

    let $log := util:log("info", "query : " || $internal-match)

    return
        $internal-match
};

declare function app:build-query($identifier, $votable, $max, $cat as map(*)){
    let $froms := array:flatten($cat?from)
    let $singlequery := count($froms)=1 or empty($votable)
    let $votname := if($votable) then $votable//*:TABLE/@name else ()
    let $s := if($votname)  then $votname else app:resolve-by-name($identifier)
    let $ra := if($votname) then $votname||".my_ra" else $s/ra
    let $dec := if($votname) then $votname||".my_dec" else $s/dec
    let $pmra := if($votname) then $votname||".my_pmra" else try{ xs:double($s/pmra) } catch * {0}
    let $pmdec := if($votname) then $votname||".my_pmdec" else try{ xs:double($s/pmdec) } catch * {0}
    let $upload-from := if($votname) then "TAP_UPLOAD."||$votname|| " as " ||$votname||", " else ()
    let $science-name-col := if($votname) then $votname||".my_user_identifier as science, " else ()
    let $order-by := if($votname) then "science," else ()

    (: We could have built query with COALESCE to replace missing pmra by 0, but:
        GAVO does not support it inside a formulae
        VizieR forbid it  :(
        but ESA DC does with ESDC_COALESCE (add it in the catalog map ?)

        OR simplify distance computation if we do not have any pm info or same epoch ?
    :)

    let $distance_J2000 := <dist_as>DISTANCE(
            POINT( 'ICRS', {$cat?ra} - ( ({$cat?epoch}-2000.0) * {$cat?pmra} ) / 3600000.0, {$cat?dec} - ( ( {$cat?epoch}-2000.0) * {$cat?pmdec} ) / 3600000.0  )
            ,POINT( 'ICRS', {$ra}, {$dec} )
        )*3600.0 as j2000_dist_as</dist_as>

    let $distance_catalog := <dist_as>DISTANCE(
            POINT('ICRS', {$cat?ra}, {$cat?dec})
            ,POINT('ICRS', {$ra}-((2000.0-{$cat?epoch})*{$pmra})/3600000.0, {$dec}-((2000.0-{$cat?epoch})*{$pmdec})/3600000.0 )
        )*3600.0 as cat_dist_as</dist_as>

    (:
    could be more reliable but does not seem to change a lot
    :)
    let $date-epoch := 2024
    let $distance_jdate := <dist_as>DISTANCE(
            POINT( 'ICRS', {$cat?ra} - ( ({$cat?epoch}-{$date-epoch}) * {$cat?pmra} ) / 3600000.0, {$cat?dec} - ( ( {$cat?epoch}-{$date-epoch}) * {$cat?pmdec} ) / 3600000.0  )
            ,POINT('ICRS', {$ra}-((2000.0-{$date-epoch})*{$pmra})/3600000.0, {$dec}-((2000.0-{$date-epoch})*{$pmdec})/3600000.0 )
        )*3600.0 as j2024_dist_as</dist_as>
    (: :)

    let $vmag := $cat?mag_v
    let $rmag := $cat?mag_r
    let $computed_prefix := if($vmag and $rmag ) then () else "computed_"

    let $v_filter := if ($vmag) then $vmag else <text>( {$cat?mag_g } - ( -0.0176 - 0.00686* ({$cat?mag_bp } - {$cat?mag_rp } ) - 0.1732*( {$cat?mag_bp } - {$cat?mag_rp })*( {$cat?mag_bp } - {$cat?mag_rp }) ) )</text>
    let $r_filter := if ($rmag) then $rmag else <text>( {$cat?mag_g } - ( 0.003226 + 0.3833* ({$cat?mag_bp } - {$cat?mag_rp } ) - 0.1345*( {$cat?mag_bp } - {$cat?mag_rp })*( {$cat?mag_bp } - {$cat?mag_rp }) ) )</text>
    let $max-mag-filters := if($votname)
        then <text>({$cat?mag_k }&lt;{max((number($max?magK_UT), number($max?magK_AT)))} OR {$v_filter}&lt;{$max?magV} OR {$r_filter}&lt;{$max?magR})</text>
        else <text>( ({$cat?mag_k }&lt;{$max?magK_UT} AND {$v_filter}&lt;{$max?magV}) OR ({$cat?mag_k }&lt;{$max?magK_AT} AND {$r_filter}&lt;{$max?magR}) )</text>

    (: escape catalogs with / inside  (VizieR case):)
    let $from := if($singlequery) then string-join($froms, "    JOIN    ") else $froms[1]
    let $from := if(contains($from, "/")) then '"'||$from||'"' else $from

    (: compute science position in catalog epoch so we can compute crossmatch even if we do not have PM (inputs always have 0 for unknown PMs) :)
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
        <m>{$v_filter} as {$computed_prefix}mag_v</m>
        ,<m>{$r_filter} as {$computed_prefix}mag_r</m>
        ,<m>{$cat?mag_k} as mag_ks</m>
        ,<m>{$cat?mag_g} as mag_g</m>[$cat?mag_g]
        ,map:for-each( $cat?detail, function ($i, $j) { $i || ' AS ' ||$j})
        ), ",&#10;        ")

    (: It seems not possible to add this in the select part ??
    let $flags := <text>{$cat?mag_k }&lt;{$max?magK_UT} , {$v_filter}&lt;{$max?magV} , {$cat?mag_k }&lt;{$max?magK_AT} , {$r_filter}&lt;{$max?magR} , </text>
    :)

    (: cross match must be done in the catalog epoch to retrieve candidates without PM :)
    (: /!\ VizieR will never end the processing if we do not put the input position in the POINT :)
    let $positional-xmatch := <position>CONTAINS( POINT('ICRS', {$cat?ra}, {$cat?dec}), CIRCLE('ICRS', {$ra_in_cat}, {$dec_in_cat}, {$max?dist_as}/3600.0) ) = 1</position>
    let $max_dec := <position>{$cat?dec} &lt; {$max?declinaison}</position>
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
        {$distance_jdate},
        0 as ut_flag,
        0 as at_flag,
        {$cat?ra} as ra, {$cat?dec} as dec,
        {$cat?pmra}, {$cat?pmdec},
        {$cat?epoch} as epoch{","[$singlequery]}
        {$mags[$singlequery]}
    FROM
        {$upload-from} {$from}
    WHERE
        {string-join(($positional-xmatch,($max-mag-filters, $max_dec)[$singlequery]) ,"&#10;            AND&#10;          ")}
    ORDER BY
        {$order-by} j2000_dist_as
    </text>

    let $subquery := if($singlequery) then () else <text>
    SELECT
        step2.*,
        {$mags[not($singlequery)]}
    FROM
        TAP_UPLOAD.step2 as step2
        JOIN {$froms[1]} USING (source_id)
        JOIN {$froms[2]}
    WHERE
        { string-join( ($max-mag-filters, $max_dec) ,"&#10;            AND&#10;          ") }
    </text>

    return
        if($singlequery) then $query
        else
        ($query, $subquery)
};