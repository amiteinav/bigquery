#!/bin/bash

export output_file=/tmp/bq_exec_$$

if [ "${1}" == "" ] ; then
    echo "No Query file provided - using default"
    if [ -f "curr_query.sql" ] ; then
        export curr_query_file=curr_query.sql
    else    
        exit 1
    fi

else
    export curr_query_file=`$1`
fi

#cat $curr_query_file
echo ""

bq query --dry_run --nouse_legacy_sql "`cat $curr_query_file`" > $output_file

bytes=`cat $output_file | awk '{print $15}'`

export GB=$((bytes/1024/1024/1024))

echo "Query is about to scan $GB GB"