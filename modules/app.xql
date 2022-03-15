xquery version "3.1";

(:~ This is the default application library module of the searchftt app.
 :
 : @author JMMC Tech Group
 : @version 1.0.0
 : @see https://www.jmmc.fr
 :)

(: Module for app-specific template functions :)
module namespace app="http://exist.jmmc.fr/searchftt/apps/searchftt/templates";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lib="http://exist-db.org/xquery/html-templating/lib";
import module namespace config="http://exist.jmmc.fr/searchftt/apps/searchftt/config" at "config.xqm";

import module namespace jmmc-tap="http://exist.jmmc.fr/jmmc-resources/tap" at "/db/apps/jmmc-resources/content/jmmc-tap.xql";
import module namespace jmmc-simbad="http://exist.jmmc.fr/jmmc-resources/simbad" at "/db/apps/jmmc-resources/content/jmmc-simbad.xql";
(:import module namespace jmmc-astro="http://exist.jmmc.fr/jmmc-resources/astro" at "/db/apps/jmmc-resources/content/jmmc-astro.xql";:)

declare variable $app:max-magV := 15;
declare variable $app:max-magK := 11;
declare variable $app:max-magR := 12.5;

declare %templates:wrap function app:form($node as node(), $model as map(*), $identifiers as xs:string*) {
    (
    <div>
        <h1>GRAVITY-wide: finding off-axis fringe tracking targets.</h1>
        <p>This newborn tool is in its first version and is subject to various changes in its early development phase.</p>
        <h2>Underlying method:</h2>
      <p>
      This form queries within 30" of the science target : <br/>
        <ol>
            <li>Simbad for sources that are suitable for GRAVITY-wide fringe tracking (i.e. ( Kmag &lt; {$app:max-magK} and Vmag &lt; {$app:max-magV} ) or Rmag&lt;12.5)</li>
            <li>the catalog <a href = "https://ui.adsabs.harvard.edu/abs/2022arXiv220103252F/abstract">Astrophysical Parameters from Gaia DR2, 2MASS &amp; AllWISE</a> through the GAVO TAP service in search for sources that are suitable for GRAVITY-wide fringe tracking (i.e. mag_ks &lt; {$app:max-magK} and computed_mag_v&lt;{$app:max-magV}). The V and R magnitudes are computed from the Gaia G, Grb and Grp magnitudes and allows the user to refine its target selection to take into account VLTI Adaptive Optics specifications (recall P110: UT (MACAO): Vmag&lt;15, AT (NAOMI): Rmag&lt;{$app:max-magR}).</li>
        </ol>
    </p>
    <p>
        <ul>
            <li>Target name resolution relies on <a href="http://simbad.u-strasbg.fr">Simbad</a>.</li>
            <li>Send your target to Aspro2 using <a href="https://www.jmmc.fr/getstar">GetStar</a> links in the result tables then press "Send Votable".</li>
            <li>Please <a href="http://www.jmmc.fr/feedback">fill a report</a> for any question or remark.</li>
        </ul>
    </p>
    <form>
        <div class="form-floating">
            <input class="form-control" type="text" id="identifiers" name="identifiers" value="{$identifiers}" required=""/>
            <label for="identifiers">Find Fringe Tracker Targets for your identifiers (comma separated) </label>
        </div>
    </form>
    
    </div>
    ,
    if (exists($identifiers)) then app:searchftt-list($identifiers) else ()
    
    )
};

