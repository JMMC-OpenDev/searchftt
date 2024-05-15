xquery version "3.1";


(:~
 : Convert star coordinates between different
 : formats
 :
 : Based on the jmal package https://github.com/JMMC-OpenDev/jmal .
 : @author JMMC Tech Group
 : @see https://www.jmmc.fr

 :)
module namespace astro="http://exist.jmmc.fr/searchftt/astro";

import module namespace test="http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";


(:~
 : Convert a sexagesimal value for a right ascension (hms) to degrees.
 :
 : @param $s a string of three values for hours minutes and seconds,
 :           space- or colon-separated
 : @return the right ascension in degrees
 : @error failed to parse right ascension
 :)
declare
    %test:arg("s", "18 32 49.9577")
    %test:assertEquals(2.7820815708333333e2)
    %test:arg("s", "bad hms")
    %test:assertError("astro:format")
function astro:from-hms($raHms as xs:string) as xs:double {
    (: RA can be given as HH:MM:SS.TT or HH MM SS.TT.
       Replace ':' by ' ', and remove trailing and leading space :)
    let $raHms := normalize-space(replace($raHms,':', ' '))
    let $tokens := tokenize($raHms, " ")
    let $hh := xs:double($tokens[1])
    let $hm := xs:double(head(($tokens[2],0.0)))
    let $hs := xs:double(head(($tokens[3],0.0)))

    (: Get sign sign which has to be propagated to hm and hs (covers -00 case ):)
    let $sign := if(starts-with($raHms, "-")) then -1.0 else 1.0

    (: Convert to degrees
        note : hh already includes the sign :)
    let $ra := ($hh + $sign * ( $hm div 60.0 + $hs div 3600.0 ) ) * 15.0
    return $ra
};

(:~
 : Convert a sexagesimal value for declination (dms) to degrees.
 :
 : @param $s a string of three values for degrees minutes and seconds,
 :           space- or colon-separated
 : @return the declination in degrees
 : @error failed to parse declination
 :)
declare
    %test:arg("s", "57:14:12.3")
    %test:assertEquals(57.23675)
    %test:arg("s", "bad dms")
    %test:assertError("astro:format")
function astro:from-dms($decDms as xs:string) as xs:double {

    (: DEC can be given as DD:MM:SS.TT or DD MM SS.TT.
       Replace ':' by ' ', and remove trailing and leading space :)
    let $decDms := normalize-space(replace($decDms,':', ' '))
    let $tokens := tokenize($decDms, " ")
    let $hh := xs:double($tokens[1])
    let $hm := xs:double(head(($tokens[2],0.0)))
    let $hs := xs:double(head(($tokens[3],0.0)))

    (: Get sign which has to be propagated to hm and hs (covers -00 case ):)
    let $sign := if(starts-with($decDms, "-")) then -1.0 else 1.0

    (: Convert to degrees
        note : hh already includes the sign :)
    let $dec := $hh + $sign * ( $hm div 60.0 + $hs div 3600.0 )
    return $dec
};


declare function astro:toHMS($degrees as xs:double) as xs:string {
  let $hours := floor($degrees)
  let $minutes := floor(($degrees - $hours) * 60)
  let $seconds := (($degrees - $hours) * 3600) mod 60
  return string-join(($hours, $minutes, $seconds),":")
};

declare function astro:toDMS($degrees as xs:double) as xs:string {
  let $degrees-abs := abs($degrees)
  let $degrees-part := floor($degrees-abs)
  let $minutes-part := floor(($degrees-abs - $degrees-part) * 60)
  let $seconds-part := (($degrees-abs - $degrees-part) * 3600) mod 60
  let $sign := if ($degrees >= 0) then "+" else "-"
  return string-join(($sign||$degrees-part, $minutes-part, $seconds-part),":")
};