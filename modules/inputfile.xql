xquery version "3.1";
import module namespace app="http://exist.jmmc.fr/searchftt/apps/searchftt/templates" at "app.xql";

(:
 Format identifiers as a single string
 - store it as session attribute
 -
:)
declare function local:filter-identifiers($inputfile){
    let $lines := for $line in tokenize($inputfile, "&#10;")
        where not ( ( ("--", "#", "&quot;", "&quot;h:m:s") ! starts-with($line, .) ) = true() )
        where string-length(normalize-space($line)) > 1
        return replace($line, "&#9;", " ") ! replace(., "&quot;","")
    let $lines := distinct-values($lines)
    return string-join($lines, ';')
};

let $inputfile :=request:get-parameter("inputfile",())
return
    if(empty($inputfile)) then () else
    let $store := session:set-attribute('identifiers', local:filter-identifiers($inputfile) )
    let $redirect := response:redirect-to(xs:anyURI("../bulk.html"))
    return <session-set>identifiers set for session {session:get-id()}</session-set>