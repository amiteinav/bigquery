#!/bin/bash

export LOCATION=EU
export FORMAT=CSV
export PROJECT_ID=PROJECT
export DATASET=DATASET
export TABLE=TABLE
export BUCKET=gs://BUCKET

# Getting buckets and locations
#gsutil ls -L  | egrep -i 'location|gs://'

bq --location=$LOCATION \
extract \
--destination_format $FORMAT \
#--compression compression_type \
#--field_delimiter tab \
--print_header true \
${PROJECT}:${DATASET}.${TABLE} \
$BUCKET/${DATASET}/${TABLE}*
