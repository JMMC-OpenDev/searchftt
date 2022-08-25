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
    "extended-cols" : [ "pmra", "pmdec", "pmde", "epoch", "cat_dist_as"],
    "samestar-dist_deg" : 2.78E-4,
    "samestar-dist_as" : 1,
    "catalogs":{
        "gdr2ap": {
            "cat_name":"GDR2AP",
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
            "cat_name"    : "Gaia DR3",
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
        },"gsc":    {
            "cat_name"    : "GSC2",
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

(: harcoded column indexes so we can present an html on top of a votable (without dynamic lookup) - MUST be consistent with generated queries :)
declare variable $app:id_index := 1;
declare variable $app:ra_index := 3;
declare variable $app:dec_index := 4;

(:~
 : Build a map with default value comming from given config or overidden by user params.
 : Caller will use it as $max?keyname to retrieve $conf?max_keyname or max_keyname parameter

 : @return a map with default values to use in the application.
:)
declare function app:defaults() as map(*){
    map:entry("max", map:merge(
        for $key in map:keys($app:conf?default)
            let $mapkey:=replace($key, "max_", "")
            let $mapvalue:= xs:double(try{ xs:double( request:get-parameter($key, "") ) }catch * {$app:conf?default($key)})
            return map:entry($mapkey, $mapvalue)
        )
    )
};

declare %templates:wrap function app:dyn-nav-li($node as node(), $model as map(*), $identifiers as xs:string*) {
    let $toggle-classes := map{ "extcols" : "extended columns", "extquery" : "queries", "extdebug" : "debug" }
    return
        <li class="nav-link">{
            map:for-each( $toggle-classes, function ($k, $label) {
                <div class="form-check form-check-inline form-switch nav-orange">
                    <input class="form-check-input" type="checkbox" onClick='$(".{$k}").toggleClass("d-none");'/><label class="form-check-label">{$label}</label>
                </div>
            })
        }</li>[exists($identifiers)]
};

declare %templates:wrap function app:form($node as node(), $model as map(*), $identifiers as xs:string*) {
    let $max := app:defaults()("max")
    return
    (
    <div>
        <h1>GRAVITY-wide: finding off-axis fringe tracking targets.</h1>
        <p>This newborn tool is in its first version and is subject to various changes in its early development phase.</p>
        <h2>Underlying method:</h2>
        <p>
            You can query one or several Science Targets. For each of them, three results of Fringe Tracker Targets will be given using following research methods: <br/>
            <ol>
                <li>Simbad for sources that are suitable for fringe tracking.</li>
                { for $cat in $app:conf?catalogs?* return <li><b>{$cat?cat_name}</b>&#160;{parse-xml("<span>"||$cat?description||"</span>")}</li>}

            </ol>
            Each query is performed within {$max?dist_as}&apos; of the Science Target.
            A magnitude filter is applied on every Fringe Tracker Targets according to the best limits offered in P110
            for <b>UT (MACAO) OR AT (NAOMI)</b>  respectively <b>( K &lt; {$max?magK_UT} AND V &lt; {$max?magV} ) OR ( K &lt; {$max?magK_AT} AND R&lt;{$max?magR} )</b>.
            When missing, the V and R magnitudes are computed from the Gaia G, Grb and Grp magnitudes.
            The user must <b>refine its target selection</b> to take into account <a href="https://www.eso.org/sci/facilities/paranal/instruments/gravity/inst.html">VLTI Adaptive Optics specifications</a> before we offer a configuration selector in a future release.
        </p>
        <p>
            <ul>
                <li>Enter comma separated names ( resolved by <a href="http://simbad.u-strasbg.fr">Simbad</a>) or coordinates (RA +/-DEC in degrees J2000), in the TextBox below.</li>
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
        </form>
    </div>
    ,
    if (exists($identifiers)) then (
        app:searchftt-list($identifiers, $max),
        <script type="text/javascript">
        $(document).ready(function() {{
        $('.datatable').DataTable( {{
            "paging": false,"searching":false,"info": false,
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
        return <s><name>{normalize-space($name-or-coords)}</name><ra>{$t[1]}</ra><dec>{$t[2]}</dec><pmra>0.0</pmra><pmdec>0.0</pmdec></s>
};

declare function app:searchftt-list($identifiers as xs:string, $max as map(*) ) {

    let $fov_deg := 3 * $max?dist_as div 3600

    let $ids := $identifiers ! tokenize(., ",") ! tokenize(., ";")

    let $lis :=
        for $id at $pos in $ids
        let $s := app:resolve-by-name($id)
        let $ra := $s/ra let $dec := $s/dec
        let $info := if(exists($s/ra))then
                <ol class="list-group list-group-numbered">
                {
                    for $e in (
                        app:search-simbad($id, $max, $s),
                        for $cat in $app:conf?catalogs?* return app:search($id, $max, $s, $cat)
                        )
                        return <li class="list-group-item d-flex justify-content-between align-items-start"><div class="ms-2 me-auto">{$e}</div></li>
                }
                </ol>
            else
                <div>Can&apos;t get position from Simbad, please check your identifier.</div>
        let $state := if(exists($info//table)) then "success" else if(exists($s/ra)) then "warning" else "danger"
        let $ff :=()
        return
            <div><ul class="p-1 list-group">
                <li class="list-group-item list-group-item-{$state}">
                    <div class="">
                        <div class="row">
                            <div class="col"><b><a href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($id)}">{$id}</a></b>
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
                                { if (exists($s/ra)) then
                                    <div class="col d-flex flex-row-reverse">
                                        <div id="aladin-lite-div{$pos}" style="width:200px;height:200px;"></div>
                                        <script type="text/javascript">
                                            var aladin = A.aladin('#aladin-lite-div{$pos}', {{survey: "P/2MASS/H", fov:{$fov_deg}, target:"{$id}" }});
                                        </script>
                                    </div>
                                    else ()
                                }
                        </div>
                        <div class="row">
                            { $info }
                        </div>
                    </div>
                </li>
            </ul></div>
    return
        (<script type="text/javascript" src="https://aladin.u-strasbg.fr/AladinLite/api/v2/latest/aladin.min.js" charset="utf-8"></script>, $lis)
};

declare function app:search-simbad($id, $max, $s) {
	let $query := app:searchftt-simbad-query($id,$max)
    let $query-code := <pre class="extquery d-none"><br/>{data($query)}</pre>
    let $votable := try{jmmc-tap:tap-adql-query($jmmc-tap:SIMBAD-SYNC, $query, $max?rec) } catch * {()}
    let $html-form-url := ""
    return
        if(exists($votable//*:TABLEDATA/*)) then
        let $detail_cols := for $e in array:flatten($app:conf?extended-cols) return lower-case($e) (: values correspond to column names given by AS ...:)
        let $field_names := for $e in $votable//*:FIELD/@name return lower-case($e)
        let $tr-count := count($votable//*:TABLEDATA/*)
        return
        <div class="aaaaa">
            <table class="table table-responsive-xxl table-light datatable" data-found-targets="{$tr-count}" data-src-targets="Simbad">
                <thead><tr><th><span class="badge rounded-pill bg-dark">{$tr-count}</span>&#160;Simbad&#160;Name</th>
                    {for $f at $cpos in $votable//*:FIELD where $cpos != $app:id_index
                        let $unit :=if (ends-with($f/@name, "_as")) then "[arcsec]" else if (data($f/@unit)) then "["|| $f/@unit ||"]" else ()
                        let $name :=if (ends-with($f/@name, "_as")) then replace($f/@name, "_as", "") else data($f/@name)
                        return
                        <th title="{$f/*:DESCRIPTION}">{if($field_names[$cpos]=$detail_cols) then attribute {"class"} {"d-none extcols table-info"} else ()}{$name} &#160; {$unit}</th>
                    }
                    <th>GetStar</th>
                </tr></thead>
                    {
                    for $tr in $votable//*:TABLEDATA/* return
                        <tr>{
                            let $main_id := $tr/*[1] (: id alway must be requested as first param in the query :)
                            let $target_link := <a href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($main_id)}" target="_new_simbad">{replace($main_id," ","&#160;")}</a>
                            let $getstar-url := "https://apps.jmmc.fr/~sclws/getstar/sclwsGetStarProxy.php?star="||encode-for-uri($main_id)
                            let $getstar-link := <a href="{$getstar-url}" target="{$main_id}"><i class="bi bi-box-arrow-up-right"></i></a>
                            return
                                (
                                    <td>{$target_link}</td>,
                                    for $td at $cpos in $tr/* where $cpos != 1 return
                                        element {"td"} {attribute {"class"} {if( $field_names[$cpos]=$detail_cols ) then "d-none extcols table-info" else ()},try { let $d := xs:double($td) return format-number($d, "0.###") } catch * { if(string-length($td)>1) then data($td) else "-" }},
                                    <td>{$getstar-link}<!--{$getstar-votable//*:TABLEDATA/*:TR/*:TD[121]/text()}--></td>
                                )
                        }</tr>
                }
            </table>
            {$query-code}
        </div>
        else
            <div>
                Sorry, no fringe traking star found for <b>{$s/name/text()}</b> in Simbad. {$query-code}
            </div>
};

declare function app:searchftt-simbad-query($identifier, $max) as xs:string{
    let $s := app:resolve-by-name($identifier)
    let $ra := $s/ra
    let $dec := $s/dec
    let $max-mag-filters := <text>( K&lt;{$max?magK_UT} AND V&lt;{$max?magV} ) OR ( K&lt;{$max?magK_AT} AND R&lt;{$max?magR})</text>
    let $query := <text>
    SELECT
        DISTINCT main_id, DISTANCE(POINT('ICRS', ra, dec),POINT('ICRS', {$ra},{$dec}))*3600.0 as dist_as, ra, dec, pmra,pmdec, G, K, V, R, otype_txt
    FROM
        basic JOIN allfluxes ON oid=oidref JOIN ident USING(oidref)
    WHERE
        ( {$max-mag-filters} )
          AND
        CONTAINS( POINT('ICRS', ra, dec), CIRCLE('ICRS', {$ra}, {$dec}, {$app:conf?samestar-dist_deg}) ) = 0
          AND
        CONTAINS(POINT('ICRS', ra, dec), CIRCLE('ICRS', {$ra}, {$dec}, {$max?dist_as}/3600.0)) = 1
    ORDER BY
        dist_as;
    </text>
    return
        $query
};

declare function app:search($id, $max, $s, $cat) {
	let $query := app:searchftt-query($id, $max, $cat)
    let $query-code := <pre class="extquery d-none"><br/>{data($query)}</pre>
    let $votable := jmmc-tap:tap-adql-query($cat?tap_endpoint,$query, $max?rec, $cat?tap_format)
	let $src := if ($cat?tap_viewer)  then <a class="extquery d-none" href="{$cat?tap_viewer||encode-for-uri($query)}">View original votable</a> else ()

    return

    if(exists($votable//*:TABLEDATA/*)) then
        let $detail_cols := for $e in (array:flatten($app:conf?extended-cols), $cat?detail?*) return lower-case($e) (: values correspond to column names given by AS ...:)
        let $field_names := for $e in $votable//*:FIELD/@name return lower-case($e)
        let $tr-count := count($votable//*:TABLEDATA/*)
        return
        <div class="table-responsive">
            <table class="table table-light datatable" data-found-targets="{$tr-count}" data-src-targets="{$cat?cat_name}">
                <thead><tr>
                    {for $f at $cpos in $votable//*:FIELD return
                        if ($cpos != $app:id_index) then
                            let $title := if("cat_dist_as"=$f/@name) then "Distance computed moving science star to the catalog epoch using its proper motion" else $f/*:DESCRIPTION
                            let $title := if("j2000_dist_as"=$f/@name) then "Distance computed moving candidates to J2000" else $f/*:DESCRIPTION
                            let $name := if(starts-with($f/@name, "computed_")) then replace($f/@name, "computed_", "") else data($f/@name)
                            let $name :=  replace($name, "j_2mass", "2MASS&#160;J")
                            let $name :=if (ends-with($name, "_as")) then replace($name, "_as", "") else data($name)
                            let $unit :=if (ends-with($f/@name, "_as")) then "[arcsec]" else if(starts-with($f/@name, "computed_")) then "(computed)" else if (data($f/@unit)) then "["|| $f/@unit ||"]" else ()

                            return
                            <th title="{$title}">{if($field_names[$cpos]=$detail_cols) then attribute {"class"} {"d-none extcols table-info"} else ()}{$name} &#160; {$unit}</th>
                        else
                            <th><span class="badge rounded-pill bg-dark">{$tr-count}</span>&#160;Simbad&#160;link&#160;for&#160;<u>{$cat?cat_name}</u></th>
                    }
                    <th>GetStar</th>
                </tr></thead>
                {
                    for $tr in $votable//*:TABLEDATA/* return
                        <tr>{
                            let $simbad_id := $cat?simbad_prefix_id||$tr/*[$app:id_index]
                            let $simbad := jmmc-simbad:resolve-by-name($simbad_id)
                            let $target_link := if ($simbad/ra) then <a href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($simbad_id)}">{replace($simbad/name," ","&#160;")}</a> else
                                let $ra := $tr/*[$app:ra_index]
                                let $dec := $tr/*[$app:dec_index]
                                return <a href="http://simbad.u-strasbg.fr/simbad/sim-coo?Coord={$ra}+{$dec}&amp;CooEpoch=2000&amp;CooEqui=2000&amp;Radius={$app:conf?samestar-dist_as}&amp;Radius.unit=arcsec" title="Using coords because Simbad does't know : {$simbad_id}">{replace($simbad_id," ","&#160;")}</a>
                            let $getstar-url := "https://apps.jmmc.fr/~sclws/getstar/sclwsGetStarProxy.php?star="||encode-for-uri($simbad/name)
                            let $getstar-link := if ($simbad/ra) then <a href="{$getstar-url}" target="{$simbad/name}"><i class="bi bi-box-arrow-up-right"></i></a>  else "-"
                            return
                                (
                                    <td>{$target_link}</td>,
                                    for $td at $cpos in $tr/* where $cpos != 1 return
                                        element {"td"} {attribute {"class"} {if( $field_names[$cpos]=$detail_cols ) then "d-none extcols table-info" else ()},try { let $d := xs:double($td) return format-number($d, "0.###") } catch * { if(string-length($td)>1) then data($td) else "-" }},
                                    <td>{$getstar-link}<!--{$getstar-votable//*:TABLEDATA/*:TR/*:TD[121]/text()}--></td>
                                )
                        }</tr>
                }
            </table>
            <span class="extdebug d-none">{serialize($votable//*:COOSYS[1])}</span> {$query-code} {$src}
        </div>
    else
        <div>
            {
                if ( $votable//*:INFO[@name="QUERY_STATUS" and @value="ERROR"] ) then let $anchor := "error-"||util:uuid() return
                    <a id="{$anchor}" href="#{$anchor}" class="text-danger" onclick='$(".extdebug").toggleClass("d-none");'>Sorry, an error occured in the query.</a>
                else
                    <span>Sorry, no fringe traking star found for <b>{$s/name/text()} in {$cat?cat_name}</b>.</span>
            }
            {$query-code} {$src} <code class="extdebug d-none"><br/>{serialize($votable)}</code>
        </div>
};

declare function app:searchftt-query($identifier, $max, $cat as map(*)){

    let $s := app:resolve-by-name($identifier)
    let $ra := $s/ra
    let $dec := $s/dec
    let $pmra := try{ xs:double($s/pmra) } catch * {0}
    let $pmdec := try{ xs:double($s/pmdec) } catch * {0}

    (: We could have built query with COALESCE to replace missing pmra by 0, but:
        GAVO does not support it inside a formulae and VizieR forbid it  :(
    :)
    let $distance_J2000 := <dist_as>DISTANCE(
        POINT( 'ICRS', {$cat?ra} - ( ({$cat?epoch}-2000.0) * {$cat?pmra} ) / 3600000.0, {$cat?dec} - ( ( {$cat?epoch}-2000.0) * {$cat?pmdec} ) / 3600000.0  ),
        POINT( 'ICRS', {$ra}, {$dec} )
        )*3600.0 as j2000_dist_as</dist_as>

    let $distance_catalog :=
        <dist_as>DISTANCE( POINT('ICRS', {$cat?ra}, {$cat?dec}), POINT('ICRS', {$ra}-((2000.0-{$cat?epoch})*{$pmra})/3600000.0, {$dec}-((2000.0-{$cat?epoch})*{$pmdec})/3600000.0 ))*3600.0 as cat_dist_as</dist_as>

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

    let $mags := string-join((
        <m>{$cat?mag_k} as mag_ks</m>
        ,<m>{$cat?mag_g} as mag_g</m>[$cat?mag_g]
        ,<m>{$v_filter} as {$computed_prefix}mag_v</m>
        ,<m>{$r_filter} as {$computed_prefix}mag_r</m>
        ,map:for-each( $cat?detail, function ($i, $j) { $i || ' AS ' ||$j})
        ), ", ")

    let $query := <text>
    SELECT
        {$cat?source_id},
        {$distance_J2000},
        {$distance_catalog},
        {$cat?ra}, {$cat?dec},
        {$cat?pmra}, {$cat?pmdec},
        {$cat?epoch} as epoch,
        {$mags}
    FROM
        {$from}
    WHERE
        {$max-mag-filters}
            AND
        CONTAINS( POINT('ICRS', {$cat?ra}, {$cat?dec}), CIRCLE('ICRS', {$ra_in_cat}, {$dec_in_cat}, {$max?dist_as}/3600.0) ) = 1
    ORDER BY
        j2000_dist_as
    </text>
    return
        $query
};


