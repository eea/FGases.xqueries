#!/bin/bash

function get_all_tests {
    if [ "$1" != "" ]; then
        for i in $@; do
            echo -n tests/$i" "
        done
        echo
    else
        echo "tests/*/"
    fi
}

function test_rule {
    for xml in `find $1 -name '*.xml'`; do
        echo -n " *  $xml ... "
        test_xml $xml
    done
}

function test_xml {
    SEARCH_TEXT="Blocking errors"
    OUTFILE=/tmp/_out.html

    java -cp lib/saxon9-xqj.jar:lib/saxon9he.jar net.sf.saxon.Query -qversion:1.0 fgases-2015.xquery source_url=$1 > $OUTFILE 2> /dev/null

    grep "$SEARCH_TEXT" $OUTFILE &> /dev/null

    if [ $? != 0 ]; then
        echo "FAIL"
    else
        echo "OK"
    fi
}

# Main program
ALL_TESTS=`get_all_tests $@`

for i in $ALL_TESTS; do
    echo "Testing: $i "
    test_rule $i
done
