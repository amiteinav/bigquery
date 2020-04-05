#!/bin/bash


echo "START $0"

while getopts ":p:d:t:e:" opt; do
  case $opt in
    p) SOURCE_PROJECT_ID="$OPTARG"
    ;;
    d) SOURCE_DATASET="$OPTARG"
    ;;
    t) TARGET_PROJECT_ID="$OPTARG"
    ;;
    e) TARGET_DATASET="$OPTARG"
    ;;
    \?) echo "ERROR $0 Invalid option -$OPTARG" >&2
    ;;
  esac
done

if [[ "${SOURCE_PROJECT_ID}" == "" || "${TARGET_PROJECT_ID}" == "" || "${SOURCE_DATASET}" == "" || "${TARGET_DATASET}" == ""  ]] ; then
    echo "[ ERROR  $0 ] Missing parameter"
    echo "[ INFO   $0 ] $0 -p SOURCE_PROJECT_ID -d SOURCE_DATASET -t TARGET_PROJECT_ID -e TARGET_DATASET"
    exit 1
fi

bq mk --transfer_config --project_id=$TARGET_PROJECT_ID \
--data_source=cross_region_copy \
--target_dataset=${TARGET_DATASET} \
--display_name='My Dataset Copy' \
--params='{"source_dataset_id":"${SOURCE_DATASET}","source_project_id":"${SOURCE_PROJECT_ID}","overwrite_destination_table":"true"}'
