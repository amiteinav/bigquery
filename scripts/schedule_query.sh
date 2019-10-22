#!/bin/bash

PROJECT=$1
OUTPUT_DATASET=$2
OUTPUT_TABLE=$3
curr_query_file=$4
LOCATION=$5
FREQ=$6
PARTITION=$7

usage=`echo "Usage: $0 project output-dataset output-table query-file location schedule-frequency time-partitioining-field"`

[ -z "${PROJECT}" ] && { echo $usage ; exit 1 ; } 
[ -z "${OUTPUT_DATASET}" ] && { echo $usage ; exit 1 ; } 
[ -z "${OUTPUT_TABLE}" ] && { echo $usage ; exit 1 ; } 
[ -z "${curr_query_file}" ] && { echo $usage ; exit 1 ; } 
[ -z "${LOCATION}" ] && { echo $usage ; exit 1 ; } 
[ -z "${FREQ}" ] && { echo $usage ; exit 1 ; } 

bash scripts/bq_safe_mk.sh ${OUTPUT_DATASET} ${PROJECT} ${LOCATION}

#frequency=`echo "every $FREQ hours"`

if [ ! -f $curr_query_file ] ; then
    echo "no such file $curr_query_file" 
    exit 1
fi

cat $curr_query_file
echo ""

temp_sql_file=/tmp/sql$$

cat ${curr_query_file} | sed "s/PROJECT_NAME/${PROJECT}/g" | sed "s/DATASET_NAME/audit_log_dataset_20190908/g" > ${temp_sql_file}

echo "bq query \
    --use_legacy_sql=false \
    --destination_table=${PROJECT}:${OUTPUT_DATASET}.${OUTPUT_TABLE} \
    --replace=true \
    ${PARTITION} \
    --schedule='every $FREQ hours' \
    QUERY"

bq query \
    --use_legacy_sql=false \
    --destination_table=${PROJECT}:${OUTPUT_DATASET}.${OUTPUT_TABLE} \
    --replace=true \
    ${PARTITION} \
    --schedule='every $FREQ hours' \
    --display_name="Scheduled Query"
    "`cat ${temp_sql_file}`"


