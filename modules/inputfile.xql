xquery version "3.1";
import module namespace app="http://exist.jmmc.fr/searchftt/apps/searchftt/templates" at "app.xql";

(:
 Format identifiers as a single string
 - store it as session attribute
 -
:)
let $inputfile :=request:get-parameter("inputfile",())
return
    if(empty($inputfile)) then () else
    let $store := session:set-attribute('identifiers', string-join(tokenize($inputfile, "&#10;"), ';') )
    let $redirect := response:redirect-to(xs:anyURI("../bulk.html"))
    return <session-set>identifiers set for session {session:get-id()}</session-set>