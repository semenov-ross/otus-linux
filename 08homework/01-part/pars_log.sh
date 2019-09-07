#!/bin/bash

LOG=$1
STR=$2
DATE=`date`

CHECK_STR=/vagrant/str_chek

if [ ! -f $CHECK_STR ]; then
    echo 0 > $CHECK_STR
fi
line_start=$(cat $CHECK_STR)

regex=".*$STR.*"
line_num=0
while read line; do
    ((line_num++))
    if [[ $line =~ $regex ]]; then
	logger "word \"$STR\" found in $LOG: $line"
    fi
done < <(tail -n +$(($line_start+1)) $LOG)

echo $(($line_start+$line_num)) > $CHECK_STR