declare function app:searchftt-list($identifiers as xs:string) {
    let $ids := $identifiers ! tokenize(., ",") ! tokenize(., ";")
    let $lis :=
        for $id at $pos in $ids 
        let $s := jmmc-simbad:resolve-by-name($id)
        let $ra := $s/ra let $dec := $s/dec
        let $info := if(exists($s/ra))then 
            let $max := 25
                return 
                    <ol>
                        <li>{app:search-simbad($id, $max, $s)}</li>
                        <li>{app:search-gdr2ap($id, $max, $s)}</li>
                    </ol>
                    
            else
                <div>Can't get position from Simbad, please check your identifier.</div>
        let $state := if(exists($info//table)) then "success" else if(exists($s/ra)) then "warning" else "danger"
        let $ff :=()
        return 
            <li class="list-group-item d-flex justify-content-between align-items-start list-group-item-{$state}">
                <div class="ms-2 me-auto">
                  <div class="fw-bold"><a href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($id)}">{$id} &#160;-&#160; {$ra}&#160;{$dec}</a></div>
                  { $info }
                </div>
            </li>
    return
        <ul class="list-group">
            {$lis,
            (<li class="list-group-item d-flex justify-content-between align-items-start">
                <div class="ms-2 me-auto">
                  <div class="form-check form-switch">
                      <label class="form-check-label extcols">Show more information</label>
                      <label class="form-check-label extcols d-none">Show basic information</label>
                      <input class="form-check-input" type="checkbox" onClick='$(".extcols").toggleClass("d-none");'/>
                  </div>
                </div>
            </li>)[$lis//table]
            }
        </ul>
};

declare function app:search-simbad($id, $max, $s) {
	let $query := app:searchftt-simbad-query($id,$max)
            let $votable := try{jmmc-tap:tap-adql-query($jmmc-tap:SIMBAD-SYNC, $query, 25) } catch * {()}
(:            let $votable := jmmc-tap:tap-adql-query($jmmc-tap:SIMBAD-SYNC, $query, 25):)
            let $html-form-url := ""
            let $extcols := ( 1500 ) (: detailed cols (hidden by default) :)
            return 
                if(exists($votable//*:TABLEDATA/*)) then 
                <div class="table-responsive">
                    <table class="table">
                        <thead><tr><th>SIMBAD NAME</th>
                            {for $f at $cpos in $votable//*:FIELD where $cpos != 1
                                let $unit :=if (ends-with($f/@name, "_as")) then "[arcsec]" else if (data($f/@unit)) then "["|| $f/@unit ||"]" else ()
                                return 
                                <th title="{$f/*:DESCRIPTION}">{if($cpos=$extcols) then attribute {"class"} {"d-none extcols"} else ()}{data($f/@name)} &#160; {$unit}</th>
                            }
                            <th><a href="https://www.jmmc.fr/getstar">GetStar</a></th>
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
                                                element {"td"} {attribute {"class"} {if($cpos=$extcols) then "d-none extcols" else ()}, try { let $d := xs:double($td) return format-number($d, "0.######") } catch * { data($td) }},
                                            <td>{$getstar-link}<!--{$getstar-votable//*:TABLEDATA/*:TR/*:TD[121]/text()}--></td>
                                        )
                                }</tr>
                        }
                    </table>
                    <code class="extcols d-none"><br/>{$query}</code>
                </div>
                else
                    <div>
                        Sorry, no fringe traking star found for <b>{$s/name/text()}</b> in <a href="{$html-form-url}">Simbad</a> <code class="extcols d-none"><br/>{$query}</code>.
                    </div>
};

declare function app:search-gdr2ap($id, $max, $s) {
	let $query := app:searchftt-query($id,$max)
            let $votable := try { jmmc-tap:tap-adql-query('https://dc.zah.uni-heidelberg.de/tap/sync',$query, 25) } catch * {()}
            let $html-form-url := "http://dc.g-vo.org/__system__/adql/query/form?__nevow_form__=genForm&amp;query="||encode-for-uri($query)||"&amp;MAXREC="||$max||"&amp;_FORMAT=HTML&amp;submit=Go"
            let $extcols := ( 5 to 10 ) (: detailed cols (hidden by default) :)
            return 
                if(exists($votable//*:TABLEDATA/*)) then 
                <div class="table-responsive">
                    <table class="table">
                        <thead><tr><th>SIMBAD NAME</th>
                            {for $f at $cpos in $votable//*:FIELD where $cpos != 1
                                let $unit :=if (ends-with($f/@name, "_as")) then "[arcsec]" else if (data($f/@unit)) then "["|| $f/@unit ||"]" else ()                                return 
                                <th title="{$f/*:DESCRIPTION}">{if($cpos=$extcols) then attribute {"class"} {"d-none extcols"} else ()}{data($f/@name)} &#160; {$unit}</th>
                            }
                            <th><a href="https://www.jmmc.fr/getstar">GetStar</a></th>
                        </tr></thead>
                        {
                            for $tr in $votable//*:TABLEDATA/* return 
                                <tr>{
                                    let $gdr2_id := "GAIA DR2 "||$tr/*[1] (: id alway must be requested as first param in the query :)
                                    let $simbad := jmmc-simbad:resolve-by-name($gdr2_id)
                                    let $target_link := if ($simbad/ra) then <a href="http://simbad.u-strasbg.fr/simbad/sim-id?Ident={encode-for-uri($gdr2_id)}">{replace($simbad/name," ","&#160;")}</a> else $gdr2_id||" unknown by Simbad"
                                    let $getstar-url := "https://apps.jmmc.fr/~sclws/getstar/sclwsGetStarProxy.php?star="||encode-for-uri($simbad/name)
                                    let $getstar-link := <a href="{$getstar-url}" target="{$simbad/name}"><i class="bi bi-box-arrow-up-right"></i></a> 
                                    return 
                                        (
                                            <td>{$target_link}</td>,
                                            for $td at $cpos in $tr/* where $cpos != 1 return 
                                                element {"td"} {attribute {"class"} {if($cpos=$extcols) then "d-none extcols" else ()},try { format-number(number($td), "0.######") } catch * { data($td) }},
                                            <td>{$getstar-link}<!--{$getstar-votable//*:TABLEDATA/*:TR/*:TD[121]/text()}--></td>

                                        )
                                }</tr>
                        }
                    </table>
                    <code class="extcols d-none"><br/>{$query}</code> 
                    <a target="_new" href="{$html-form-url}">View original votable @ GAVO</a>&#160;({serialize($votable//*:COOSYS)})
                </div>
                else
                    <div>
                        <!-- code>{$query}</code><br/ -->
                        Sorry, no fringe traking star found for <b>{$s/name/text()}</b> in the <a href="{$html-form-url}">GAVO</a>'s <a href="https://ui.adsabs.harvard.edu/abs/2022arXiv220103252F/abstract"> gdr2ap catalogue</a>.
                    </div>
};

declare function app:searchftt-query($identifier, $max){
    let $s := jmmc-simbad:resolve-by-name($identifier) 
    let $ra := $s/ra
    let $dec := $s/dec
    let $max-dist_as := 30
    let $min-dist-ut_as := 2 (: defautl for UT  TODO: make it dynamic for AT : 4 :)
    let $min-dist-at_as := 4 (: defautl for UT  TODO: make it dynamic for AT : 4 :)
    
    let $detail := "pmra, pmdec, (-15.5*pmra/1000.0) as delta_ra2000_as,(-15.5*pmdec/1000.0) as delta_de2000_as,(RA-15.5*pmra/3600000.0) as RA2000,(DEC-15.5*pmdec/3600000.0) AS de2000,"
    let $vcalc := "( mag_g - ( -0.0176 - 0.00686* (mag_bp - mag_rp ) - 0.1732*( mag_bp - mag_rp)*( mag_bp - mag_rp) ) )"
    let $rcalc := "( mag_g - ( 0.003226 + 0.3833* (mag_bp - mag_rp ) - 0.1345*( mag_bp - mag_rp)*( mag_bp - mag_rp) ) )"
    let $min-sep-ut := concat(" CONTAINS( POINT('ICRS', RA, DEC), CIRCLE('ICRS', ",$ra,',',$dec, ", ", $min-dist-ut_as,"/3600.0 ) ) as within_2as" )
    let $min-sep-at := concat(" CONTAINS( POINT('ICRS', RA, DEC), CIRCLE('ICRS', ",$ra,',',$dec, ", ", $min-dist-at_as,"/3600.0 ) ) as within_4as" )
    
    let $query := concat("SELECT gaia.dr2light.source_id,DISTANCE(POINT('ICRS',(RA-15.5*pmra/3600000.0),(DEC-15.5*pmdec/3600000.0)),POINT('ICRS', ", $ra,",",$dec,"))*3600.0 as dist_as ,ra,dec,", $detail,"mag_g,mag_ks,",$vcalc, " AS computed_mag_v, ",$rcalc, " AS computed_mag_r, ", $min-sep-ut, ", ", $min-sep-at , "&#10; FROM gaia.dr2light JOIN gdr2ap.main ON gaia.dr2light.source_id=gdr2ap.main.source_id WHERE ( (mag_ks<",$app:max-magK," AND ", $vcalc, "<", $app:max-magV, ") OR ", $rcalc ,"< ", $app:max-magR,") AND CONTAINS(POINT('ICRS', RA, DEC), CIRCLE('ICRS', ", $ra,",",$dec,", ",$max-dist_as,"/3600.0)) = 1 " )
    (: ivo_apply_pm(RA,DEC,pmra,pmdec,-15) does not seems to work :)
    return
        $query
};


declare function app:searchftt-simbad-query($identifier, $max){
    let $s := jmmc-simbad:resolve-by-name($identifier) 
    let $ra := $s/ra
    let $dec := $s/dec
    let $samestar-dist_as := 1E-23
    let $max-dist_as := 30
    let $min-dist-ut_as := 2 (: defautl for UT  TODO: make it dynamic for AT : 4 :)
    let $min-dist-at_as := 4 (: defautl for UT  TODO: make it dynamic for AT : 4 :)
    let $max-mags := concat(" ( K<",$app:max-magK ," AND V<",$app:max-magV," ) OR R<12.5")
    
    
    
    let $query := concat("SELECT  DISTINCT main_id, DISTANCE(POINT('ICRS', ra, dec),POINT('ICRS', ", $ra,",",$dec,"))*3600.0 as dist_as, ra, dec, pmra,pmdec, G, K, V, R, otype_txt FROM basic JOIN allfluxes ON oid=oidref JOIN ident USING(oidref) WHERE ( ",$max-mags, " ) AND CONTAINS(POINT('ICRS', ra, dec), CIRCLE('ICRS', ", $ra, ", ", $dec, ",", $samestar-dist_as,")) = 0 AND CONTAINS(POINT('ICRS', ra, dec), CIRCLE('ICRS', ", $ra, ", ", $dec, ",", $max-dist_as,"/3600.0)) = 1 ORDER BY dist_as;")
    return
        $query
};







