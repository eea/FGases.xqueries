xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: FGASES - UI methods. (Library module)
 :
 : Version:     $Id$
 : Created:     15 October 2012
 : Copyright:   European Environment Agency
 :)
(:~
 : UI utility methods for build HTML formatted QA result.
 : Reporting Obligation: http://rod.eionet.europa.eu/obligations/669
 :
 : @author Kaido Laine
 :)
module namespace uiutil = "http://converters.eionet.europa.eu/fgases/ui";
(: namespace for BDR localisations :)
declare namespace i18n = "http://namespaces.zope.org/i18n";

(: Common utility methods :)
import module namespace cutil = "http://converters.eionet.europa.eu/fgases/cutil" at "fgases-common-util-2015.xquery";
(:~ Constant for error level messages. :)
declare variable $uiutil:ERROR_LEVEL as xs:string :=  "ERROR";
(:~ Constant for warning level messages. :)
declare variable $uiutil:WARNING_LEVEL as xs:string :=  "WARNING";
(:~ Error flag token placed in invalid rule results. :)
declare variable $uiutil:ERROR_FLAG as xs:string :=  "ERRORFLAG";
(:~ Warning flag token placed in invalid rule results. :)
declare variable $uiutil:WARNING_FLAG as xs:string :=  "WARNINGFLAG";
(:~ Message displayed for missig values. :)
declare variable $uiutil:MISSING_VALUE_LABEL as xs:string :=  "-empty-";
(:~ Maximum length of string value displayed in the result table :)
declare variable $uiutil:MAX_VALUE_LENGTH as xs:integer :=  100;
declare variable $uiutil:TABLE_STYLE as xs:string := "width:100%; text-align:left;";
declare variable $uiutil:INNER_TABLE_STYLE as xs:string := $uiutil:TABLE_STYLE ;
declare variable $uiutil:TH_STYLE as xs:string := "width:250px;font-weight:normal;text-align:left;";
declare variable $uiutil:TH_HEADING_STYLE as xs:string := "width:150px;font-weight:bold;text-align:left;font-size:1.2em;";
declare variable $uiutil:TH_SUB_HEADING_STYLE as xs:string := "width:150px;font-weight:bold;text-align:left;";

declare variable $uiutil:TD_DESCR_STYLE as xs:string := "background-color:#d0dec3;";
declare variable $uiutil:TD_SUM_STYLE as xs:string := "background-color:grey; font-weight:bold";

(: color of explanatory row below the table :)
declare variable $uiutil:SUP_EXISTS_COLOR as xs:string := "blue";
declare variable $uiutil:SUP_NOTEXISTS_COLOR as xs:string := "grey";

declare variable $uiutil:CHECKS_SUCCEEDED_PRG as element(p) := <p><span style="background-color: green; font-size: 0.8em; color: white; padding-left:7px;padding-right:7px;text-align:center">OK</span>&#32;<span i18n:translate="">Your reported data has successfully passed the quality check.</span></p>;

declare variable $uiutil:CHECKS_FAILED_PRG as element(p) :=
    <p><span class="red block" i18n:translate="">Your delivery did not pass some important checks. In the following sections you will find more information on these errors.</span><span class="red-bold block" i18n:translate="">It is necessary that you correct the blocking errors found by changing your questionnaire before finalizing the delivery!</span></p>;

declare variable  $uiutil:CHECKS_WARNING_PRG as element(p) :=
<p><span class="orange-bold" i18n:translate="">The quality check found some issues that may need to be followed-up with your company at a later stage. You don’t have to change your data at present.</span></p>;

declare variable  $uiutil:ONLY_STATUS_ERROR_PRG as element(p) :=
<p><span style="color:blue font-weight:bold" i18n:translate="">The report is not yet certified</span></p>;


