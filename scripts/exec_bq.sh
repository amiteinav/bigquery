#!/bin/bash

export output_file=/tmp/bq_exec_$$

curr_query_file=$1
prettyjson=$2

[ -z "$curr_query_file" ] && { echo "No dataset entered" ; exit 1 ; } 

cat $curr_query_file
echo ""

if [ "${prettyjson}" == "json" ] ; then
    bq query --nouse_legacy_sql --format=prettyjson "`cat $curr_query_file`" > $output_file 
else
    bq query --nouse_legacy_sql "`cat $curr_query_file`" > $output_file 

fi

echo "results are in file $output_file"
cat $output_file