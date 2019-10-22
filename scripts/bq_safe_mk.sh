#!/bin/bash

# this is how you call the function
#bash bq_safe_mk.sh dataset-name

    dataset=$1
    project=$2
    location=$3

    [ -z "$dataset" ] && { echo "No dataset entered" ; exit 1 ; } 
    [ -z "$project" ] && { echo "No project entered" ; exit 1 ; } 
    [ -z "$location" ] && { echo "No location entered" ; exit 1 ; } 

    exists=$(bq ls -d ${project}: | grep -w $dataset)
    if [ -n "$exists" ]; then
       echo "Not creating $dataset since it already exists"
    else
       echo "Creating $dataset"
       bq mk --location $location \
       --dataset ${project}:${dataset} 
    fi

