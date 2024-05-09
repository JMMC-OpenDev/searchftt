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
import module namespace astro="http://exist.jmmc.fr/searchftt/astro" at "astro.xql";

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
    - support coord+pm when simbad does resolv it!
    - add objtypes while resolving simbad
:)

(: suffix used in maps to provide a text or html documentation :)
declare variable $app:doc-suffix := "_doc";

(: Main config to unify catalog accross their colnames or simbad :)
declare variable $app:json-conf :='{
    "default":{
        "max_magV" : 15,
        "max_magK_UT" : 11,
        "max_magK_AT" : 10,
        "max_magR" : 12.5,

        "max_AO_mag": 12.5,
        "max_AO_mag_doc": "use Gmag if present in catalogs else Rmag or Vmag",
        "max_FT_mag": 12,

        "max_dist_as" : 30,
        "max_declinaison" : 40,
        "max_rec" : 25,
        "max_result_table_rows" : 1000,
        "max_rank" : 4,
        "max_rankbulk_doc" : "max number of best AOFT tuples sorted by score",

        "min_score" : 0.0,

        "preferred_bulk_catalog" : "Gaia DR3",
        "max_rows_from_vizier" : 500
    },
    "aspro-cols" : {"pmra":"PMRA", "pmdec":"PMDEC", "mag_v": "FLUX_V", "mag_r": "FLUX_R", "mag_g": "FLUX_G", "mag_ks": "FLUX_K"},
    "extended-cols" : [ "pmra", "pmdec", "pmde", "epoch", "cat_dist_as", "today_dist_as", "id", "str_source_id", "name" ],
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
            "cat_name"     : "Gaia DR3",
            "main_cat"     : true,
            "bulk"         : true,
            "description"  : "Gaia DR3 catalogues and cross-matched catalogues though <a href=&apos;https://www.cosmos.esa.int/web/gaia-users/archive&apos;>ESA archive center</a>.",
            "tap_endpoint" : "https://gea.esac.esa.int/tap-server/tap/sync",
            "tap_endpoint_coulb_be_a_backup" : "https://gaia.aip.de/tap/sync",
            "tap_format"   : "votable_plain",
            "tap_viewer"   : "",
            "tap_max_xmatch_votable_size" : 500,
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
            "detail"      : { "gaia.phot_rp_mean_mag": "Grp_mag", "tmass.h_m":"H_mag", "tmass_nb.angular_distance":"tmass_dist", "tmass.designation":"J_2MASS" },
            "from_very_slow"  :
                    "gaiadr3.gaia_source_lite as gaia JOIN gaiaedr3.tmass_psc_xsc_best_neighbour AS tmass_nb USING (source_id) JOIN gaiaedr3.tmass_psc_xsc_join AS xjoin ON tmass_nb.original_ext_source_id = xjoin.original_psc_source_id JOIN gaiadr1.tmass_original_valid AS tmass ON xjoin.original_psc_source_id = tmass.designation"
                ,
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
 : User params are converted to the default value types if possible or not applied else.
 : map will be populated by keyname_info entries so we can display overriden param.
 : @return a map with default or overriden values to use in the application.
:)
declare function app:config() as map(*){
    let $sections := ("min", "max", "preferred")
    return
    map:merge(
        for $section in $sections
            let $section-prefix := $section||"_"
            return
            map:entry($section, map:merge(
                for $key in map:keys($app:conf?default) where starts-with($key, $section-prefix)
                    let $map-key:=replace($key, $section-prefix, "")
                    let $map-info-key:=$map-key||"_info"
                    let $conf := $app:conf?default($key)
                    let $param := (request:get-parameter($key, ()))[1] (: accept one param from uri or post payload :)
                    let $map-info:= if( exists($param) and ( string($param) != string($conf) )) then <mark title="overridden by user : default conf is {$conf}">{$param}</mark> else $conf
                    let $map-value:= if( exists($param) ) then
                            try{
                                typeswitch($conf)
                                    case xs:double return xs:double($param)
                                    case xs:integer return xs:integer($param)
                                    default return $param
                            } catch * {$conf}
                        else $conf
                    (: let $log := util:log("info", "conf ["|| $section ||"."|| $map-key || "]=" || $map-value) :)
                    return ( map:entry($map-key, $map-value), map:entry($map-info-key, $map-info))
            ))
    )
};

declare %templates:wrap function app:dyn-nav-li($node as node(), $model as map(*), $identifiers as xs:string*) {
    let $toggle-classes := map{ (:"extcats" : "extended catalogs", :) "extquery" : "queries", "exttable" : "hide tables", (: "extorphan" : "hide orphans",:) "extdebug" : "debug" }

    return
        <li class="nav-link">{
            map:for-each( $toggle-classes, function ($k, $label) {
                <div class="form-check form-check-inline form-switch nav-orange">
                    <input class="form-check-input" type="checkbox" onClick='$(".{$k}").toggleClass("d-none");'/><label class="form-check-label">{$label}</label>
                </div>
            })
        }</li>[exists($identifiers)]
};

