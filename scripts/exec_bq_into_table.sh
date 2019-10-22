#!/bin/bash

sourcefile=$1

[ -z "$sourcefile" ] && { echo "No source file entered" ; exit 1 ; } 

source $sourcefile

bash scripts/bq_safe_mk.sh ${OUTPUT_DATASET} ${OUTPUT_PROJECT} ${LOCATION}

if [ ! -f $curr_query_file ] ; then
    echo "no such file $curr_query_file" 
    exit 1
fi

cat $curr_query_file
echo ""

bq --location=$LOCATION query \
--destination_table ${OUTPUT_PROJECT}:${OUTPUT_DATASET}.${OUTPUT_TABLE} \
--replace \
$PARTITIONING \
$CLUSTERING \
--use_legacy_sql=false "`cat $curr_query_file`"

echo "created table ${OUTPUT_PROJECT}:${OUTPUT_DATASET}.${OUTPUT_TABLE}"