#!/bin/bash

project_id=$1
dataset=$2
table=$3
jsonfile=$4

message=`echo $0 project dataset table jsonfile`

[ -z "$project_id" ] && { echo $message ; exit 1 ; } 
[ -z "$dataset" ] && { echo $message; exit 1 ; } 
[ -z "$table" ] && { echo $message; exit 1 ; } 
[ -z "$jsonfile" ] && { echo $message; exit 1 ; } 


bq show \
--schema \
--format=prettyjson \
${project_id}:${dataset}.${table} > ${jsonfile}