(:
 : ======================================================================
 :              UI HELPER methods for building QA results HTML
 : ======================================================================
 :)
 declare function uiutil:buildScriptResult($ruleResults as element(div)*, $highestErrorClass as xs:string, $errText as xs:string,
     $onlyStatusError as xs:boolean, $css as element(style))
 as element(div)
 {
    let $resultErrors := uiutil:getResultErrors($ruleResults)
    let $reportCount := count($ruleResults/@key)
    let $errorCount := count($resultErrors)
    let $hasErrors := $errorCount > 0


    return
    <div class="feedbacktext" xmlns:i18n="http://namespaces.zope.org/i18n">
        {$css}
        {uiutil:buildFBStatusSpan($highestErrorClass, $errText)}
        {uiutil:buildScriptHeader()}
        {
        if ($highestErrorClass = 'BLOCKER') then
             if ($onlyStatusError) then
                 $uiutil:ONLY_STATUS_ERROR_PRG
             else
                 $uiutil:CHECKS_FAILED_PRG
        else
            $uiutil:CHECKS_SUCCEEDED_PRG
            }

         <div id="feedBackDiv" style="display:{if ($hasErrors and not($onlyStatusError)) then 'block' else 'none'}">

        {uiutil:buildTableOfContents($resultErrors)}
     {
        if ( count($resultErrors) < 0 ) then
            uiutil:buildValidMessage("The validation is passed successfully.")
        else
            <div>{
                $ruleResults
            }</div>

    }
             </div>
    </div>

 };
declare function uiutil:addTranslateAttr($translate as xs:boolean)
as attribute(i18n:translate)?
{
    if ($translate) then (attribute {'i18n:translate'} {''}) else ()
};


