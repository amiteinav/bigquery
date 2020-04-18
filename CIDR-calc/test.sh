#!/bin/sh
i=1
    for j in {0..1} ; do
        for k in {0..255} ; do
            for l in {0..255} ; do
                echo "$i.$j.$k.$l,$(($((i*256*256*256))+$((j*256*256))+$((k*256))+l))"
            done
        done
    done