declare function app:datatable-script($score_index, $rank_index, $sci_ft_dist_index, $sci_ao_dist_index){
    (: TODO try to avoid hardcoded indexes for datacolumns :)
    <script type="text/javascript">

        let grays = culori.interpolate(['FF6666', '#FFFF66', '#B2FFB2']);

        let formatTable = true;
        $(document).ready(function() {{
        // bulk filter
        const min_score = document.querySelector('#min_score');
        const max_rank = document.querySelector('#max_rank');

        // Custom range filtering function
        DataTable.ext.search.push(function (settings, data, dataIndex) {{
            // Don t filter on anything other than "bulkTable"
            if ( settings.nTable.id !== 'bulkTable' ) {{
                return true;
            }}

            let min_s = parseFloat(min_score.value, 10) || 0;
            let s = parseFloat(data[{$score_index - 1}],10) || 0;

            let max_r = parseInt(max_rank.value) || 100;
            let r = parseInt(data[{$rank_index - 1}]) || 100;

            if ( ( r &lt;= max_r ) &amp;&amp; ( s &gt;= min_s ) ) {{
                return true;
            }}
            return false;
        }});

        var tables = $('.datatable').DataTable( {{
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
            {{
                "targets": {$score_index - 1},
                "createdCell": function (td, cellData, rowData, row, col) {{
                    if ( $(this)[0].id == 'bulkTable' ) {{
                        $(td).css('background-color', culori.formatHex(culori.convertOklabToRgb(culori.convertRgbToOklab( grays(cellData)))));
                    }}
                }}
            }},
            {{
                "targets": [ {$sci_ft_dist_index - 1 },{$sci_ao_dist_index - 1 } ],
                "createdCell": function (td, cellData, rowData, row, col) {{
                    if ( $(this)[0].id == 'bulkTable' ) {{
                        $l = 1 - ( cellData / {app:config()?max?dist_as} );
                        $(td).css('background-color', culori.formatHex(culori.convertOklabToRgb(culori.convertRgbToOklab(grays($l)))));
                    }}
                }}
            }}
            ],
            "paging": false,"scrollX": true,"scrollY": 600, "scrollResize": true,"scrollCollapse": true,
            "searching":true,"info": true,"order": [],
            "dom": 'Bfrti',
            "buttons": [ 'colvis','csv','copy'  ]
            }});

        // Changes to the inputs will trigger a redraw to update the table
        min_score.addEventListener('input', function () {{ tables.draw(); }});
        max_rank.addEventListener('input', function () {{ tables.draw(); }});

        // Hide extcols by default
        tables.columns( '.extcols' ).visible( false );

        // Set search input and buttons on the same line
        // bugged tables.buttons().container().appendTo( '.dataTables_filter' );

        }});
    </script>
};


declare %templates:wrap function app:form($node as node(), $model as map(*), $identifiers as xs:string*, $format as xs:string*) {
    let $max := app:config()("max")
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
    if (exists($identifiers)) then ( app:searchftt-list($identifiers, $max), app:datatable-script(0,0,0,0) ) else ()
    )
};