declare function uiutil:buildResultElement($value as xs:string, $errorDefs as element(rule)*, $subCodes as xs:string*, $tableName as xs:string)
as element(div)
{
    uiutil:buildResultElement($value, $errorDefs, $subCodes, $tableName, false())
};
declare function uiutil:buildResultElement($value as xs:string, $errorDefs as element(rule)*, $subCodes as xs:string*, $tableName as xs:string, $translate as xs:boolean)
as element(div)
{
    let $isValid := count($errorDefs) = 0

    let $valueForDisplay := if (string-length($value) > $uiutil:MAX_VALUE_LENGTH) then concat(fn:substring($value, 1, $uiutil:MAX_VALUE_LENGTH), " ...") else $value
    let $valueForDisplay := if (cutil:isEmpty($value) and not(empty(index-of($errorDefs//show_missing, "true")))) then $uiutil:MISSING_VALUE_LABEL else $valueForDisplay

    return
        if ($isValid) then
            <div>{uiutil:addTranslateAttr($translate)}&#32;{ $valueForDisplay }</div>
        else
            uiutil:getErrorElement($valueForDisplay, $errorDefs, $subCodes, $tableName, $translate)
};


(:
: Builds the index to the row definition indicating which sub rule violation occurs
: @param $codes - sub rule codes
: @param $table - table where the rule is shown
:)

declare function uiutil:buildAdditionalInfoSup($errDef as element(rule), $subRuleCodes as xs:string*, $table as xs:string)
{

    let $supCodes :=
        for $code in $subRuleCodes
            let $shortText := uiutil:getSubRuleShorttext($errDef,$code)
            let $supId := concat(" ",data($errDef//subrule[@id=$code]/ruletable[@id=$table]/@supId))
            return
                <span>{$shortText}<sup>{$supId}</sup></span>


     return $supCodes
};

declare function uiutil:getErrorElement($errValue, $errorDefs as element(rule)*, $subCodes as xs:string*, $tableName as xs:string, $translate as xs:boolean)
as element(div)
{
    let $errMessages := string-join($errorDefs//message, "; ")
    let $errColor := if (not(empty(index-of($errorDefs//error_level, "0")))) then
                fn:concat("color:", uiutil:getErrorColor($uiutil:ERROR_LEVEL))
            else
                fn:concat("color:", uiutil:getErrorColor($uiutil:WARNING_LEVEL))
    let $displayErrorMessages :=
        for $errDef in $errorDefs
        let $additionalMess := if (string-length($errDef/additional_message) > 0) then $errDef/additional_message else ""
        return
            <span style="font-weight:normal;padding:5px;font-size:0.8em;color:blue" errorCode="{ data($errDef/@code) }" subErrorCodes="{string-join($subCodes, '|')}"
                errorFlag="{ uiutil:getErrorFlagByLevel($errDef/error_level) }">{data($errDef/message) }{uiutil:buildAdditionalInfoSup($errDef, $subCodes, $tableName)} { $additionalMess };</span>
    return
        <div title="{ $errMessages }">
            <span style="{ $errColor }" name="errValue">{uiutil:addTranslateAttr($translate)}&#32;{ $errValue }</span>
        { $displayErrorMessages }</div>
};


(:
: $displayElemName - child element that contains label to display
:)
declare function uiutil:buildHeaderColumns($elements as element()*, $displayElemName as xs:string)
as element(th)* {
    for $elem in $elements
        return
        <th style = "{$uiutil:TH_HEADING_STYLE}">{data($elem/*[name()=$displayElemName])}</th>

};


declare function uiutil:buildHeaderColumns($elementNode as node(), $elemName as xs:string, $displayElemName as xs:string)
as element(th)* {
    for $elem in $elementNode/*[name()=$elemName]
        return
        <th align="left">&#32;{data($elem/*[name()=$displayElemName])}</th>

};


declare function uiutil:buildTD($value)
as element(td) {
    <td>&#32;{data($value)}</td>
};

declare function uiutil:buildSumTD($value)
as element(td) {
    <td align="right" style="{$uiutil:TD_SUM_STYLE}">&#32;{$value}</td>
};


declare function uiutil:buildDocNotAvailableError($url as xs:string)
as element(div)
{
    <div class="feedbacktext" xmlns:i18n="http://namespaces.zope.org/i18n" i18n:translate="">
        Could not execute the script because the source XML is not available: <span i18n:name="xml-url">{ cutil:getCleanUrl($url) }</span>
    </div>

};

declare function uiutil:buildReportTitleWithBorder($title as xs:string)
as element(h3)
{
    <h3 style="border-bottom: 1px solid #999999;" i18n:translate="">{ $title }</h3>
};


declare function uiutil:buildValidMessage($message as xs:string)
as element(div)
{
    <div style="color:blue;font-size:1.1em;" i18n:translate="">&#32;{ $message }</div>
};

 (:~
  :
  :)
declare function uiutil:buildScriptHeader()
as element(h2)
{
        <h2 i18n:translate="">Validation report for F-Gases Compliance Checks</h2>
};

declare function uiutil:buildTableHeader($headerText as xs:string)
as element(h3)
{
        <h3 i18n:translate="">{$headerText}</h3>
};

(:~
 : Function builds HTML fragemnt for displaying successful rule result header.
 : @param $rule Rule element defined in rules XML.
 : @return HTML fragment.
 :)
declare function uiutil:buildSuccessHeader($rule as element(rule))
as element(div)
{
    <div result="{ uiutil:getResultCode($rule/@code , "ok") }">{
        uiutil:buildTitle($rule)}{
        uiutil:buildDescr($rule)
        }<div style="color:green" i18n:translate="">OK - the test was passed successfully.</div>
    </div>
};
(:~
 : Function builds HTML fragemnt for displaying successful sub rule result header.
 : @param $rule Rule element defined in rules XML.
 : @return HTML fragment.
 :)
declare function uiutil:buildSuccessSubHeader($rule as element(rule))
as element(div)
{
    <div>
        <h3>{
        concat($rule/@code, " ", $rule/title)
        }</h3>
        <p>&#32;{ fn:data($rule/message) }</p>
        <div style="color:green" i18n:translate="">OK - the test was passed successfully.</div>
    </div>
};
(:~
 : Function builds HTML fragemnt for displaying failed sub rule result header.
 : @param $rule Rule element defined in rules XML.
 : @return HTML fragment.
 :)
declare function uiutil:buildFailedSubHeader($rule as element(rule))
as element(div)
{
    <div>
        <h3>{
        concat($rule/@code, " ", $rule/title)
        }</h3>
        <p>&#32;{ fn:data($rule/message) }</p>{
        uiutil:getFailedMessage("", "")
    }</div>
};
(:~
 : Function builds HTML fragemnt for displaying failed rule result header.
 : @param $rule Rule element defined in rules XML.
 : @param $errMessage Error message displayed in the header.
 : @return HTML fragment
 :)
declare function uiutil:buildFailedHeader($rule as element(rule), $errMessage as xs:string)
as element(div)
{
    <div result="{ uiutil:getResultCode($rule/@code , "error") }">{
        uiutil:buildTitle($rule) }{
        uiutil:buildDescr($rule) }{
        uiutil:getFailedMessage(fn:string($rule/message),$errMessage)
    }</div>
};
(:~
 : Function builds HTML fragemnt for displaying rule results header with warnings.
 : @param $rule Rule element defined in rules XML.
 : @param $warnMessage Warning message displayed in the header.
 : @return HTML fragment
 :)
declare function uiutil:buildWarningHeader($rule as element(rule), $warnMessage as xs:string)
as element(div)
{
    <div result="{ uiutil:getResultCode($rule/@code , "warning") }">{
        uiutil:buildTitle($rule) }{
        uiutil:buildDescr($rule)
        }<div style="color:orange">WARNING - { $warnMessage }</div>
    </div>
};
(:~
 : Function builds HTML fragemnt for displaying rule results header with info.
 : @param $rule Rule element defined in rules XML.
 : @param $infoMessage Info message displayed in the header.
 : @param $textColor Text color for info message.
 : @return HTML fragment
 :)
declare function uiutil:buildInfoHeader($rule as element(rule), $infoMessage as xs:string, $textColor as xs:string)
as element(div)
{
    <div result="{ uiutil:getResultCode($rule/@code , "skipped") }">{
        uiutil:buildTitle($rule) }{
        uiutil:buildDescr($rule)
        }<div style="color:{$textColor}">{ $infoMessage }</div>
    </div>
};

declare function uiutil:isInvalidElement($elem as element(div))
as xs:boolean
{
    count($elem/span/@errorCode) > 0
};
(:~
 : Build error TD, if the checked element value is invalid. The returned td element is displayed in the tabel of rule results.
 : This is the entry function for building result table cells. If the checked element value is valid, then just return the value between td tags.
 : Otherwise the invalid value is wrapped with error message.
 : @param $checkedRow Element displayed in the table cell.
 : @param $elementName Element name.
 : @param $rule Rule element defined in rules XML.
 : @param $showMissing True if missing values showed be displayed.
 : @param $errLevel error level (0 - ERROR, 1 - WARNING)
 : @param $isInvalid True, if the checked element in invalid.
 : @param $valueDelimiter Separator character for delimiting multivalue element values.
 : @return HTML fragment.
 :)
declare function uiutil:buildResultTD($checkedRow as element(), $elementName as xs:string, $errMess as xs:string,
    $showMissing as xs:boolean, $errLevel as xs:string, $isInvalid as xs:boolean*, $valueDelimiter as xs:string)
as element(div)
{
    let $isMultivalueElem := $valueDelimiter != ""
    let $value :=  if ($isMultivalueElem) then
                        string-join($checkedRow//child::*[name() = $elementName], $valueDelimiter)
                   else
                        string($checkedRow//child::*[name() = $elementName])
    let $isValid := empty(index-of($isInvalid, fn:true()))
    let $valueForDisplay := if (not($isValid)) then uiutil:getElementValueForDisplay($value, $showMissing, $isInvalid, $errLevel, $valueDelimiter) else ""
    let $valueForDisplay := if (string-length($valueForDisplay) > $uiutil:MAX_VALUE_LENGTH) then concat(fn:substring($valueForDisplay, 1, $uiutil:MAX_VALUE_LENGTH), " ...") else $valueForDisplay
    let $value := if (string-length($value) > $uiutil:MAX_VALUE_LENGTH) then concat(fn:substring($value, 1, $uiutil:MAX_VALUE_LENGTH), " ...") else $value
    return
        if ($isValid) then
            <div element="{ $elementName }">{ $value }</div>
        else
            uiutil:getErrorTD($valueForDisplay, $errMess, $showMissing, $elementName, $errLevel, $isMultivalueElem)
}
;
declare function uiutil:getErrorTD($errValue as element(span)*,  $errMessage as xs:string,
    $showMissing as xs:boolean, $elementName as xs:string, $errLevel as xs:string, $isMultiValueElem as xs:boolean)
as element(div)
{
    let $errColor := if ($isMultiValueElem) then "" else fn:concat("color:", uiutil:getErrorColor($errLevel))
    return
        <div title="{ $errMessage }" element="{ $elementName }" style="{ $errColor }">{
            $errValue
        }<span style="display:none">{ uiutil:getErrorFlagByLevel($errLevel) }</span></div>
};

declare function uiutil:getElementValue($row as element(), $element as xs:string, $delimiter as xs:string)
as xs:string
{
    fn:string-join(uiutil:getElementValues($row/*[name()=$element]), $delimiter)
}
;
declare function uiutil:getElementValueSorted($row as element(), $element as xs:string, $delimiter as xs:string)
as xs:string
{
    string-join(cutil:sort(uiutil:getElementValues($row/*[name()=$element])), $delimiter)
}
;
declare function uiutil:getElementValues($elements as element())
as xs:string*
{
    for $elem in $elements
    where not(cutil:isEmpty($elem))
    return
            normalize-space(string($elem))
}
;
(:~
 : Build the HTML span element for displaying XML element value. The value can be multivalue element
 : and some of the values can be valid and the others could be invalid. Invalid values should be colored red.
 : @param $errValue Invalid value from XML.
 : @param $showMissing True if missing values showed be displayed.
 : @param $isInvalid List of boolean values. True, if the checked element in invalid.
 : @param $errLevel error level (0 - ERROR, 1 - WARNING)
 : @param $valueDelimiter Separator character for delimiting multivalue element values.
 : @return HTML span element.
 :)
declare function uiutil:getElementValueForDisplay($errValue as xs:string, $showMissing as xs:boolean, $isInvalid as xs:boolean*,
    $errLevel as xs:string, $valueDelimiter as xs:string)
as element(span)*
{
    let $isMultivalueElem := $valueDelimiter != ""
    let $errValue :=
        if ($showMissing = fn:true() and ((not($isMultivalueElem) and cutil:isEmpty($errValue))
            or ($isMultivalueElem and cutil:isEmpty(fn:replace($errValue, $valueDelimiter, ""))))) then
            $uiutil:MISSING_VALUE_LABEL
        else
            $errValue

    let $multiValues := if ($isMultivalueElem) then fn:tokenize($errValue, $valueDelimiter) else ($errValue)

    for $value at $pos in $multiValues
    let $isValid :=
        if (count($isInvalid)>=$pos) then
            not($isInvalid[$pos ])
        else if (count($isInvalid)=1) then
            not($isInvalid[1])
        else
            fn:true()
    let $color := if($isValid) then "" else fn:concat("color:", uiutil:getErrorColor($errLevel))
    let $showDelimiter := if ($isMultivalueElem and $pos < count($multiValues)) then fn:true() else fn:false()
    return
            (<span style="{ $color }">{ normalize-space($value) }</span>,
            if ($showDelimiter) then
                <span>{ $valueDelimiter }</span>
            else
                ()
            )
}
;
(:~
 : Return the color of error message.
 : @param $errLevel error level (BLOCKER,  WARNING)
 : @rteturn color name
 :)
declare function uiutil:getErrorColor($errLevel as xs:string)
as xs:string
{
    if ($errLevel = $uiutil:WARNING_LEVEL) then
        "orange"
    else
        "red"
};
(:~
 : Return the flag name of error message.
 : @param $errLevel error level (BLOCKER, WARNING)
 : @rteturn flag name
 :)
declare function uiutil:getErrorFlagByLevel($errLevel as xs:string)
as xs:string
{
    if($errLevel = $uiutil:WARNING_LEVEL) then
        $uiutil:WARNING_FLAG
    else
        $uiutil:ERROR_FLAG
};

(:~
 : Build HTML title element
 : @param $rule Rule element defined in rules XML.
 : @return HTML fragment
 :)
declare function uiutil:buildTitle($rule as element(rule))
as element(h2)
{
    <h2><a name="{ fn:string($rule/@code) }">{ fn:string($rule/@code) }.</a>&#32;{ fn:string($rule/title) }</h2>
};
(:~
 : Build HTML descritoption element
 : @param $rule Rule element defined in rules XML.
 : @return HTML fragment
 :)
declare function uiutil:buildDescr($rule as element(rule))
as element(p)
{
    <p>&#32;{ fn:string($rule/descr) }</p>
};
(:~
 : Get red colored error message displayed for invalid value. Concats 2 messages if both provided.
 : @param $errMessage Error message.
 : @param $errMessage2 Optional error message. To be concatenated to the first message.
 : @return HTML fragment
 :)
declare function uiutil:getFailedMessage($errMessage as xs:string, $errMessage2 as xs:string)
as element(div)
{
    let $mess := "ERROR - the test was not passed."
    let $fullMessage :=
        if (cutil:isEmpty($errMessage)) then
            concat($mess, " ", $errMessage2)
        else
            concat($mess, " ", $errMessage, " ", $errMessage2)
    return
        <div style="color:red">{ $fullMessage }</div>
};
(:~
 : Get rule message description from the XML rule element.
 : @param $rule Rule element defined in rules XML.
 : @return String message.
 :)
declare function uiutil:getRuleMessage($rule as element(rule))
as xs:string
{
    fn:string($rule/message)
};
(:~
 : Builds the HTML table header row with all the required element names.
 : @param $ruleElementNames List of element names.
 : @return HTML tr element.
 :)
declare function uiutil:buildTableHeaderRow($ruleElementNames as xs:string*)
as element(tr)
{
    <tr align="center">
        <th>Row</th>{
            for $n in $ruleElementNames
                return
                    <th>&#32;{$n}</th>
    }</tr>
}
;
(:~
 : Build HTML title and table with invalid rows for sub-rule.
 : @param $ruleDef Rule code in rules XML.
 : @param $result HTML table tr elements with invalid values.
 : @param $ruleElements List of XML elements used in this rule
 : @return HTML div element.
 :)
declare function uiutil:buildSubRuleFailedResult($ruleDef as element(rule), $result as element(tr)*, $ruleElements as xs:string*)
as element(div){
    <div>{
        uiutil:buildFailedSubHeader($ruleDef)
        }<table border="1" class="datatable" error="{ uiutil:getRuleMessage($ruleDef) }">{
            uiutil:buildTableHeaderRow($ruleElements)
            }{$result
        }</table>
    </div>
};


declare function uiutil:buildTableOfContents($resultErrors as element(span)*)
as element(ul)
{
    let $rules :=
        <rules>
            <rule code="BLOCKER">
                <title>Blocking errors:</title>
                <descr>The quality check found important inconsistencies and/or errors in the reported data which need to be fixed.</descr>
                <rulefine>No blocking errors have been found.</rulefine>
                <error_level>0</error_level>
            </rule>
            <rule code="WARNING">
                <title>Potential errors:</title>
                <descr>The quality check found some issues that may need to be followed-up with your company at a later stage. You don't have to change your data at present.</descr>
                <rulefine>No potential errors have been found.</rulefine>
                <error_level>1</error_level>
            </rule>
        </rules>

    return
        <ul>{
        for $rule at $pos in $rules//rule
        let $countErrors := count($resultErrors[@errorLevel = data($rule/@code)])
        return
            <li style="list-style-type:none">{ uiutil:buildErrorBullet($countErrors, $rule/title, $rule/@code) }&#32;&#32;<span style="font-weight:bold">{ $pos }.&#32;<span i18n:translate="">{ data($rule/title) }</span></span>&#32;<span i18n:translate="">{ if ($countErrors = 0) then data($rule/rulefine) else data($rule/descr) }</span>&#32;
            </li>
        }</ul>
};


declare function uiutil:buildAdditionalRuleDescrList($rule as element(rule))
{
   let $descs :=
   for $desc in $rule/additional_descr
    return
        <span style="font-size:small;font-style:italic;display:block">&#32;{data($desc)}</span>

   return
        $descs

};

declare function uiutil:buildErrorBullet($countErrors as xs:integer, $ruleTitle as xs:string, $errLevel as xs:string)
as element(span)
{
    let $bulletTitle := if ($countErrors = 0) then
                            concat("No errors within this type of rule - ", $ruleTitle)
                        else if ($countErrors = 1) then
                            concat("1 error within this type of rule - ", $ruleTitle)
                        else
                            concat($countErrors, " errors within this type of rule - ", $ruleTitle)
    let $padding := if ($countErrors < 10) then "12" else if ($countErrors < 100) then "9"  else if ($countErrors < 1000) then "6" else "3"
    return
        if ($countErrors = 0) then
            <span style="background-color: green; font-size: 0.8em; color: white; padding-left:3px;padding-right:9px;text-align:center" title="{ $bulletTitle }">OK</span>
        else
             <span style="background-color: { uiutil:getErrorColor($errLevel) }; font-size: 0.8em; color: white; padding-left:{ $padding }px;padding-right:{ $padding  }px;text-align:center;margin-right:9px" title="{ $bulletTitle }">{ $countErrors }</span>
};
(:~
 : Create rule result message displayed in the list of rules at the end of each rule.
 : @param $errorCode Rule code.
 : @param $results Rule results codes ("1-ok")
 : return HTML containing rule result message
 :)
declare function uiutil:getRuleResultBox($errorCode as xs:string, $results as xs:string*)
as element(span)*{
    for $result in $results
    let $resultCode := fn:substring-after($result, "-")
    where substring-before($result, "-") = $errorCode
    return
        if($resultCode = "ok") then
            <span style="background-color:green;font-size:0.8em;color:white;">OK</span>
        else if($resultCode = "error") then
            <span style="background-color:red;font-size:0.8em;color:white;">ERROR</span>
        else if($resultCode = "warning") then
            <span style="background-color:orange;font-size:0.8em;color:white;">WARNING</span>
        else if($resultCode = "skipped") then
            <span style="background-color:brown;font-size:0.8em;color:white;">SKIPPED</span>
        else
            <span>&#32;</span>

};
(:~
 : Build rule results code containg rule code and result message eg.: "1-ok" or "2-error"
 : @param $errorCode Rule code.
 : @param $result Result code: error, ok, warning
 : @return Rule result code.
 :)
declare function uiutil:getResultCode($errorCode as xs:string, $result as xs:string)
as xs:string
{
   fn:concat($errorCode, "-", $result)
};
(:~
 : Return rule results from span result attribute.
 : @param $results List of rule results as HTML fragments starting with span element.
 : @return List of rule results.
 :)
declare function uiutil:getResultErrors($results as element(div)*)
as element(span)*
{
    $results//span[string-length(@errorCode) > 0]
};

(:~
 : Build HTML table for logical rules errros.
 : @param $ruleDefs List of rule elements
 : @return HTML table element.
 :)
declare function uiutil:buildRulesTable($ruleDefs as element(rule)*)
as element(table)
{
    <table class="datatable" border="1">
        <tr>
            <th>Code</th>
            <th style="width:300px">Rule violated</th>
            {
            if(count($ruleDefs//*[name()="message2"]) > 0) then
                <th>Description</th>
            else
                <th style="display:none">&#32;</th>
            }
        </tr>{
            for $ruleDef in $ruleDefs
            let $value :=  fn:substring-after($ruleDef/@code, ".")
            return
                <tr>
                    <td>&#32;{ fn:data($value) }</td>
                    <td>&#32;{ fn:data($ruleDef/message) }</td>
                    {
                    if(count($ruleDefs//*[name()="message2"]) > 0) then
                        <td>&#32;{ fn:data($ruleDef/message2) }</td>
                    else
                        <td style="display:none">&#32;</td>
                    }
                </tr>
    }</table>
};
declare function uiutil:buildReportTitle($title as xs:string)
as element(h3)
{
    <h3>{ $title }</h3>
};
declare function uiutil:buildResultTable($groupTitle as xs:string, $invalidElems as element(div)*, $subTable as element(table)?)
as element(table)?
{
    let $cols := if (not(empty($subTable)) and count($subTable/tr/th) > 2) then count($subTable/tr/th) else 2
    return
        if (not(empty($invalidElems)) or not(empty($subTable))) then
            <table class="datatable" style="{ $uiutil:TABLE_STYLE }">{
                if (string-length($groupTitle) > 0) then
                    uiutil:buildTableGroupHeaderRow($groupTitle, $cols, "")
                else
                    ()
                }{
                if (not(empty($subTable))) then
                   $subTable//tr
                else
                    ()
                }{
                uiutil:buildResultTableRows($invalidElems, $cols)
            }</table>
        else
            ()
  };
declare function uiutil:buildTableGroupHeaderRow($title as xs:string, $cols as xs:integer, $style as xs:string)
as element(tr)
{
    let $style := if ($style = "") then $uiutil:TH_HEADING_STYLE else $style
    return
    <tr>
        <th scope="col" style="{ $style }" colspan="{ $cols }" i18n:translate="">&#32;{ $title }</th>
    </tr>
};
declare function uiutil:buildResultTableRows($invalidElems as element(div)*, $cols as xs:integer)
as element(tr)*
{
    if (not(empty($invalidElems))) then
        for $invalidElem in $invalidElems
        return
            uiutil:buildResultTableRow($invalidElem, $cols - 1)
    else
        ()
};
declare function uiutil:buildResultTableRow($invalidElem as element(div)?, $cols as xs:integer)
as element(tr)
{
    let $colspan := if ($cols > 1) then concat(" colspan=""", $cols, """") else ""
    return
    <tr>
        <th scope="row" style="{ $uiutil:TH_STYLE }" i18n:translate="">&#32;{ data($invalidElem/@label) }</th>{
        element { "td" }{if ($cols > 1) then attribute{"colspan"}{$cols} else (), $invalidElem}
        }
     </tr>
};
declare function uiutil:getFieldValue($node as node()?)
as xs:string
{
    if (exists($node) and exists($node/@desc) and string-length($node/@desc) > 0) then
        concat($node, " - ", $node/@desc)
    else
        data($node)
};

(:
: Builds a hidden span for external services
:)
declare function uiutil:buildFBStatusSpan($class as xs:string, $description as xs:string)
as element(span)
{
<span id="feedbackStatus" class="{$class}" style="display:none">&#32;
    {$description}
 </span>
};

declare function uiutil:buildAdditionalInfoToTable($ruleResult,  $ruleTables as element(ruletable)*) {
    uiutil:buildAdditionalInfoToTable($ruleResult,  $ruleTables, "")
};
declare function uiutil:buildAdditionalInfoToTable($ruleResult,  $ruleTables as element(ruletable)*, $role as xs:string)
{

   let $hasErrors := count($ruleResult//span[string-length(@errorCode) gt 0]) gt 0

    let $rows :=
        if ($hasErrors) then
            for $tbl in $ruleTables
                let $code := data($tbl/@supId)
                let $hasThisError := count($ruleResult//sup[text() = concat(" ", $code)]) gt 0
                let $rowColor := if ($hasThisError)  then $uiutil:SUP_EXISTS_COLOR else $uiutil:SUP_NOTEXISTS_COLOR

                let $ruleText := $tbl/../ruletext[empty(@role) or @role=$role]

                let $row :=
                    if ($hasThisError) then
                        <tr><td><span style="font-weight:normal;padding:5px;font-size:0.8em;color:{$rowColor}"><sup>{$code}</sup><span i18n:translate="">{concat(' ', data($ruleText))}</span></span></td></tr>
                    else
                        ()
                return
                    $row
    else
        ()


    return
    if (not(empty($rows))) then
        <table class="datatable" style="{ $uiutil:TABLE_STYLE }">
            {$rows}
        </table>
    else ()

};

declare function uiutil:getSubRuleShorttext($errDef as element(rule), $subRuleId as xs:string)
as xs:string? {
    $errDef//subrule[@id = $subRuleId]/shorttext

};
(:~
: @return QA rule results in HTML format.
:)
declare function uiutil:buildRuleResult($ruleCode as xs:string, $transactionCode as xs:string, $errorText as xs:string, $errLevel as xs:string,
        $isInvalid as xs:boolean, $invalidRecords, $invalidRecordsText as xs:string)
as element(div)
{
    let $countErrors := if ($isInvalid and count($invalidRecords)=0) then 1 else count($invalidRecords)
    return
        if (not($isInvalid)) then
            <div></div> (: do nothing, if result is ok :)
        else
            <div>
                <div>{
                    uiutil:buildErrorBullet($countErrors, "", $errLevel)
                } { if (string-length($transactionCode) > 0) then <strong>Transaction { $transactionCode } - </strong> else () }
                    <span>{ $errorText }</span>
                    <span> (code={ $ruleCode })</span>
                </div>
                {
                 if  (count($invalidRecords) > 0) then
                    <div class="error-details">
                        <div>{$invalidRecordsText}</div>
                        <ul>{
                            for $invalidRecord at $pos in $invalidRecords
                            return
                                <li>
                                    <span errorFlag="{ uiutil:getErrorFlagByLevel($errLevel) }" errorCode="{$ruleCode}" errorLevel="{ $errLevel }">{ $invalidRecord }</span>
                                </li>
                        }</ul>
                    </div>
                else
                    <span errorFlag="{ uiutil:getErrorFlagByLevel($errLevel) }" errorCode="{$ruleCode}" errorLevel="{ $errLevel }" style="display:none"></span>
                }
            </div>
};
