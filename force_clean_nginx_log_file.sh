#!/bin/bash
x=`lsof | grep deleted | awk '{print $2}'`
for i in $x
do
echo > /proc/$i/fd/3
done
