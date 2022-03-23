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


(: Constants :)
declare variable $app:default_max_magV := 15;
declare variable $app:default_max_magK_UT := 11;
declare variable $app:default_max_magK_AT := 10;
declare variable $app:default_max_magR := 12.5;
declare variable $app:default_max_dist_as := 30; 


declare %templates:wrap function app:form($node as node(), $model as map(*), $identifiers as xs:string*) {
    let $max_dist_as := request:get-parameter("max_dist_as", $app:default_max_dist_as)
    let $max_magV := request:get-parameter("max_magV", $app:default_max_magV)
    let $max_magK_UT := request:get-parameter("max_magK_UT", $app:default_max_magK_UT)
    let $max_magK_AT := request:get-parameter("max_magK_AT", $app:default_max_magK_AT) 
    let $max_magR := request:get-parameter("max_magR", $app:default_max_magR) 
    return 
    (
    <div>
        <h1>GRAVITY-wide: finding off-axis fringe tracking targets.</h1>
        <p>This newborn tool is in its first version and is subject to various changes in its early development phase.</p>
        <h2>Underlying method:</h2>
      <p>
      You can query one or several Science Targets. For each of them, three results of Fringe Tracker Targets will be given using following research methods: <br/>
        <ol>
            <li>Simbad for sources that are suitable for  fringe tracking.</li>
            <li>GAIA DR2 catalogues <a href="https://arxiv.org/pdf/1808.09151.pdf">with its external catalogues cross-match</a> though <a href="https://gea.esac.esa.int/archive/">ESA archive center</a>.</li>
            <li>The <a href = "https://ui.adsabs.harvard.edu/abs/2022arXiv220103252F/abstract">Astrophysical Parameters from Gaia DR2, 2MASS &amp; AllWISE</a>  catalog through the GAVO DC.</li>
        </ol>
        
        Each query is performed within {$max_dist_as}" of the Science Target. A magnitude filter is applied on every Fringe Tracker Targets according to the best limits offered in P110  for <b>UT (MACAO) OR AT (NAOMI)</b>  respectively <b>( K &lt; {$max_magK_UT} AND V &lt; {$max_magV} ) OR ( K &lt; {$max_magK_AT} AND R&lt;{$max_magR} )</b>. When missing, the V and R magnitudes are computed from the Gaia G, Grb and Grp magnitudes. The user must <b>refine its target selection</b> to take into account <a href="https://www.eso.org/sci/facilities/paranal/instruments/gravity/inst.html">VLTI Adaptive Optics specifications</a> before we offer a configuration selector in a future release. 
        
    </p>
    
    
    <p>
        <ul>
            <li>Enter  name, the resolution of which is relied on <a href="http://simbad.u-strasbg.fr">Simbad</a>, in the Text Box below.</li>
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
    if (exists($identifiers)) then app:searchftt-list($identifiers) else ()
    
    )
};

