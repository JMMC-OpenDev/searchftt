xquery version "3.1";
import module namespace app="http://exist.jmmc.fr/searchftt/apps/searchftt/templates" at "app.xql";


<test>
{
    for $param in request:get-parameter-names() order by $param
        return <parameter><name>{$param}</name>{for $v in request:get-parameter($param,()) return <value>{$v}</value>}</parameter>
    ,
    app:bulk-form-test(request:get-parameter("identifiers",()),request:get-parameter("catalogs",()))
}
</test>