(:~
 Build a fake target record mimicing jmmc-simbad format.
 If votable-tr and colidx are provided, try to search for aspro2 fluxes FLUX_V,R,G,K

 let $colidx := map:merge( for $e at $pos in $votable//*:FIELD/@name return map:entry(replace(lower-case($e),"computed_",""), $pos) )

 @param $votable-tr optional votable tr
 @param $colidx optional map of td indexes to search into given votable-tr/*:TD

:)
declare %private function app:fake-target($name as xs:string?, $coords as xs:string?,$votable-tr as node()?, $colidx as map(*)?) {
    let $name := if($name) then $name else normalize-space($coords)
    let $coord := $coords => replace( "\+", " +") => replace ("\-", " -")
    let $t := for $e in tokenize($coord, " ")[string-length(.)>0]  return $e
    let $t := try{
            if(matches($coords, ":")) then (astro:from-hms($t[1]), astro:from-dms($t[2])) else $t
        }catch*{(0,0)}
    let $t := try{
            if(count($t)>2) then
                (astro:from-hms(string-join($t[position()<4], ":" )), astro:from-dms(string-join($t[position()>3], ":" )))
            else
                $t
        }catch*{(0,0)}
    let $additional-info := if(exists($votable-tr)) then
        let $tds := $votable-tr/*:TD
        let $aspro-elements := map:for-each($app:conf?aspro-cols,
            function ($tr-col, $aspro-col){
                let $td-value := $tds[$colidx($tr-col)]/text()
                return if(exists($td-value)) then element {$aspro-col} {data($td-value)} else ()
            }
        )(:
        let $log := util:log("info", "addtional info")
        let $log := util:log("info", $votable-tr)
        let $log := util:log("info", $colidx)
        let $log := util:log("info", $aspro-elements) :)
        return $aspro-elements
        else
            ()
    let $fake-target :=
        <target fake-target="y">
            <user_identifier>{$name}</user_identifier>
            <name>{$name}</name>
            <ra>{$t[1]}</ra>
            <dec>{$t[2]}</dec>
            <pmra>-0.0</pmra>
            <pmdec>-0.0</pmdec>
            {$additional-info}
        </target>
    (: let $log := util:log("info", "fake-target:")
    let $log := util:log("info", $fake-target) :)
    return $fake-target
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
        app:fake-target((), $name-or-coords, (), ())
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
        for $c in $coords return map:entry($c, app:fake-target((),$c, (), ()))
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
    let $targets-maps := app:resolve-by-names($ids)
    let $count := count($ids)
    let $lis :=
        for $id at $pos in $ids
        let $s := map:get($targets-maps, $id)
        let $log := util:log("info", <txt>loop {$pos} / {$count} : {$id} {$s} </txt>)
        let $simbad-link := if($s/@fake-target) then <a target="_blank" href="http://simbad.u-strasbg.fr/simbad/sim-coo?Coord={encode-for-uri($id)}&amp;CooEpoch=2000&amp;CooEqui=2000&amp;Radius={$app:conf?samestar-dist_as}&amp;Radius.unit=arcsec">{$id}</a> else <a target="_blank" href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($id)}">{$id}</a>
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
                            <th title="{$title}">{if($field_names[$cpos]=$detail_cols) then attribute {"class"} {"extcols"} else ()}{$name} &#160; {$unit}</th>
                        else
                            <th><span class="badge rounded-pill bg-dark">{$tr-count}</span>&#160;Simbad&#160;link&#160;for&#160;<u>{$cat?cat_name}</u></th>
                    }
                    <th>GetStar</th>
                </tr></thead>
                {
                    let $trs := $votable//*:TABLEDATA/*
                    (: compute simbad id adding a prefix to build a valid identifier :)
                    let $targets-ids := $trs/*[$source_id_idx]!concat($cat?simbad_prefix_id, .)
                    let $targets-maps := app:resolve-by-names($targets-ids)
                    for $tr in $trs return
                        <tr>{
                            let $simbad_id := $cat?simbad_prefix_id||$tr/*[$source_id_idx]
                            let $simbad := map:get($targets-maps, $simbad_id)

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
                                        element {"td"} {attribute {"class"} {if( $field_names[$cpos]=$detail_cols ) then "extcols" else ()},try { let $d := xs:double($td) return format-number($d, "0.###") } catch * { if(string-length($td)>1) then data($td) else "-" }},
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

declare %templates:wrap function app:bulk-form($node as node(), $model as map(*), $identifiers as xs:string*, $catalogs as xs:string*, $viziertable as xs:string?) {
    for $type in ("success", "danger")
        where exists(session:get-attribute($type))
        return
            <div class="alert alert-{$type} alert-dismissible fade show" role="alert">
                {session:get-attribute($type)}
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            </div>
    ,
    app:bulk-form-html($identifiers, $catalogs, $viziertable)
    ,try{ session:clear() }catch *{ () }
};

declare function app:bulk-form-html($identifiers as xs:string*, $catalogs as xs:string*, $viziertable as xs:string?) {
    let $start-time := util:system-time()
    let $config := app:config()
    let $max := $config("max")
    (: was here before max-mags to convey mags parameters
        let $params :=  for $p in request:get-parameter-names() where not ( $p=("identifiers", "catalogs") ) return <input type="hidden" name="{$p}" value="{request:get-parameter($p,' ')}"/> :)

    let $max-inputs :=  for $k in ("FT_mag","AO_mag", "declinaison") let $v := map:get($max,$k) return
        <div class="p-2"><div class="input-group">
                <span class="input-group-text">
                {
                    let $doc := map:get($max, $k||$app:doc-suffix)
                    let $label := replace($k, "_", "&#160;")
                    return
                        if(exists($doc))then <a title="{$doc}">{$label}<i class="bi bi-question-circle"></i></a> else $label
                }
                </span>
                <input name="max_{$k}" value="{$v}" class="form-control"/>

        </div></div>
    let $default-catalogs := for $cat in $app:conf?catalogs?* where exists($cat?bulk) order by $cat?main_cat descending return $cat?cat_name
    let $catalogs := if(exists($catalogs)) then $catalogs else $config?preferred?bulk_catalog
    let $cats-params := for $catalog in $default-catalogs order by $catalog
        return
            <div class="p-2"><div class="input-group">
                <div class="input-group-text">
                    { element input { attribute class {"form-check-input"}, attribute type {"checkbox"}, attribute name {"catalogs"}, attribute value {$catalog}, if ($catalog=$catalogs) then attribute checked {"true"}  else ()} }
                </div>    <span class="form-control">{$catalog}</span>
            </div></div>
    return
    (
    <div>
<h2>SearchFTT: off-axis Fringe Tracking and Adaptative Optics for interferometry</h2>
<p>This tool searches for nearby stars suitable for off-axis Fringe Tracking and off-axis Adaptive Optics.
<br/>
You can query one or several Science Targets separated by semicolon by names (resolved using Simbad for proper motion) or by coordinates (RA +/-DEC J2000). For each of them, suitable solutions will be searched. Only solutions with a valid AO and a valid FT are presented. When several solutions are found, a scoring ( \(strehl_{{SCI}} . exp( -\sigma_{{\phi}}^2 ) . exp( -\sigma_{{iso}}^2 )\) ) and ranking is proposed based on a simplified model of AO (GPAO) and FT (GRAVITY) of VLTI. If the Science Target allows it, the on-axis solution is also presented and ranked.
<br/>

<br/>
For the time being, only the NGS mode of GPAO is supported by the scoring. However, solutions can be found for the LGS mode by increasing the AO magnitude (but with wrong scoring and ranking).
<br/>
SIMBAD and Gaia DR3 catalogues are cross-matched though CDS and ESA data centers. Each query is performed within a search radius around the Science Target below a max declinaison. A magnitude filter is applied to define candidates for the FT (infrared) and for the AO (visible). Only solutions with a valid AO and a valid FT are presented in the main output table. For debug or further investigations, the list of all individual candidates can be found in the extended raw result.
</p>
        <form method="post" action="bulk.html"> <!-- force action to avoid param duplication on post -->
            <div class="d-flex p-2">
            <div class="input-group">
                <input type="text" class="form-control" placeholder="Enter your science identifiers or coordinates. Use semicolon as separator, e.g : 0 0 ; 4.321 -6.543 ; -00:11:22 +33:44:55.66 ; HD123 ; HD234 " aria-label="Science identifiers (semicolon separator)" id="identifiers" name="identifiers" value="{$identifiers}"/>
            </div>
            </div>
            <div class="d-flex p-2"><div class="p-2 justify-content-end"><label class="form-check-label ">Catalogs to query:</label></div>
                {$cats-params}
            </div>
            <div class="d-flex p-2"><div class="p-2 justify-content-end">Constraints:</div>
                {$max-inputs}
            </div>
            <div class="d-flex p-2">
                <div class="col-sm-2"><input type="submit" class="btn btn-primary" value="Submit my identifiers"/></div>
                <div class="col-sm-2"><a href="bulk.html" class="btn btn-outline-secondary" role="button"> Reset <i class="bi bi-arrow-clockwise"></i></a></div>
            </div>
            {
                if (exists($identifiers[string-length()>0])) then
                    (
                        app:searchftt-bulk-list-html($identifiers, $max, $catalogs),
                        <code class="extdebug d-none"><br/>Request processing duration : {seconds-from-duration(util:system-time()-$start-time)}s</code>,
                        <p><i class="bi bi-info-circle-fill"></i>&#160;<kbd>Shift</kbd> click in the column order buttons to combine a multi column sorting.</p>
                    )
                else ()
            }
        </form>
        {
            if (exists($identifiers[string-length()>0]) )  then () else
            <div>
            <form method="post" enctype="multipart/form-data" action="modules/inputfile.xql"><div class="d-flex p-2">
            <div class="col-sm-2"><button type="submit" class="btn btn-primary" title="You may submit an input file with one id or coordinate (RA +/-DEC in degrees J2000) per line ">Submit my file<i class="bi bi-question-circle"></i></button></div>
            <div class="col-sm-2"><input type="file" class="form-control" name="inputfile"/></div>
            <div class="col-sm-2">&#160; <a href="test/inputs/test1.csv">(see sample file)</a></div>
            </div></form>
            <form method="post" action="modules/viziertable.xql"><div class="d-flex p-2">
            <div class="col-sm-2"><button type="submit" class="btn btn-primary" title="You may request to gather coordinates using a VizieR table name">Use VizieR table <i class="bi bi-question-circle"></i></button></div>
            <div class="col-sm-2"><input type="text" class="form-control" name="viziertable" value="{$viziertable}"/></div>
            <div class="col-sm-2">&#160;<input class="form-check-input" type="checkbox" name="try-name-first"/><label class="form-check-label">Prefer name over coordinates</label></div>
            <div class="col-sm-2">&#160; <a href="modules/viziertable.xql?try-name-first=y&amp;viziertable=J/MNRAS/414/108/stars">(test J/MNRAS/414/108/stars)</a></div>
            </div></form>
            </div>
        }
    </div>
    )
};

declare function app:simbad-link($id as xs:string, $target, $ra as xs:string?, $dec as xs:string?){
    if (exists($target/ra/text()) and empty($target/@fake-target) ) then
        <a title="{$target/user_identifier} ( {$ra} {$dec} )" href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($id)}" target="_blank">{replace($target/name," ","&#160;")}&#160;<i class="bi bi-arrow-up-right-square"></i></a>
    else if (exists($ra) and exists($dec) ) then
        <span>{replace($id," ","&#160;")}<a href="http://simbad.u-strasbg.fr/simbad/sim-coo?Coord={$ra}+{$dec}&amp;CooEpoch=2000&amp;CooEqui=2000&amp;Radius={$app:conf?samestar-dist_as}&amp;Radius.unit=arcsec" title="Using coords ( {$ra} {$dec} ) because Simbad does't know : {$id}" target="_blank">&#160;<i class="bi bi-arrow-up-right-square"></i></a></span>
    else if (exists($target/ra/text()) and exists($target/dec/text()) ) then
        <span>{replace($id," ","&#160;")}<a href="http://simbad.u-strasbg.fr/simbad/sim-coo?Coord={$target/ra}+{$target/dec}&amp;CooEpoch=2000&amp;CooEqui=2000&amp;Radius={$app:conf?samestar-dist_as}&amp;Radius.unit=arcsec" title="Using coords ( {$target/ra} {$target/dec} ) because Simbad does't know : {$id}" target="_blank">&#160;<i class="bi bi-arrow-up-right-square"></i></a></span>
    else
        $target/user_identifier/text()
};

declare function app:searchftt-bulk-list-html($identifiers as xs:string*, $max as map(*), $catalogs-to-query as xs:string* ) {
    let $config := app:config()
    let $bulk-search-map := app:searchftt-bulk-list($identifiers, $catalogs-to-query)
    let $identifiers-map := $bulk-search-map?identifiers-map

    let $start-time := util:system-time()
    (: Rebuild the table (and votable) with a summary of what we have in the catalogs :)
    let $cnt := try{ count( $bulk-search-map?ranking?scores?* ) }catch * { "XX" }
	let $log := util:log("info", "merge main table to show ranked results ("|| $cnt || " for " || count($identifiers-map?*) ||" sciences))... ")

    let $detail_cols := for $e in (array:flatten($app:conf?extended-cols)) return lower-case($e)

    let $sci-cols :=  $identifiers-map?*[1]/* ! name(.)
    let $ranking-input-params := (($bulk-search-map?catalogs?*)[1])?ranking?input-params
    let $cols := ($sci-cols,"FT identifier", "AO identifier", "Score", "Rank", $ranking-input-params , "Catalog")
    let $th := <tr> {$cols ! <th>{if(.=$detail_cols) then attribute {"class"} {"extcols"} else ()} {.}</th>}</tr>

    (: prepare some data for speedup in the following loops :)
    let $cat-sciences-scores := map:merge((
        for $cat-name in map:keys($bulk-search-map?catalogs) return map:entry($cat-name, $bulk-search-map?catalogs($cat-name)?ranking?scores?* )
    ))

    (: let $log := util:log("info", ``[identifiers returned : `{string-join(map:keys($identifiers-map), ", ")}`]``) :)

    let $trs :=  map:merge((
    for $identifier at $identifier-pos in map:keys($identifiers-map) order by $identifier
        let $science := map:get($identifiers-map, $identifier)
        (: let $log := util:log("info", ``[identifier : `{$identifier}`]``) :)
        let $identifier-name := data($science/name)
        return
            map:entry($identifier,
            for $cat-name in map:keys($bulk-search-map?catalogs)
                let $cat := $bulk-search-map?catalogs($cat-name)
                let $targets-map := $cat?targets-map
                let $ranking := $cat?ranking
                let $ftaos := $cat?ranking?ftaos
                let $scores := $cat?ranking?scores
                let $science-idx := $cat?ranking?sciences-idx?($identifier-name)

                (: let $science-scores := for $idx in $science-idx return $cat?ranking?scores?*[$idx] This line is very cost effective !! prefer following one :)
                let $science-scores := for $idx in $science-idx return $cat-sciences-scores($cat-name)[$idx]

                (: reorder with NaN at the end of the sequence :)
                (: does it work ??? using  descending empty least_or_greatest return $idx ???:)
                let $ordered-science-idx := for $idx at $pos in $science-idx let $score:=$science-scores[$pos] let $score := if($score=$score) then $score else -1 order by $score descending return $idx
                let $ordered-science-scores := for $idx at $pos in $ordered-science-idx return $science-scores[$pos]

                let $inputs := $cat?ranking?inputs

                let $rows :=
                    for $idx at $pos in $ordered-science-idx
                        where $ordered-science-scores[$pos] >= $config?min?score and $pos <= $max?rank
                        let $ftao := $ftaos?*[$idx]?*
                        return
                            (: <tr class="opacity-{$opacity}"> :)
                            <tr>
                                {for $col in $sci-cols return <td>{ if($col=("name","user_identifier")) then app:simbad-link($science/*[name(.)=$col], $science,(),()) else data($science/*[name(.)=$col]) }</td>}
                                {for $id in $ftao let $t := $targets-map($id) return <td>{app:simbad-link($id, $t,$t/ra,$t/dec)}</td>}
                                <td>{$scores?*[$idx]}</td>
                                <td>{$pos}</td>
                                { let $tds := array:flatten($inputs?*[$idx]) return for $c at $pos in $ranking-input-params return <td>{$tds[$pos+1]}</td>}
                                <td>{$cat-name}</td>
                            </tr>
                (:let $log := util:log("info", "done "|| $identifier || "("||seconds-from-duration(util:system-time()-$start-time)||"s) : " || count($rows) ||"solutions" ) :)

                return $rows
            )))

    let $table := <table class="table table-bordered table-light table-hover datatable" id="bulkTable">
        <thead>{$th}</thead>
        {$trs?*}
        </table>
    let $votable := jmmc-tap:table2votable($table, "targets")

    let $error-report := for $cat in map:keys($bulk-search-map?catalogs)
        let $cat := $bulk-search-map?catalogs($cat)
        let $info := $cat?ranking
        let $error := ($cat?error,$info?error)
        where exists($error)
        return
        <div class="alert alert-danger alert-dismissible fade show" role="alert">
            {$error}
            { if (exists($info?query)) then <span><br/> query was for {$info?cat}: <br/>{$info?query}</span> else () }
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>

    let $log := util:log("info", "done ("||seconds-from-duration(util:system-time()-$start-time)||"s)")

    let $targets :=<div><h3>{ count(map:for-each($trs, function($k,$v){if(exists($v)) then $k else ()})) } targets with both FT and AO solutions
        <a class="btn btn-outline-secondary btn-sm" href="data:application/x-votable+xml;base64,{util:base64-encode(serialize($votable))}" type="application/x-votable+xml" download="input_{app:getFileSuffix($identifiers)}.vot">votable</a>&#160;
        {(:)
            for $cat-name in map:keys($bulk-search-map?catalogs)
                let $v := $bulk-search-map?catalogs($cat-name)?ranking?res
                return
                    <a class="btn btn-outline-secondary btn-sm" href="data:application/x-votable+xml;base64,{util:base64-encode(serialize($v))}" type="application/x-votable+xml" download="internal{$cat-name}.vot">internal query({$cat-name})&#160;</a>
        :)}
        </h3>
        {
            (:)
            for $cat-name in map:keys($bulk-search-map?catalogs)
                return <div class="extquery d-none"><pre><br/>{data($bulk-search-map?catalogs($cat-name)?ranking?query)}<br/></pre></div>
:)
        }
        {$error-report}
        {$table}

        <div class="p-2 d-flex">
            <div class="p-2 justify-content-end">Limit to :</div>
            <div class="p-2"><div class="input-group"><span class="input-group-text" title="1= best performance, 0= worst performance">Min score of solutions <i class="bi bi-question-circle"></i></span><input type="text" id="min_score" name="min_score" value="{$config?min?score}"/></div></div>
            <div class="p-2"><div class="input-group"><span class="input-group-text" title="this is the rank">Max number solutions per science <i class="bi bi-question-circle"></i></span><input type="text" id="max_rank" name="max_rank" value="{$max?rank}"/></div></div>
        </div>
        <div class="p-2 d-flex">
            <div class="p-2"><button class="btn btn-primary" type="submit" formaction="modules/aspro.xql">Get my ASPRO2 file 🤩</button></div>
            <div class="p-2"><button class="btn btn-primary" type="submit" formaction="modules/outputfile.xql">Get as SearchFTT input file</button></div>
            <!-- <div class="p-2"><button class="btn btn-primary" type="submit" formaction="modules/test.xql">Test this list</button></div> -->
        </div>
        <div class="extquery d-none">{for $q in $bulk-search-map?catalogs?*?ranking?query return <pre><br/>{data($q)}<br/></pre>}</div>
    </div>

    return
        ($targets
        ,<br/>,<hr/>,<em>Next debug content will be improved if not removed...</em>,<hr/>,<br/>
        ,<h2>Raw results from catalogs.</h2>
        ,<p>By now, the ut_flag and at_flag columns are not computed in the votable but the table below ( 1=FT, 2=AO, 3=FT or AO). <br/> Magnitudes columns colors are for
            <small class="d-inline-flex mb-3 px-2 py-1 fw-semibold bg-success bg-opacity-10 border border-success border-opacity-10 rounded-2">UT and AT compliancy</small>,
            <small class="d-inline-flex mb-3 px-2 py-1 fw-semibold bg-warning bg-opacity-10 border border-warning border-opacity-10 rounded-2">UT compliancy</small> or
            <small class="d-inline-flex mb-3 px-2 py-1 fw-semibold bg-danger bg-opacity-10 border border-danger border-opacity-10 rounded-2">not compatible / unknown</small>
        </p>
        , $bulk-search-map?catalogs?*?html
        ,app:datatable-script(index-of($cols, "Score"),index-of($cols, "Rank"),index-of($cols, "sci_ft_dist"),index-of($cols, "sci_ao_dist"))
        )
};

(: query given catalogs and perform for rank each ft ao compatible combination
    output structure is a map :
    - $res?identifiers-map : map {$identifier : id-info}
    - $res?catalogs : map{ $catalogName :
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
declare function app:searchftt-bulk-list($identifiers as xs:string*, $catalogs-to-query as xs:string* ) {
    let $log := util:log("info", "catalogs to query : " || string-join($catalogs-to-query))
    (: Check that we have requested catalog in our conf :)
    let $catalogs-to-query := for $cat-name in $catalogs-to-query
        where exists($app:conf?catalogs?*[?cat_name=$cat-name])
        return $cat-name

    let $config := app:config()
    let $catalogs-to-query := if(exists($catalogs-to-query)) then $catalogs-to-query else $config?preferred?bulk_catalog

    (: Cleanup requested ids and get Simbad or basic informations for each of them :)
    let $ids := distinct-values($identifiers ! tokenize(., ";") ! tokenize(., "&#9;") ! normalize-space(.))[string-length()>0]
    let $identifiers-map := app:resolve-by-names($ids)

    let $catalogs := map:merge((
        for $cat-name in $catalogs-to-query
            let $cat := $app:conf?catalogs?*[?cat_name=$cat-name]
            let $res  := try{app:bulk-search($identifiers-map, $cat)}catch *{map{"error":<div>{$err:description} : <br/> <pre>{$err:value}</pre> </div>}}
            return map:entry($cat-name,$res)
        ))

    let $bulk-search-map :=  map:merge((
        map:entry("identifiers-map",$identifiers-map),
        map:entry("catalogs", $catalogs)))

    return
        $bulk-search-map
};

declare function app:get-input-votables($ths,$trs, $split-size){
    let $size := count($trs)
    return
        for $i in 0 to xs:integer($size div $split-size)
            let $sub-trs := subsequence( $trs, 1+($i*$split-size) , ($i+1)*$split-size)
            let $table := <table class="table table-bordered table-light table-hover datatable">
                <thead>{$ths}</thead>
                {$sub-trs}
                </table>
            return
                jmmc-tap:table2votable($table, "targets")
};

declare function app:bulk-search($identifiers-map, $cat) {
    let $start-time := util:system-time()

    (: Let's build one tr for each target so we can use it for tap votable upload later :)
    let $cols := $identifiers-map?*[1]/* ! name(.)
    let $ths := <tr> {$cols ! <th>{.}</th>}</tr>
    let $trs := for $star in $identifiers-map?* where $star/ra/text() and $star/dec/text() order by $star
        return <tr> {for $col in $cols return <td>{data($star/*[name(.)=$col])}</td> } </tr>

    let $input-targets-count := count($trs)
	let $log := util:log("info", "searching bulk ftt in "||$cat?cat_name||" for " || $input-targets-count || " target(s)...")

    let $config := app:config()
    let $max := $config("max")

    (: let $input-votables :=  app:get-input-votables($ths, $trs, min((xs:integer($cat?tap_max_xmatch_votable_size), 10000 ))) leave max so the user can see the timeout :)
    let $input-votables :=  app:get-input-votables($ths, $trs, max((xs:integer($cat?tap_max_xmatch_votable_size), 10000 )))
    let $query :=  app:build-query((), $input-votables[1], $max, $cat)
    let $query-code := <div class="extquery d-none">{for $q in $query return <pre><br/>{data($q)}<br/></pre>}</div>

    let $votables := for $input-votable at $pos in $input-votables[1] (: TODO remove [1] to enable batch approach and see next TODO too :)
           	let $log := util:log("info", " subquery "|| $pos)

            let $max-rec := $max?rec * count($input-votable//*:TR) * 100 (: TODO show this magic value in doc :)
            let $votable :=
                try{
                    if(exists(request:get-parameter("dry", ())))
                    then
                        <error>dry run : remote query SKIPPED !</error>
                    else if( $input-targets-count = 0 )
                    then
                        <error>Cannot find any coordinates from your input list.</error>
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
            return $votable
    (: TODO merge votables :)
    let $votable := $votables[1]

    let $res := if($votable/error or name($votable)="error" or $votable//*:INFO[@name="QUERY_STATUS" and @value="ERROR"])
         then
            map:entry("error",
                <div class="alert alert-danger" role="alert">
                    Error trying to query remote catalog <em>{$cat?cat_name}</em>:<br/>
                    <pre>{data($votable)}</pre>
                    {util:log("error", data($votable))}
                </div>
            )
        else if(not ( contains(lower-case(name($votable/*)),"votable") ) ) (: TODO throw an exception for this case on jmmc-tap side :)
        then
            map:entry("error",
                <div class="alert alert-danger" role="alert">
                    Error trying to get votable (maybe html ? '{lower-case(name($votable/*))}') : <br/>
                    {$votable}
                    {util:log("error", data($votable))}
                </div>
            )
        else

            let $ranking := app:get-ranking($votable,$cat,$max)

            let $detail_cols := for $e in (array:flatten($app:conf?extended-cols), $cat?detail?* ) return lower-case($e)
            let $detail_fields_pos := for $e at $pos in $votable//*:FIELD/@name return if(lower-case($e)=$detail_cols) then $pos else ()

            let $field_names := for $e in $votable//*:FIELD/@name return lower-case($e)
            let $colidx := map:merge( for $e at $pos in $votable//*:FIELD/@name return map:entry(replace(lower-case($e),"computed_",""), $pos) )
            let $science_idx := index-of($field_names, "science")
            let $source_id_idx := index-of($field_names, "source_id")
            let $str_source_id_idx := index-of($field_names, "str_source_id")
            let $mag_k_idx := index-of($field_names, "mag_ks")
            let $mag_g_idx := index-of($field_names, "mag_g")
            let $mag_v_idx := (index-of($field_names, "mag_v"),index-of($field_names, "computed_mag_v"))
            let $mag_r_idx := (index-of($field_names, "mag_r"),index-of($field_names, "computed_mag_r"))
            let $at_flag_idx := index-of($field_names, "at_flag")
            let $ut_flag_idx := index-of($field_names, "ut_flag")

            let $trs := $votable//*:TR
            let $targets-ids := $trs/*[$colidx?str_source_id]
            let $targets-maps := app:resolve-by-names($targets-ids)
            (: re add non resolved ones :)
            let $targets-maps := map:merge((
                $targets-maps,
                map:merge(
                    for $tr in $trs
                        let $target-id:=$tr/*[$colidx?str_source_id]
                        where not($targets-maps($target-id)/name/text())
                        return
                            map:entry($target-id,app:fake-target($target-id,$tr/*[$colidx?ra]||" "||$tr/*[$colidx?dec], $tr, $colidx))
                )
            ))

            let $nb_rows := count($votable//*:TR)
            let $count-ftao := if(exists($ranking?sciences-idx)) then count(map:keys($ranking?sciences-idx)) else ()
            let $count-no-ftao := $input-targets-count - $count-ftao

            return (
                map:entry("html",
                    <div class="{if($cat?main_cat) then () else "extcats d-none"}">
                    <h3>
                        {$cat?cat_name} ({$nb_rows} FT or AO stars)&#160;
                        <a class="btn btn-outline-secondary btn-sm" href="data:application/x-votable+xml;base64,{util:base64-encode(serialize($votable))}" type="application/x-votable+xml" download="searchftt_{$cat?cat_name}_{app:getFileSuffix(request:get-parameter("identifiers",()))}.vot">votable</a>
                    </h3>
                    <ul>
                    <li> {$input-targets-count} targets queried </li>
                    <li> {$count-ftao} targets with both FT and AO solutions </li>
                    <li> TBD_C targets with FT only </li>
                    <li> TBD_D targets with AO only </li>
                    <li> {$count-no-ftao} targets with no candidate </li>
                    </ul>
                    <table class="table table-light table-bordered table-hover datatable exttable">
                        <thead><tr>
                            {for $field at $pos in $votable//*:FIELD
                                return
                                    <th title="{$field/*:DESCRIPTION}">{if($pos=$detail_fields_pos) then attribute {"class"} {"nnnextcols"} else ()}{data($field/@name)}</th>}
                            <th title="number of stars returned for the same science target">commons</th>
                        </tr></thead>
                        <tbody>{
                            for $src_tr in subsequence($trs,1,$max?result_table_rows) group by $science := $src_tr/*:TD[$science_idx]
                            let $group_size := count($src_tr)
                            return for $tr in $src_tr
                            let $simbad_id := $cat?simbad_prefix_id||$tr/*[$source_id_idx]
                            let $simbad := map:get($targets-maps, $simbad_id)
                            let $target_link := app:simbad-link($simbad_id, $simbad,$tr/*[index-of($field_names, "ra")],$tr/*[index-of($field_names, "dec")])
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

                            let $magg := number($tr/*[$mag_g_idx])

                            return <tr>
                                    {for $td at $pos in $tr/*:TD
                                    return <td>{
                                        switch($pos)
                                            case $source_id_idx return $target_link
                                            case $mag_k_idx return
                                                (attribute {"class"} {if ($magk<$max?magK_AT) then "table-success" else if ($magk<$max?FT_mag) then "table-warning" else "table-danger"}, data($td))
                                            case $mag_v_idx return
                                                (attribute {"class"} {if ($magv<$max?magV) then "table-success" else "table-danger"}, data($td))
                                            case $mag_r_idx return
                                                (attribute {"class"} {if ($magr<$max?magR) then "table-success" else "table-danger"}, data($td))
                                            case $mag_g_idx return
                                                (attribute {"class"} {if ($magg<$max?AO_mag) then "table-success" else "table-danger"}, data($td))
                                            case $at_flag_idx return
                                                $at_flag
                                            case $ut_flag_idx return
                                                $ut_flag
                                            default return data($td)
                                    }</td>}
                                    <td>{$group_size}</td>
                                </tr>
                        }</tbody>
                    </table>
                    {$query-code}
                    {<code class="extdebug d-none"><br/>Catalog query duration : {seconds-from-duration(util:system-time()-$start-time)}s</code>}
                    </div>
                ),
                map:entry("votable", $votable),
                map:entry("targets-map" , $targets-maps),
                map:entry("ranking", $ranking)
            )

    let $log := util:log("info", "done ("||seconds-from-duration(util:system-time()-$start-time)||"s)")
    return
        map:merge($res)

};

(: Returns a ranking map or empty value if given votable has no data :)
declare function app:get-ranking($votable, $cat, $max) {
    if(empty($votable//*:TR)) then () else
        let $start-time := util:system-time()
	    let $log := util:log("info", "  doing ranking...")

        (: prepare input with every permutations :)
        let $internal-match-query := app:build_internal_query($votable, "internal", $cat, $max)
        let $res := jmmc-tap:tap-adql-query("http://tap.jmmc.fr/vollt/tap/sync", $internal-match-query, $votable, -1, "votable/td", "internal")
        (:let $log := util:log("info", "internal match field count = "|| count($res//*:FIELD) || " rows count = "|| count($res//*:TR) ):)

        let $colidx := map:merge( for $e at $pos in $res//*:FIELD/@name return map:entry(replace(lower-case($e),"computed_",""), $pos) )
        (:let $log := util:log("info", serialize( map:keys($colidx) => sort() )):)

        let $error :=  data($res//*:INFO[@name='QUERY_STATUS' and @value='ERROR'])
        (: let $log := util:log("info", serialize($res)) :)

        (: WebService ask for : [[sci_Kmag, ft_Kmag, sci_ft_dist, ao_Rmag, sci_ao_dist, ft_ao_dist]] :)
        (: at_flag_ao at_flag_ft cat_dist_as_ao cat_dist_as_ft dec_ao dec_ft epoch_ao epoch_ft j2000_dist_as_ao j2000_dist_as_ft j2024_dist_as_ao j2024_dist_as_ft
           mag_g_ao mag_g_ft mag_ks_ao mag_ks_ft mag_r_ao mag_r_ft
           mag_v_ao mag_v_ft otype_txt_ao otype_txt_ft pmdec_ao pmdec_ft pmra_ao pmra_ft ra_ao ra_ft science ft_ao_dist_as source_id_ao source_id_ft ut_flag_ao ut_flag_ft
        :)
        let $input-params := ("ft_mag","sci_ft_dist","ao_mag","sci_ao_dist","ft_ao_dist")

        (: TODO test if pre process of colidx could speedup array building process :)
        let $inputs := array{
                 for $tr at $pos in $res//*:TR
                    return array{
                        (
                        0,
                        number($tr/*:TD[$colidx("mag_ks_ft")]),
                        number($tr/*:TD[$colidx("cat_dist_as_ft")]),
                        ( for $c in ("mag_g_ao","mag_r_ao","mag_v_ao") let $v := number($tr/*:TD[$colidx($c)]) where $v=$v return $v)[1],
                        number($tr/*:TD[$colidx("cat_dist_as_ao")]),
                        number($tr/*:TD[$colidx("ft_ao_dist_as")])
                        )
                    }
            }

        let $start-time2 := util:system-time()
        let $scores := if(exists($res//*:TR)) then jmmc-ws:pyws-ut_ngs_score($inputs) else ()
        let $start-time3 := util:system-time()

        let $ftaos := array{ for $tr at $pos in $res//*:TR
              return array{ data($tr/*:TD[$colidx?str_source_id_ft]), data($tr/*:TD[$colidx?str_source_id_ao]) }
            }

        let $map-by-sci  := map:merge((
            for $tr at $pos in $res//*:TR group by $science := data($tr/*:TD[1])
                return map:entry($science,$pos)
        ))

        let $log := util:log("info", "  done ("||seconds-from-duration(util:system-time()-$start-time)||"s  / "||seconds-from-duration($start-time3 - $start-time2) ||" for webservice) for "|| count($scores?*) || " analysed solutions")
        return
            map{"res":$res, "cat":$cat?cat_name, "error":$error, "query": $internal-match-query, "sciences-idx" : $map-by-sci , "ftaos": $ftaos ,"scores": $scores, "inputs":$inputs, "input-params":$input-params}
};

declare function app:build_internal_query($votable, $table-name, $cat, $max){
    (: iterate on every columns except science and add a new distance :)
    let $colnames := for $f in $votable//*:FIELD/@name return lower-case($f)

    let $vmag := $cat?mag_v
    let $rmag := $cat?mag_r
    let $computed_prefix := if($vmag and $rmag ) then () else "computed_"
    let $ft-filters := <text>(ft.mag_ks &lt; {$max?FT_mag})</text>
    let $ao-filters := <text>( ao.mag_g&lt;{$max?AO_mag} OR ao.{$computed_prefix}mag_r&lt;{$max?AO_mag} OR ao.{$computed_prefix}mag_v&lt;{$max?AO_mag} )</text>

    let $ftao-dist := <text>DISTANCE( POINT( 'ICRS', ft.ra, ft.dec),POINT('ICRS', ao.ra, ao.dec))*3600.0</text>
    let $dist-filter := <text>(({$ftao-dist}) &lt; {2 * $max?dist_as})</text>

    let $internal-match := string-join((
        "SELECT",
        "  "||string-join(
            ("ft.science as science",
            $ftao-dist || " as ft_ao_dist_as",
            for $c in $colnames[not(.="science")] return
                for $type in ("ft", "ao")
                    return string-join( (($type, ".", $c), " as ", $c, "_"[exists($c)], $type) )
            ),",&#10;  "),
        "FROM",
        "  TAP_UPLOAD."||$table-name||" as ft , TAP_UPLOAD."||$table-name||" as ao ",
        "WHERE",
        "  " || $ft-filters || " AND " || $ao-filters || " AND " || $dist-filter
        ),"&#10;")

    return
        $internal-match
};

(: A votable is given in bulk mode.
    bulk query are not the same as the individual one.
    limits are not the same bulk uses max.FT_mag and max.AO_mag (on G R V)

:)
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
    let $science-name-col := if($votname) then $votname||".my_name as science, " else ()
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
        then <text>({$cat?mag_k }&lt;{$max?FT_mag} OR {$v_filter}&lt;{$max?AO_mag} OR {$r_filter}&lt;{$max?AO_mag} OR {$cat?mag_g}&lt;{$max?AO_mag})</text>
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
        {if ( exists($cat?simbad_prefix_id) ) then "'"||$cat?simbad_prefix_id||"' ||" else () } {$cat?source_id} as str_source_id,
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

declare function app:genTargetIds($names as xs:string*) as xs:string*
{
    $names ! translate(., ' &lt;&gt;?,;:/!*%$^&amp;~#{[|`\^@]}°', '______________________________')
};


declare function app:getFileSuffix($identifiers as xs:string*) as xs:string
{
    let $nmax:=3
    let $dots := if ( count($identifiers) > $nmax ) then "..." else ()
    return
        string-join((subsequence($identifiers, 1, $nmax), $dots), "_")
};
