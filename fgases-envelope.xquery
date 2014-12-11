xquery version "1.0";
(:
 : Module Name: FGases dataflow envelope level check(Main module)
 :
 : Version:     $Id$
 : Created:     10 December 2014
 : Copyright:   European Environment Agency
 :)
(:~
 : Reporting Obligation: http://rod.eionet.europa.eu/obligations/713
 : XML Schema:  : XML Schema: http://dd.eionet.europa.eu/schemas/fgases-2015/FGasesReporting.xsd
 :
 : F-Gases QA Rules implementation
 :
 : @author Enriko Käsper
 :)


declare namespace xmlconv="http://converters.eionet.europa.eu/fgases";
(: namespace for BDR localisations :)
declare namespace i18n = "http://namespaces.zope.org/i18n";
(: Common utility methods :)
import module namespace cutil = "http://converters.eionet.europa.eu/fgases/cutil" at "fgases-common-util-2015.xquery";
(: UI utility methods for build HTML formatted QA result:)
import module namespace uiutil = "http://converters.eionet.europa.eu/fgases/ui" at "fgases-ui-util-2015.xquery";
(:===================================================================:)
(: Variable given as an external parameter by the QA service:)
(:===================================================================:)
(:
declare variable $source_url as xs:string :='http://cdrtest.eionet.europa.eu/de/colt_cs2a/colt_ctda/envumtz_a/xml';
declare variable $source_url as xs:string external;
:)
declare variable $source_url as xs:string external;

declare variable $SCHEMA as xs:string := " : XML Schema: http://dd.eionet.europa.eu/schemas/fgases-2015/FGasesReporting.xsd";
declare variable $REPORT_TYPE as xs:string := "F-Gases";
declare variable $HELPDESK_EMAIL as xs:string := "f-gases.reporting@eea.europa.eu";

(:==================================================================:)
(:==================================================================:)
(:==================================================================:)
(:					QA rules related functions				       :)
(:==================================================================:)
(:==================================================================:)
(:==================================================================:)



declare function xmlconv:getFiles($url as xs:string, $schema as xs:string)   {

    for $pn in fn:doc($url)//file[@schema = $schema and string-length(@link)>0]
        let $fileUrl := cutil:replaceSourceUrl($url, string($pn/@link))
        where doc-available($fileUrl)
        return
            $fileUrl
}
;

declare function xmlconv:validateEnvelope($url as xs:string)
as element(div)
{
    let $files := fn:doc($url)//file[string-length(@link)>0]

    let $filesCountAll := count($files)
    let $filesCountCorrectSchema := count($files[@schema = $SCHEMA])

    let $filesCountMainSchema := count($files[@schema = $SCHEMA])

    let $filesCountXml := count($files[@type="text/xml"])

    let $errorLevel := if ($filesCountCorrectSchema = 1 and $filesCountXml = 1) then "INFO" else "BLOCKER"

    let $description :=
        if ($filesCountCorrectSchema = 0) then
            <span><span i18n:translate="">Your delivery cannot be accepted as you did not complete the online questionnaire as instructed in the BDR user manual.</span>
<br/><br/><span i18n:translate="">Please create a new envelope, fill in the online questionnaire and re-submit.</span></span>
        else if ($filesCountCorrectSchema >= 1 and $filesCountXml > 1) then
            <span><span i18n:translate="">Your delivery cannot be accepted as you have provided more than one xml files (you have completed more than one online questionnaires).</span>
<br/><br/><span i18n:translate="">Please create a new envelope and re-submit using only the correct xml file. Note that if you wish to report for more than one reporting year you have to use separate envelopes.</span>
<br/><span i18n:translate="">For your convenience, you can use the "Copy previous delivery" button in the new envelope to copy existing xml-files from the current (submitted but rejected) envelope.</span></span>
        else if ($filesCountCorrectSchema = 1 and $filesCountXml = 1 and $filesCountAll > 1) then
            <span><span i18n:translate="">You have made a submission using the online questionnaire correctly. Your data report (xml-file stored in this envelope) is accepted.</span>
<br/><span i18n:translate="">Please note that the quality of any additional files included in your delivery will not be evaluated automatically. In case you wish to have an additional evaluation of this data please contact the { $REPORT_TYPE } Reporting support team (<span i18n:name="helpdesk-email-address"><a href="mailto:{ $HELPDESK_EMAIL }">{ $HELPDESK_EMAIL }</a></span>), providing the link to the current submission (copy and paste the url address of the present webpage).</span></span>
        else
            <span i18n:translate="">Your data report has been completed correctly using the online questionnaire.</span>
    return
    <div class="feedbacktext">
        <h2 i18n:translate="">Check contents of delivery</h2>
        {uiutil:buildFBStatusSpan($errorLevel, $description)}
        {
        if ($errorLevel = "BLOCKER") then
            <p><span style="color:red">{ $description }</span></p>
        else
            <p style="color:blue;font-size:1.1em;">{ $description }</p>
        }
    </div>

};
(:===================================================================:)
(: Main function calls the different get function and returns the result:)
(:===================================================================:)

declare function xmlconv:proceed($url as xs:string) {

    let $sourceDocAvailable := doc-available($source_url)
    let $results := if ($sourceDocAvailable) then xmlconv:validateEnvelope($source_url) else ()

    return
        if ($sourceDocAvailable) then
            $results
        else
            uiutil:buildDocNotAvailableError($source_url)
}
;

xmlconv:proceed($source_url)