declare function app:searchftt-list($identifiers as xs:string) {
    let $max_dist_as := request:get-parameter("max_dist_as", $app:default_max_dist_as)
    let $fov_deg := 3 * $max_dist_as div 3600

    
    let $ids := $identifiers ! tokenize(., ",") ! tokenize(., ";")
    let $lis :=
        for $id at $pos in $ids 
        let $s := jmmc-simbad:resolve-by-name($id)
        let $ra := $s/ra let $dec := $s/dec
        let $info := if(exists($s/ra))then 
            let $max := 25
                return 
                    <ol class="list-group list-group-numbered">
                    {
                        for $e in ( app:search-simbad($id, $max, $s), app:search-esagaia($id, $max, $s), app:search-gdr2ap($id, $max, $s) )
                            return <li class="list-group-item d-flex justify-content-between align-items-start"><div class="ms-2 me-auto">{$e}</div></li>
                    }
                    </ol>
            else
                <div>Can't get position from Simbad, please check your identifier.</div>
        let $state := if(exists($info//table)) then "success" else if(exists($s/ra)) then "warning" else "danger"
        let $ff :=()
        return 
            <div><ul class="p-1 list-group">
                <li class="list-group-item list-group-item-{$state}">
                    <div class="">
                        <div class="row">
                            <div class="col"><a href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($id)}">{$id} &#160;-&#160; {$ra}&#160;{$dec}</a></div>
                            <div class="col d-flex flex-row-reverse">
                                <div id="aladin-lite-div{$pos}" style="width:200px;height:200px;"></div>
                                { if (exists($s/ra)) then 
                                    <script type="text/javascript">
                                        var aladin = A.aladin('#aladin-lite-div{$pos}', {{survey: "P/2MASS/color", fov:{$fov_deg}, target:"{$id}" }});
                                    </script>
                                    else ()
                                }
                            </div>
                        </div>
                        <div class="row">
                            { $info }
                        </div>
                    </div>
                </li>
            </ul></div>
    return
        
            (<script type="text/javascript" src="https://aladin.u-strasbg.fr/AladinLite/api/v2/latest/aladin.min.js" charset="utf-8"></script>,
             $lis,
            (<ul class="p-1 list-group"><li class="list-group-item d-flex justify-content-between align-items-start">
                <div class="ms-2 me-auto">
                  <div class="form-check form-switch">
                      <label class="form-check-label extcols">Show more information</label>
                      <label class="form-check-label extcols d-none">Show basic information</label>
                      <input class="form-check-input" type="checkbox" onClick='$(".extcols").toggleClass("d-none");'/>
                  </div>
                </div>
            </li></ul>)[true() or $lis//table]
            )
};

declare function app:search-simbad($id, $max, $s) {
	let $query := app:searchftt-simbad-query($id,$max)
            let $votable := try{jmmc-tap:tap-adql-query($jmmc-tap:SIMBAD-SYNC, $query, $max) } catch * {()}
            let $html-form-url := ""
            let $extcols := ( 1500 ) (: detailed cols (hidden by default) :)
            return 
                if(exists($votable//*:TABLEDATA/*)) then 
                <div class="table-responsive">
                    <table class="table">
                        <thead><tr><th>Simbad Name</th>
                            {for $f at $cpos in $votable//*:FIELD where $cpos != 1
                                let $unit :=if (ends-with($f/@name, "_as")) then "[arcsec]" else if (data($f/@unit)) then "["|| $f/@unit ||"]" else ()
                                return 
                                <th title="{$f/*:DESCRIPTION}">{if($cpos=$extcols) then attribute {"class"} {"d-none extcols"} else ()}{data($f/@name)} &#160; {$unit}</th>
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
                                                element {"td"} {attribute {"class"} {if($cpos=$extcols) then "d-none extcols" else ()}, try { let $d := xs:double($td) return format-number($d, "0.###") } catch * { data($td) }},
                                            <td>{$getstar-link}<!--{$getstar-votable//*:TABLEDATA/*:TR/*:TD[121]/text()}--></td>
                                        )
                                }</tr>
                        }
                    </table>
                    <code class="extcols d-none"><br/>{$query}</code>
                </div>
                else
                    <div>
                        Sorry, no fringe traking star found for <b>{$s/name/text()}</b> in <a href="{$html-form-url}">Simbad</a>
                        <code class="extcols d-none"><br/>{$query}</code>.
                    </div>
};

declare function app:search-esagaia($id, $max, $s) {
	let $query := app:searchftt-esagaia-query($id,$max)
    let $tapserver := ""
    
    let $votable := jmmc-tap:tap-adql-query("https://gea.esac.esa.int/tap-server/tap/sync", $query, $max, "votable_plain")
            let $html-form-url := ""
            let $extcols := ( 1500 ) (: detailed cols (hidden by default) :)
            return 
                if(exists($votable//*:TABLEDATA/*)) then 
                <div class="table-responsive">
                    <table class="table">
                        <thead><tr><th>Simbad link</th>
                            {for $f at $cpos in $votable//*:FIELD where $cpos != 1
                                let $name := if(starts-with($f/@name, "computed_")) then replace($f/@name, "computed_", "") else data($f/@name)
                                let $name :=  replace($name, "j_2mass", "2MASS&#160;J")
                                let $unit :=if (ends-with($f/@name, "_as")) then "[arcsec]" else if(starts-with($f/@name, "computed_")) then "(computed)" else if (data($f/@unit)) then "["|| $f/@unit ||"]" else ()
                                
                                return 
                                <th title="{$f/*:DESCRIPTION}">{if($cpos=$extcols) then attribute {"class"} {"d-none extcols"} else ()}{$name} &#160; {$unit}</th>
                            }
                            <th>GetStar</th>
                        </tr></thead>
                            {                    
                            for $tr in $votable//*:TABLEDATA/* return 
                                <tr>{
                                    let $gdr2_id := "GAIA DR2 "||$tr/*[1] (: id alway must be requested as first param in the query :)
                                    let $simbad := jmmc-simbad:resolve-by-name($gdr2_id)
                                    let $target_link := if ($simbad/ra) then <a href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($gdr2_id)}">{replace($simbad/name," ","&#160;")}</a> else $gdr2_id
                                    let $getstar-url := "https://apps.jmmc.fr/~sclws/getstar/sclwsGetStarProxy.php?star="||encode-for-uri($simbad/name)
                                    let $getstar-link := if ($simbad/ra) then <a href="{$getstar-url}" target="{$simbad/name}"><i class="bi bi-box-arrow-up-right"></i></a>  else "-"
                                    return 
                                        (
                                            <td>{$target_link}</td>,
                                            for $td at $cpos in $tr/* where $cpos != 1 return 
                                                element {"td"} {attribute {"class"} {if($cpos=$extcols) then "d-none extcols" else ()}, try { let $d := xs:double($td) return format-number($d, "0.###") } catch * { data($td) }},
                                            <td>{$getstar-link}<!--{$getstar-votable//*:TABLEDATA/*:TR/*:TD[121]/text()}--></td>
                                        )
                                }</tr>
                        }
                    </table>
                    <code class="extcols d-none"><br/>{$query}</code>
                </div>
                else
                    <div>
                        Sorry, no fringe traking star found for <b>{$s/name/text()}</b> in <a href="{$html-form-url}">https://gea.esac.esa.int/archive/</a> <code class="extcols d-none"><br/>{$query}</code>.
                        <code class="extcols d-none"><br/>{$query}</code>
                    </div>
};


declare function app:search-gdr2ap($id, $max, $s) {
	let $query := app:searchftt-query($id,$max)
            let $votable := try { jmmc-tap:tap-adql-query('https://dc.zah.uni-heidelberg.de/tap/sync',$query, $max) } catch * {()}
            let $html-form-url := "http://dc.g-vo.org/__system__/adql/query/form?__nevow_form__=genForm&amp;query="||encode-for-uri($query)||"&amp;MAXREC="||$max||"&amp;_FORMAT=HTML&amp;submit=Go"
            let $extcols := ( 5 to 10 ) (: detailed cols (hidden by default) :)
            return 
                if(exists($votable//*:TABLEDATA/*)) then 
                <div class="table-responsive">
                    <table class="table">
                        <thead><tr><th>Simbad link </th>
                            {for $f at $cpos in $votable//*:FIELD where $cpos != 1
                                let $name := if(starts-with($f/@name, "computed_")) then replace($f/@name, "computed_", "") else data($f/@name)
                                let $unit :=if (ends-with($f/@name, "_as")) then "[arcsec]" else if(starts-with($f/@name, "computed_")) then "(computed)" else if (data($f/@unit)) then "["|| $f/@unit ||"]" else ()
                                return 
                                <th title="{$f/*:DESCRIPTION}">{if($cpos=$extcols) then attribute {"class"} {"d-none extcols"} else ()}{$name} &#160; {$unit}</th>
                            }
                            <th>GetStar</th>
                        </tr></thead>
                        {
                            for $tr in $votable//*:TABLEDATA/* return 
                                <tr>{
                                    let $gdr2_id := "GAIA DR2 "||$tr/*[1] (: id alway must be requested as first param in the query :)
                                    let $simbad := jmmc-simbad:resolve-by-name($gdr2_id)
                                    let $target_link := if ($simbad/ra) then <a href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($gdr2_id)}">{replace($simbad/name," ","&#160;")}</a> else $gdr2_id
                                    let $getstar-url := "https://apps.jmmc.fr/~sclws/getstar/sclwsGetStarProxy.php?star="||encode-for-uri($simbad/name)
                                    let $getstar-link := <a href="{$getstar-url}" target="{$simbad/name}"><i class="bi bi-box-arrow-up-right"></i></a> 
                                    return 
                                        (
                                            <td>{$target_link}</td>,
                                            for $td at $cpos in $tr/* where $cpos != 1 return 
                                                element {"td"} {attribute {"class"} {if($cpos=$extcols) then "d-none extcols" else ()},try { format-number(number($td), "0.###") } catch * { data($td) }},
                                            <td>{$getstar-link}<!--{$getstar-votable//*:TABLEDATA/*:TR/*:TD[121]/text()}--></td>
                                        )
                                }</tr>
                        }
                    </table>
                    <a target="_new" href="{$html-form-url}">View original votable @ GAVO</a>&#160;({serialize($votable//*:COOSYS)})
                    <code class="extcols d-none"><br/>{$query}</code>
                </div>
                else
                    <div>
                        Sorry, no fringe traking star found for <b>{$s/name/text()}</b> in the <a href="{$html-form-url}">GAVO</a>'s <a href="https://ui.adsabs.harvard.edu/abs/2022arXiv220103252F/abstract"> gdr2ap catalogue</a>.
                        <code class="extcols d-none"><br/>{$query}</code>
                    </div>
};


declare function app:searchftt-simbad-query($identifier, $max){
    let $s := jmmc-simbad:resolve-by-name($identifier) 
    let $ra := $s/ra
    let $dec := $s/dec
    let $samestar-dist_as := 1E-23

    let $max_dist_as := request:get-parameter("max_dist_as", $app:default_max_dist_as)
    let $max_magV := request:get-parameter("max_magV", $app:default_max_magV)
    let $max_magK_UT := request:get-parameter("max_magK_UT", $app:default_max_magK_UT)
    let $max_magK_AT := request:get-parameter("max_magK_AT", $app:default_max_magK_AT)
    let $max_magR := request:get-parameter("max_magR", $app:default_max_magR)  

    
    let $max-mag-filters := <text>( K&lt;{$max_magK_UT} AND V&lt;{$max_magV} ) OR ( K&lt;{$max_magK_AT} AND R&lt;{$max_magR})</text>
    
    let $query := concat("SELECT  DISTINCT main_id, DISTANCE(POINT('ICRS', ra, dec),POINT('ICRS', ", $ra,",",$dec,"))*3600.0 as dist_as, ra, dec, pmra,pmdec, G, K, V, R, otype_txt FROM basic JOIN allfluxes ON oid=oidref JOIN ident USING(oidref) WHERE ( ",$max-mag-filters, " ) AND CONTAINS(POINT('ICRS', ra, dec), CIRCLE('ICRS', ", $ra, ", ", $dec, ",", $samestar-dist_as,")) = 0 AND CONTAINS(POINT('ICRS', ra, dec), CIRCLE('ICRS', ", $ra, ", ", $dec, ",", $max_dist_as,"/3600.0)) = 1 ORDER BY dist_as;")
    return
        $query
};

declare function app:searchftt-query($identifier, $max){
    let $s := jmmc-simbad:resolve-by-name($identifier) 
    let $ra := $s/ra
    let $dec := $s/dec
    
    let $max_dist_as := request:get-parameter("max_dist_as", $app:default_max_dist_as)
    let $max_magV := request:get-parameter("max_magV", $app:default_max_magV)
    let $max_magK_UT := request:get-parameter("max_magK_UT", $app:default_max_magK_UT)
    let $max_magK_AT := request:get-parameter("max_magK_AT", $app:default_max_magK_AT)
    let $max_magR := request:get-parameter("max_magR", $app:default_max_magR) 
    
    let $detail := "pmra, pmdec, (-15.5*pmra/1000.0) as delta_ra2000_as,(-15.5*pmdec/1000.0) as delta_de2000_as,(RA-15.5*pmra/3600000.0) as RA2000,(DEC-15.5*pmdec/3600000.0) AS de2000,"
    
    let $mag_k_name := "mag_ks"
    let $mag_g_name := "mag_g"
    let $mag_bp_name := "mag_bp"
    let $mag_rp_name := "mag_rp"
    
    let $vcalc := <text>( {$mag_g_name} - ( -0.0176 - 0.00686* ({$mag_bp_name} - {$mag_rp_name} ) - 0.1732*( {$mag_bp_name} - {$mag_rp_name})*( {$mag_bp_name} - {$mag_rp_name}) ) )</text>
    let $rcalc := <text>( {$mag_g_name} - ( 0.003226 + 0.3833* ({$mag_bp_name} - {$mag_rp_name} ) - 0.1345*( {$mag_bp_name} - {$mag_rp_name})*( {$mag_bp_name} - {$mag_rp_name}) ) )</text>
    
    let $max-mag-filters := <text>({$mag_k_name}&lt;{$max_magK_UT} AND {$vcalc}&lt;{$max_magV}) OR ({$mag_k_name}&lt;{$max_magK_AT} AND {$rcalc}&lt;{$max_magR})</text>
    
    let $query := concat("SELECT gaia.dr2light.source_id,DISTANCE(POINT('ICRS',(RA-15.5*pmra/3600000.0),(DEC-15.5*pmdec/3600000.0)),POINT('ICRS', ", $ra,",",$dec,"))*3600.0 as dist_as ,ra,dec,", $detail,"mag_g,mag_ks,",$vcalc, " AS computed_mag_v, ",$rcalc, " AS computed_mag_r ", "&#10; FROM gaia.dr2light JOIN gdr2ap.main ON gaia.dr2light.source_id=gdr2ap.main.source_id WHERE (", $max-mag-filters, ") AND CONTAINS(POINT('ICRS', RA, DEC), CIRCLE('ICRS', ", $ra,",",$dec,", ",$max_dist_as,"/3600.0)) = 1 " ) 
    (: ivo_apply_pm(RA,DEC,pmra,pmdec,-15) does not seems to work :)
    return
        $query
};


declare function app:searchftt-esagaia-query($identifier, $max){
    let $s := jmmc-simbad:resolve-by-name($identifier) 
    let $ra := $s/ra
    let $dec := $s/dec
    
    let $max_dist_as := request:get-parameter("max_dist_as", $app:default_max_dist_as)
    let $max_magV := request:get-parameter("max_magV", $app:default_max_magV)
    let $max_magK_UT := request:get-parameter("max_magK_UT", $app:default_max_magK_UT)
    let $max_magK_AT := request:get-parameter("max_magK_AT", $app:default_max_magK_AT) 
    let $max_magR := request:get-parameter("max_magR", $app:default_max_magR) 
    
    let $mag_k_name := "tmass.ks_m"
    let $mag_g_name := "gaia.phot_g_mean_mag"
    let $mag_bp_name := "gaia.phot_bp_mean_mag"
    let $mag_rp_name := "gaia.phot_rp_mean_mag"
    let $vcalc := <text>( {$mag_g_name} - ( -0.0176 - 0.00686* ({$mag_bp_name} - {$mag_rp_name} ) - 0.1732*( {$mag_bp_name} - {$mag_rp_name})*( {$mag_bp_name} - {$mag_rp_name}) ) )</text>
    let $rcalc := <text>( {$mag_g_name} - ( 0.003226 + 0.3833* ({$mag_bp_name} - {$mag_rp_name} ) - 0.1345*( {$mag_bp_name} - {$mag_rp_name})*( {$mag_bp_name} - {$mag_rp_name}) ) )</text>
    
    let $max-mag-filters := <text>({$mag_k_name}&lt;{$max_magK_UT} AND {$vcalc}&lt;{$max_magV}) OR ({$mag_k_name}&lt;{$max_magK_AT} AND {$rcalc}&lt;{$max_magR})</text>
    
    let $query := string-join((
    "SELECT",
    "gaia.source_id, DISTANCE(POINT('ICRS', gaia.ra, gaia.dec),POINT('ICRS', ", $ra,",",$dec,"))*3600.0 as dist_as,",
    "gaia.ra,gaia.dec,gaia.pmra,gaia.pmdec,gaia.phot_g_mean_mag as mag_g , "|| $vcalc ||" as computed_mag_v, "|| $rcalc ||" as computed_mag_r, tmass.h_m as H_mag, tmass.ks_m as K_mag,",
    "tmass_nb.angular_distance as tmass_dist, tmass.designation as J_2MASS",
    "FROM",
    "gaiadr2.gaia_source as gaia JOIN gaiadr2.tmass_best_neighbour as tmass_nb ON gaia.source_id = tmass_nb.source_id JOIN gaiadr1.tmass_original_valid as tmass ON tmass.tmass_oid = tmass_nb.tmass_oid",
    "WHERE ",
    "("|| $max-mag-filters ||") AND ",
    "CONTAINS(POINT('ICRS', gaia.ra, gaia.dec), CIRCLE('ICRS', ", $ra, ", ", $dec, ",", $max_dist_as,"/3600.0)) = 1 ORDER BY dist_as"),"&#10;")
    return
        $query
};

