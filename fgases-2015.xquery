xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: FGases dataflow (Main module)
 :
 : Version:     $Id$
 : Created:     20 November 2014
 : Copyright:   European Environment Agency
 :)
(:~
 : Reporting Obligation: http://rod.eionet.europa.eu/obligations/669
 : XML Schema: http://dd.eionet.europa.eu/schemas/fgases-2015/FGasesReporting.xsd
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

declare variable $xmlconv:BLOCKER as xs:string := "BLOCKER";
declare variable $xmlconv:WARNING as xs:string := "WARNING";
declare variable $xmlconv:INFO as xs:string := "INFO";
declare variable $xmlconv:ERR_TEXT_2016 as xs:string := "You reported on own destruction in section 1B. Please accordingly select to be a destruction company in the activity selection and report subsequently in section 8.";


declare variable $xmlconv:cssStyle as element(style) :=

<style type="text/css">
  <![CDATA[

.red {
  color:red;
}

.red-bold {
  color:red;
  font-weight:bold;
}

.orange {
  color:orange;
}

.blue {
  color:blue;
  font-size:0.8em;
}

.block {
    display:block;
}

ul.items-list li {
  list-style-type:none;
}

ul.errors-list li span.error-red,
ul.errors-list li span.error-orange {
  font-size: 0.8em;
  color: white;
  padding-left:12px;
  padding-right:12px;
  text-align:center;
}

ul.errors-list li span.error-red {
  background-color: red;
}

ul.errors-list li span.error-orange {
  background-color: orange;
}

ul.errors-list li span.error-name {
  font-weight:bold;
}

.datatable {
  width:100%;
  text-align:left;
}

.datatable tr th {
  width:250px;
  font-weight:normal;
  text-align:left;
}

.datatable tr td sup {
  font-size:0.7em;
  color:blue;
}
.error-details {
    margin-left: 37px;
    padding-top: 5px;
}
.error-details ul {
    margin-top: 5px;
    padding-top: 0px;
}
.errors {
    width:100%;
    margin-top: 10px;
}
.errors h4 {
	font-weight: bold;
	padding: 0.2em 0.4em;
	background-color: rgb(240, 244, 245);
	color: #000000;
	border-top: 1px solid rgb(224, 231, 215);
}
      ]]>
</style>

;

declare variable $source_url as xs:string external;

(:
  Change it for testing locally:
declare variable $source_url as xs:string external;
declare variable $source_url as xs:string external;
declare variable $source_url := "http://cdrtest.eionet.europa.eu/de/colt_cs2a/colt_ctda/envt_cyoq/questionnaire_fgases.xml";
:)
(:
 : ======================================================================
 :     QA rules
 : ======================================================================
 :)

declare function xmlconv:rule_2016($doc as element())
as element(div) {

  let $err_text := "You reported on own destruction in section 1B. Please accordingly select to be a destruction company in the activity selection and report subsequently in section 8."

  let $err_flag := sum($doc/F1_S1_4_ProdImpExp/Gas/tr_01B/Amount[number(.)=number(.)]) > 1000 and $doc/GeneralReportData/Activities/D != 'true'

  return uiutil:buildRuleResult("2016", "1B", $err_text, $xmlconv:BLOCKER, $err_flag, (), "")
};


declare function xmlconv:rule_2017($doc as element(), $tran as xs:string)
as element(div) {

  let $err_text := "A negative amount here is implausible, please revise your data."

  let $err_flag :=
    for $gas in $doc/F1_S1_4_ProdImpExp/Gas
    where $gas/*[name()=concat('tr_0', $tran)]/Amount[number(.)=number(.)] < 0
    return
      data($doc/ReportedGases[GasId = $gas/GasCode]/Name)

  return uiutil:buildRuleResult("2017", $tran, $err_text, $xmlconv:BLOCKER, count($err_flag)>0, $err_flag, "Invalid gases are: ")
};


declare function xmlconv:rule_2300($doc as element(), $tran as xs:string)
as element(div) {

  let $err_text := "The calculated specific charge of F-gases exceeds 1000kg/tonne;
    therefore a value or unit must be incorrect. Please revise reported data or units."

  let $err_flag :=
    if ($doc/F7_s11EquImportTable/UISelectedTransactions/*[name()=concat('tr_', $tran)] = 'true')
      then
        if ($doc/F7_s11EquImportTable/*[name()=concat('TR_', $tran, '_Unit')] = 'metrictonnes')
          then
            if ($doc/F7_s11EquImportTable/AmountOfImportedEquipment/*[name()=concat('tr_', $tran)]/Amount > 1000)
              then fn:true()
              else fn:false()
          else fn:false()
      else fn:false()

  return uiutil:buildRuleResult("2030", $tran, $err_text, $xmlconv:BLOCKER, $err_flag, (), "")

};


declare function xmlconv:rule_2301($doc as element(), $tran as xs:string)
as element(div) {

  let $err_text := "The calculated specific charge of F-gases d is not in the expected range
    (0.2 and 1000 kg/piece). Please make sure you correctly reported the amounts of gases in
    units of tonnes, not in kilograms. Please revise your data or provide an explanation to the
    calculated specific charge."

  let $err_flag :=
    if ($doc/F7_s11EquImportTable/UISelectedTransactions/*[name()=concat('tr_', $tran)] = 'true')
      then
        if ($doc/F7_s11EquImportTable/AmountOfImportedEquipment/*[name()=concat('tr_', $tran)][Amount > 0.2][Amount < 1000])
          then fn:false()
          else fn:true()
      else fn:false()

  let $err_status :=
    if ($doc/F7_s11EquImportTable/Comment/*[name()=concat('tr_', $tran)] = '')
      then $xmlconv:BLOCKER
      else $xmlconv:WARNING

  return uiutil:buildRuleResult(
    "2031", $tran, $err_text, $err_status, $err_flag, (), "")
};


declare function xmlconv:validateReport($url as xs:string)
as element(div)
{
    let $doc := fn:doc($url)/FGasesReporting

    let $r2016 := xmlconv:rule_2016($doc)

    let $r2017 :=
        for $tran in ('1E', '3C', '4D', '4E', '4I', '4J')
            return xmlconv:rule_2017($doc, $tran)

    let $r2300 :=
        for $tran in ('11P', '11H04')
            return xmlconv:rule_2300($doc, $tran)

    let $r2301 :=
        for $tran in ('11A01')
            return xmlconv:rule_2301($doc, $tran)

  return
    <div class="errors">
        <h4>Error details</h4>
        {$r2016}
        {$r2017}
        {$r2300}
        {$r2301}
    </div>

};

declare function xmlconv:getMostCriticalErrorClass($ruleResults as element()?)
as xs:string {
        if (count($ruleResults//span[@errorLevel='BLOCKER']) > 0) then
            "BLOCKER"
        else if (count($ruleResults//span[@errorLevel='WARNING']) > 0) then
            "WARNING"
        else
            "INFO"
};
declare function xmlconv:getErrorText($class as xs:string) as xs:string {
    if ($class = "BLOCKER") then
        "The delivery is not acceptable. Please see the QA output."
    else if ($class = "WARNING") then
        "The delivery is acceptable but some of the information has to be checked. Please see the QA output."
    else if ($class = "INFO") then
            "The delivery is acceptable."
        else
            "The delivery status is unknown."
};
declare function xmlconv:buildRuleResult($ruleCode as xs:string, $trCode as xs:string, $errorText as xs:string, $errorLevel as xs:string, $isInvalid as xs:boolean, $invalidRecords)
as element(){

    if ($isInvalid) then
        <tr errorCode="{ $ruleCode} " errorLevel=" {$errorLevel} ">
            <td>{ $trCode }</td>
            <td>
                <div>{ $errorText }</div>
                {
                    if (count($invalidRecords) > 0) then
                        <ul>{
                            for $r in $invalidRecords
                            return
                                <li>{$r}</li>
                        }</ul>
                    else
                        ()
                }
            </td>
        </tr>
    else
        ()
};
(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string)
as element(div){
    let $sourceDocAvailable := doc-available($source_url)

    let $results := if ($sourceDocAvailable) then xmlconv:validateReport($source_url) else ()

    let $class := if ($sourceDocAvailable) then  xmlconv:getMostCriticalErrorClass($results) else ()
    let $errorText :=  if ($sourceDocAvailable) then  xmlconv:getErrorText($class) else ""

    let $resultErrors :=  if ($sourceDocAvailable) then  uiutil:getResultErrors($results) else ()

    (: FIXME :)
    (: let $hasOnlyStatusError := count($resultErrors) = 1 and $resultErrors/@subErrorCodes=$rules:COMPLETNESS_WRONGSTATUS_SUBID:)
    let $hasOnlyStatusError := false()

    return
        if ($sourceDocAvailable) then
            uiutil:buildScriptResult($results, $class, $errorText, $hasOnlyStatusError, $xmlconv:cssStyle)
        else
            uiutil:buildDocNotAvailableError($source_url)
};
xmlconv:proceed( $source_url )

