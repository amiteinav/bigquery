#!/bin/bash

mkdir -p files

for i in `seq $1 1 $2` ; do
        nohup bash create_all.sh $i > files/file_${i} 2>&1 &
done