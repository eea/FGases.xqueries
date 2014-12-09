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

declare function xmlconv:rule_1($doc as element())
as element(div) {

  (: apply to rule 2016 :)

  let $err_text := "You reported on own destruction in section 1B. Please accordingly select to
      be a destruction company in the activity selection and report subsequently in section 8."

  let $err_flag :=
    sum($doc/F1_S1_4_ProdImpExp/Gas/tr_01B[number(Amount) > 1000])
    and $doc/GeneralReportData/Activities/D != 'true'

  return uiutil:buildRuleResult("2016", "1B", $err_text, $xmlconv:BLOCKER, $err_flag, (), "")
};


declare function xmlconv:rule_2($doc as element(), $tran as xs:string)
as element(div) {

  (: apply to rule 2017 :)

  let $err_text := "A negative amount here is implausible, please revise your data."

  let $err_flag :=
    for $gas in $doc/F1_S1_4_ProdImpExp/Gas
    where $gas/*[name()=concat('tr_0', $tran)][number(Amount) < 0]
    return
      data($doc/ReportedGases[GasId = $gas/GasCode]/Name)

  return uiutil:buildRuleResult("2017", $tran, $err_text, $xmlconv:BLOCKER, count($err_flag)>0, $err_flag, "Invalid gases are: ")
};


declare function xmlconv:rule_3($doc as element())
as element(div) {

  (: apply to rule 2040 :)

  let $err_text := "Please explain the 'other' intended application
    / why the application is unknown."

  let $err_flag :=
    for $gas in $doc/F3A_S6A_IA_HFCs/Gas
    where $gas/tr_06T[number(Amount) > 0]
    return
      if (cutil:isEmpty($gas/tr_06T/Comment))
        then data($doc/ReportedGases[GasId = $gas/GasCode]/Name)
        else ()

  return uiutil:buildRuleResult("2040", "6T", $err_text, $xmlconv:BLOCKER, count($err_flag)>0, $err_flag, "Invalid gases are: ")
};


declare function xmlconv:rule_4($doc as element())
as element(div) {

  (: apply to rule 2041 :)

  let $err_text := "Please provide an explanation for accountancy adjustments."

  let $err_flag :=
    for $gas in $doc/F3A_S6A_IA_HFCs/Gas
    where $gas/tr_06V[number(Amount) != 0]
    return
      if (cutil:isEmpty($gas/tr_06V/Comment))
        then data($doc/ReportedGases[GasId = $gas/GasCode]/Name)
        else ()

  return uiutil:buildRuleResult("2041", "6V", $err_text, $xmlconv:BLOCKER, count($err_flag)>0, $err_flag, "Invalid gases are: ")
};


declare function xmlconv:rule_5($doc as element())
as element(div) {

  (: apply to rule 2042 :)

  let $err_text := "The totals reported for intended applications (6W)
    should match the totals reported as placed on the Union market (6X).
    Please revise your data."

  let $err_flag :=
    for $gas in $doc/F3A_S6A_IA_HFCs/Gas
    return
      if ($gas/tr_06W/Amount != $gas/tr_06X/Amount)
        then data($doc/ReportedGases[GasId = $gas/GasCode]/Name)
        else ()

  return uiutil:buildRuleResult("2042", "6W", $err_text, $xmlconv:BLOCKER, count($err_flag)>0, $err_flag, "Invalid gases are: ")
};


declare function xmlconv:rule_6($doc as element())
as element(div) {

  (: apply to rule 2043 :)

  let $err_text := "The totals calculated in 6X must not be negative.
    Please check amounts reported for production, imports, exports,
    and stocks (sections 1 to 4)."

  let $err_flag :=
    for $gas in $doc/F3A_S6A_IA_HFCs/Gas
    where $gas/tr_06X[number(Amount) < 0]
    return data($doc/ReportedGases[GasId = $gas/GasCode]/Name)

  return uiutil:buildRuleResult("2043", "6X", $err_text, $xmlconv:BLOCKER, count($err_flag)>0, $err_flag, "Invalid gases are: ")
};


declare function xmlconv:rule_7($doc as element(), $tran as xs:string, $tran_unit as xs:string)
as element(div) {

  (: apply to rule 2050 :)

  let $err_text := "Please specify a measurement unit for the
    amount of products/equipment imported."

  let $err_flag :=
    if ($doc/F7_s11EquImportTable/UISelectedTransactions/*[name()=concat('tr_', $tran)] = 'true')
      then
        for $gas in $doc/F7_s11EquImportTable/Gas
        where ($gas/*[name()=concat('tr_', $tran)][number(Amount) > 0])
          return
            if ($doc/F7_s11EquImportTable/*[name()=concat('TR_', $tran_unit, '_Unit')] = '')
              then data($doc/ReportedGases[GasId = $gas/GasCode]/Name)
              else ()
      else ()

  return uiutil:buildRuleResult("2050", $tran, $err_text, $xmlconv:BLOCKER, count($err_flag)>0, $err_flag, "Invalid gases are: ")
};


declare function xmlconv:rule_8($doc as element(), $tran as xs:string)
as element(div) {

  (: apply to rule 2051 :)

  let $err_text := "You reported on the amount of imported products/equipment.
    Please report on the amount of contained gases, as well
    (unit: metric tonnes of gases)."

  let $err_flag :=
    if ($doc/F7_s11EquImportTable/UISelectedTransactions/*[name()=concat('tr_', $tran)] = 'true')
      then
        if (fn:not(cutil:isMissingOrEmpty($doc/F7_s11EquImportTable/AmountOfImportedEquipment/*[name()=concat('tr_', $tran)]/Amount)))
          then
            for $gas in $doc/F7_s11EquImportTable/Gas
            let $amount := $gas/*[name()=concat('tr_', $tran)]/Amount
            where (cutil:isMissingOrEmpty($amount) or number($amount) = 0)
              return data($doc/ReportedGases[GasId = $gas/GasCode]/Name)
          else ()
      else ()

 return uiutil:buildRuleResult("2051", $tran, $err_text, $xmlconv:BLOCKER, count($err_flag)>0, $err_flag, "Invalid gases are: ")
};


declare function xmlconv:rule_9($doc as element(), $tran as xs:string,
                                   $exempt_tran as xs:string, $rule as xs:string)
as element(div) {

  (: apply to rules 2091, 2092, 2093, 2094, 2095, 2096 :)

  let $err_text := "The amount reported for exempted supply for export in 5C_exempted must
    not exceed the amount reported for the intended application 'export' in 6A.
    Please revise your data."

  let $gases :=
    for $gas in $doc/GeneralReportData/HFCs/GasName
    for $mixture in $doc/GeneralReportData/CommonlyUsedMixtures/GasName
    return $gas | $mixture

  let $err_flag :=
    for $gas in $gases

    let $node_exempted := $doc/F2_S5_exempted_HFCs/Gas[GasCode=$gas]/*[name()=concat('tr_0', $exempt_tran)]/SumOfPartnerAmounts
    let $node_gas := $doc/F3A_S6A_IA_HFCs/Gas[GasCode=$gas]/*[name()=concat('tr_0', $tran)]/Amount

    return
      if ($node_exempted != '' and $node_gas != '')
        then
          if (fn:number($node_gas) ge fn:number($node_exempted))
          then ()
          else data($doc/ReportedGases[GasId eq $gas]/Name)
        else ()

  return uiutil:buildRuleResult($rule, $tran, $err_text, $xmlconv:BLOCKER,
         count($err_flag)>0, $err_flag, "Invalid gases are: ")
};


declare function xmlconv:rule_10($doc as element(), $tran as xs:string, $tran_unit as xs:string)
as element(div) {

  (: apply to rule 2300 :)

  let $err_text := "The calculated specific charge of F-gases exceeds 1000kg/tonne;
    therefore a value or unit must be incorrect. Please revise reported data or units."

  let $err_flag :=
    if ($doc/F7_s11EquImportTable/UISelectedTransactions/*[name()=concat('tr_', $tran)] = 'true')
      then
        if ($doc/F7_s11EquImportTable/*[name()=concat('TR_', $tran_unit, '_Unit')] = 'metrictonnes')
          then
            if ($doc/F7_s11EquImportTable/AmountOfImportedEquipment/*[name()=concat('tr_', $tran)]/Amount > 1000)
              then fn:true()
              else fn:false()
          else fn:false()
      else fn:false()

  return uiutil:buildRuleResult("2300", $tran, $err_text, $xmlconv:BLOCKER, $err_flag, (), "")

};


declare function xmlconv:rule_11($doc as element(),
                                        $tran as xs:string,
                                        $range_min as xs:decimal,
                                        $range_max as xs:decimal,
                                        $range_unit as xs:string,
                                        $rule as xs:string)
as element(div) {

  (: apply to rules 2301, 2302, 2303, 2304, 2305, 2306, 2307, 2308, 2310, 2311,
                    2312, 2313, 2314, 2315, 2316, 2317, 2318, 2319, 2320,
                    2327, 2328, 2329, 2330, 2331, 2332, 2333 :)

  let $err_text := concat("The calculated specific charge of F-gases is not in the expected range
    (", $range_min," and ", $range_max, " ", $range_unit, "). Please make sure you correctly reported the amounts of gases in
    units of tonnes, not in kilograms. Please revise your data or provide an explanation to the
    calculated specific charge.")

  let $err_flag :=
    if ($doc/F7_s11EquImportTable/UISelectedTransactions/*[name()=concat('tr_', $tran)] = 'true')
      then
        if ($doc/F7_s11EquImportTable[AmountOfImportedEquipment != ''])
          then
            if ($doc/F7_s11EquImportTable/AmountOfImportedEquipment/
                *[name()=concat('tr_', $tran)]
                [number(Amount) > $range_min]
                [number(Amount) < $range_max])
              then fn:false()
              else fn:true()
          else fn:false()
      else fn:false()

  let $err_status :=
    if ($doc/F7_s11EquImportTable/Comment/*[name()=concat('tr_', $tran)] = '')
      then $xmlconv:BLOCKER
      else $xmlconv:WARNING

  return uiutil:buildRuleResult(
    $rule, $tran, $err_text, $err_status, $err_flag, (), "")
};


declare function xmlconv:rule_12($doc as element(),
                                   $tran as xs:string,
                                   $range_max as xs:decimal,
                                   $range_unit as xs:string,
                                   $rule as xs:string)
as element(div) {

  (: apply to rules 2321, 2322, 2323, 2324, 2331 :)

  let $err_text := concat("The calculated specific charge of F-gases is not in the expected range
    (up to ", $range_max, " ", $range_unit, "). Please make sure you correctly reported the amounts of gases in
    units of tonnes, not in kilograms. Please revise your data or provide an explanation to the
    calculated specific charge.")

  let $err_flag :=
    if ($doc/F7_s11EquImportTable/UISelectedTransactions/*[name()=concat('tr_', $tran)] = 'true')
      then
        if ($doc/F7_s11EquImportTable[AmountOfImportedEquipment != ''])
          then
            if ($doc/F7_s11EquImportTable/AmountOfImportedEquipment/*[name()
                =concat('tr_', $tran)]/Amount[number() < $range_max])
              then fn:false()
              else fn:true()
          else fn:false()
      else fn:false()

  let $err_status :=
    if ($doc/F7_s11EquImportTable/Comment/*[name()=concat('tr_', $tran)] = '')
      then $xmlconv:BLOCKER
      else $xmlconv:WARNING

  return uiutil:buildRuleResult(
    $rule, $tran, $err_text, $err_status, $err_flag, (), "")
};


declare function xmlconv:rule_13($doc as element(), $tran as xs:string)
as element(div) {

  (: apply to rule 2065 :)

  let $err_text := "You reported on the amount of contained gases in imported products/equipment.
      Please report on the amount of imported products/equipment, as well."

  let $gases :=
    if ($doc/F7_s11EquImportTable/UISelectedTransactions/*[name()=concat('tr_', $tran)] = 'true')
      then
        for $gas in $doc/F7_s11EquImportTable/Gas
        where $gas/*[name()=concat('tr_', $tran)][number(Amount) > 0]
        return $gas/GasCode
      else ()

  let $amount := $doc/F7_s11EquImportTable/AmountOfImportedEquipment/*[name()=concat('tr_', $tran)]/Amount

  let $err_flag :=
    if (fn:count($gases) > 0 and (cutil:isEmpty($amount) or number($amount) = 0))
      then fn:true()
      else fn:false()

  return uiutil:buildRuleResult(
    "2065", $tran, $err_text, $xmlconv:BLOCKER, $err_flag, (), "")
};


declare function xmlconv:rule_14($doc as element())
as element(div) {

  (: apply to rule 2079 :)

  let $err_text := "Please explain the category of imported products/equipment."

  let $err_flag :=
    if ($doc/F7_s11EquImportTable/UISelectedTransactions/tr_11P = 'true'
      and $doc/F7_s11EquImportTable/SumOfAllGasesS1/tr_11P[number(Amount) > 0]
      and cutil:isMissingOrEmpty($doc/F7_s11EquImportTable/Category/tr_11P))
      then fn:true()
      else fn:false()

  return uiutil:buildRuleResult("2079", "11P", $err_text, $xmlconv:BLOCKER, $err_flag, (), "")
};


declare function xmlconv:rule_15($doc as element())
as element(div) {

  (: apply to rule 2078 :)

  let $err_text := "A negative amount here is implausible, please revise your data."

  let $gases :=
    for $gas in $doc/ReportedGases
    where $gas/IsBlend = 'true'
    return $gas/GasId

  let $err_flag :=
    for $gas in $gases
    return
      if ($doc/F1_S1_4_ProdImpExp/Gas[GasCode=$gas]/tr_01H[number(Amount) < 0])
        then data($doc/ReportedGases[GasId eq $gas]/Name)
        else ()

  return uiutil:buildRuleResult("2078", "1H", $err_text, $xmlconv:BLOCKER,
         count($err_flag)>0, $err_flag, "Invalid gases are: ")
};


declare function xmlconv:validateReport($url as xs:string)
as element(div)
{
    let $doc := fn:doc($url)/FGasesReporting

    let $r2016 := xmlconv:rule_1($doc)

    let $r2017 :=
        for $tran in ('1E', '3C', '4D', '4E', '4I', '4J')
            return xmlconv:rule_2($doc, $tran)

    let $r2040 := xmlconv:rule_3($doc)
    let $r2041 := xmlconv:rule_4($doc)
    let $r2042 := xmlconv:rule_5($doc)
    let $r2043 := xmlconv:rule_6($doc)

    let $r2050 :=
        xmlconv:rule_7($doc, '11P', '11P') | xmlconv:rule_7($doc, '11H04', '11H4')

    let $r2051 :=
        for $tran in ('11A01', '11A02', '11A03', '11A04', '11A05', '11A06', '11A07',
                      '11A08', '11A09', '11A10', '11A11', '11A12', '11A13', '11A14',
                      '11B01', '11B02', '11B03', '11B04', '11B05', '11B06', '11B07',
                      '11B08', '11B09', '11B10', '11B11', '11B12', '11B13', '11B14',
                      '11C', '11D01', '11D02', '11D03', '11E01', '11E02', '11E03',
                      '11E04', '11F01', '11F02', '11F03', '11F04', '11F05', '11F06',
                      '11F07', '11F08', '11F09', '11H01', '11H02', '11H03', '11H04',
                      '11I', '11J', '11K', '11L', '11M', '11N', '11O', '11P')
            return xmlconv:rule_8($doc, $tran)

    let $r2065 :=
        for $tran in ('11A01', '11A02', '11A03', '11A04', '11A05', '11A06', '11A07',
                      '11A08', '11A09', '11A10', '11A11', '11A12', '11A13', '11A14',
                      '11B01', '11B02', '11B03', '11B04', '11B05', '11B06', '11B07',
                      '11B08', '11B09', '11B10', '11B11', '11B12', '11B13', '11B14',
                      '11C', '11D01', '11D02', '11D03', '11E01', '11E02', '11E03',
                      '11E04', '11F01', '11F02', '11F03', '11F04', '11F05', '11F06',
                      '11F07', '11F08', '11F09', '11H01', '11H02', '11H03', '11H04',
                      '11I', '11J', '11K', '11L', '11M', '11N', '11O', '11P')
            return xmlconv:rule_13($doc, $tran)


    let $r2078 := xmlconv:rule_15($doc)
    let $r2079 := xmlconv:rule_14($doc)

    let $r2091 := xmlconv:rule_9($doc, "6A", "5C", "2091")
    let $r2092 := xmlconv:rule_9($doc, "6B", "5A", "2092")
    let $r2093 := xmlconv:rule_9($doc, "6C", "5D", "2093")
    let $r2094 := xmlconv:rule_9($doc, "6I", "5F", "2094")
    let $r2095 := xmlconv:rule_9($doc, "6L", "5B", "2095")
    let $r2096 := xmlconv:rule_9($doc, "6M", "5E", "2096")

    let $r2300 :=
        xmlconv:rule_10($doc, '11P', '11P') | xmlconv:rule_10($doc, '11H04', '11H4')

    let $r2301 := xmlconv:rule_11($doc, "11A01", 0.2, 1000.0, "kg/piece", "2301")

    let $r2302 :=
        for $tran in ('11A07', '11A08', '11A09', '11A10', '11A11', '11A12')
            return xmlconv:rule_11($doc, $tran, 0.2, 300.0, "kg/piece", "2302")

    let $r2303 :=
        for $tran in ('11B01', '11B02', '11B03', '11B04', '11B05', '11B06',
                      '11B07', '11B08', '11B09', '11B10', '11B11', '11B14')
            return xmlconv:rule_11($doc, $tran, 1.0, 1000.0, "kg/piece", "2303")

    let $r2304 := xmlconv:rule_11($doc, "11B12", 1.0, 800.0, "kg/piece", "2304")
    let $r2305 := xmlconv:rule_11($doc, "11B13", 1.0, 400.0, "kg/piece", "2305")

    let $r2306 := xmlconv:rule_11($doc, "11C", 0.15, 0.5, "kg/piece", "2306")

    let $r2307 :=
        for $tran in ('11D01', '11D03')
            return xmlconv:rule_11($doc, $tran, 0.2, 1000.0, "kg/piece", "2307")

    let $r2308 := xmlconv:rule_11($doc, "11D02", 0.2, 300.0, "kg/piece", "2308")

    let $r2310 := xmlconv:rule_11($doc, "11E01", 0.7, 1.3, "kg/piece", "2310")
    let $r2311 := xmlconv:rule_11($doc, "11E02", 0.8, 1.6, "kg/piece", "2311")

    let $r2312 :=
        for $tran in ('11E03', '11E04')
            return xmlconv:rule_11($doc, $tran, 10.0, 5000.0, "kg/piece", "2312")

    let $r2313 := xmlconv:rule_11($doc, "11F01", 0.3, 1.5, "kg/piece", "2313")
    let $r2314 := xmlconv:rule_11($doc, "11F02", 7.0, 20.0, "kg/piece", "2314")
    let $r2315 := xmlconv:rule_11($doc, "11F03", 0.5, 1.5, "kg/piece", "2315")
    let $r2316 := xmlconv:rule_11($doc, "11F04", 0.7, 1.5, "kg/piece", "2316")
    let $r2317 := xmlconv:rule_11($doc, "11F05", 0.7, 2.5, "kg/piece", "2317")
    let $r2318 := xmlconv:rule_11($doc, "11F06", 5.0, 35.0, "kg/piece", "2318")
    let $r2319 := xmlconv:rule_11($doc, "11F07", 100.0, 1000.0, "kg/piece", "2319")
    let $r2320 := xmlconv:rule_11($doc, "11F08", 2.0, 10.0, "kg/piece", "2320")
    let $r2321 := xmlconv:rule_12($doc, "11F09", 5000.0, "kg/piece", "2321")
    let $r2322 := xmlconv:rule_12($doc, "11H01", 1040.0, "kg/cubic metre", "2322")
    let $r2323 := xmlconv:rule_12($doc, "11H02", 100.0, "kg/cubic metre", "2323")
    let $r2324 := xmlconv:rule_12($doc, "11H03", 0.5, "kg per container", "2324")

    let $r2327 := xmlconv:rule_11($doc, "11I", 3.0, 500.0, "kg/piece", "2327")
    let $r2328 := xmlconv:rule_11($doc, "11J", 0.007, 0.020, "kg/piece", "2328")
    let $r2329 := xmlconv:rule_11($doc, "11K", 0.05, 0.5, "kg/piece", "2329")
    let $r2330 := xmlconv:rule_11($doc, "11M", 1.0, 500.0, "kg/piece", "2330")
    let $r2331 := xmlconv:rule_12($doc, "11L", 500.0, "kg/piece", "2331")
    let $r2332 := xmlconv:rule_11($doc, "11N", 1.0, 500.0, "kg/piece", "2332")
    let $r2333 := xmlconv:rule_11($doc, "11O", 0.2, 1000.0, "kg/piece", "2333")


  return
    <div class="errors">
        <h4>Error details</h4>
        {$r2016}
        {$r2017}
        {$r2040}
        {$r2041}
        {$r2042}
        {$r2043}
        {$r2050}
        {$r2051}
        {$r2065}
        {$r2078}
        {$r2079}
        {$r2091}
        {$r2092}
        {$r2093}
        {$r2094}
        {$r2095}
        {$r2096}
        {$r2300}
        {$r2301}
        {$r2302}
        {$r2303}
        {$r2304}
        {$r2305}
        {$r2306}
        {$r2307}
        {$r2308}
        {$r2310}
        {$r2311}
        {$r2312}
        {$r2313}
        {$r2314}
        {$r2315}
        {$r2316}
        {$r2317}
        {$r2318}
        {$r2319}
        {$r2320}
        {$r2321}
        {$r2322}
        {$r2323}
        {$r2324}
        {$r2327}
        {$r2328}
        {$r2329}
        {$r2330}
        {$r2331}
        {$r2332}
        {$r2333}
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

