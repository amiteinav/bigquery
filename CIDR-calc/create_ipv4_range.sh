#!/bin/bash

#IP to Integer IP formula: #192(256)^3 + 168(256)^2 + 0(256)^1 + 1			

if [ "$1" != "" ] ; then
i=$1

for i in {0..255} ; do
    for j in {0..255} ; do
        for k in {0..255} ; do
            for l in {0..255} ; do
                echo "$i.$j.$k.$l,$(($((i*256*256*256))+$((j*256*256))+$((k*256))+l))"
            done
        done
    done
done



