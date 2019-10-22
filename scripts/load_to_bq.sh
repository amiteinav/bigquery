#/bin/bash

sourcefile=$1
jsonfile=$2
PROJECT_ID=$3
DATASET=$4
TABLE=$5
time_partitioning_field=$6

message=`echo $0 source-file csv-file json-file project-id dataset table time-partition-field`

[ -z "$sourcefile" ] && { echo $message ; exit 1 ; } 
[ -z "$jsonfile" ] && { echo $message; exit 1 ; } 
[ -z "$PROJECT_ID" ] && { echo $message; exit 1 ; } 
[ -z "$DATASET" ] && { echo $message; exit 1 ; } 
[ -z "$TABLE" ] && { echo $message; exit 1 ; } 
[ -z "$time_partitioning_field" ] && { echo $message; exit 1 ; } 


bash scripts/bq_safe_mk.sh $DATASET $PROJECT_ID US


# examples:
#bq --global_flag [ARGUMENT] --global_flag [ARGUMENT] bq_command --command-specific_flag [ARGUMENT] --command-specific_flag [ARGUMENT]
#bq --location=[LOCATION] load --source_format=[FORMAT] [DATASET].[TABLE] [PATH_TO_SOURCE] [SCHEMA]

# Delete the table if needed
#bq rm -f -t ${PROJECT_ID}:${DATASET}.${TABLE}

echo" bq load \
--skip_leading_rows=1  \
--source_format=CSV  \
--time_partitioning_field $time_partitioning_field \
--noreplace \
${PROJECT_ID}:${DATASET}.${TABLE} \
${sourcefile} \
${jsonfile} "

bq load \
--skip_leading_rows=1  \
--source_format=CSV  \
--time_partitioning_field $time_partitioning_field \
--noreplace \
--schema ${jsonfile} \
${PROJECT_ID}:${DATASET}.${TABLE} \
${sourcefile} \
