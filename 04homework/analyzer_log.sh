#!/bin/bash

#=========================================================#
BIN_FOLDER=/home/vagrant/scr
LOCKFILE=$BIN_FOLDER/analyzer.lock
LOGFILE=access.log
CHECK_LINE=$BIN_FOLDER/cur_line
#=========================================================#

if [ -n "$1" ]; then
	CHECK_IP=$1
else
	CHECK_IP=10
fi

if [ -n "$2" ]; then
	CHECK_URL=$2
else
	CHECK_URL=10
fi

if [ -e $LOCKFILE ]; then
	echo "Analizer in work. Please, try again later."
	echo "PID is $(cat $LOCKFILE)"
	exit 0
fi

if [ 0 -eq $(find $BIN_FOLDER/ -maxdepth 1 -name "$LOGFILE" -type f | wc -l) ]; then
	echo -e "No LOGfile found in $BIN_FOLDER"
	exit 0
fi

echo  "$$" > "$LOCKFILE"

trap 'rm -f ${LOCKFILE} ; exit 1' 1 2 3 15

if [ ! -e $CHECK_LINE ]; then
    echo  "0" > "$CHECK_LINE"
fi

declare -A COUNT_IP
declare -A GOOD_URL
declare -A BAD_URL
declare -A COUNT_CODES

get_ip() {
	echo $1 | awk '{print $1}'
}

get_rec_date() {
	echo $1 | awk '{print $4}' | sed -e 's/^\[//g'
}

get_rec_url() {
	echo $1 | awk '{print $7}'
}

get_rec_code() {
	echo $1 | awk '{print $9}'
}

sort_arr() {
    var=$(declare -p "$1")
    eval "declare -A arr="${var#*=}

    for key in "${!arr[@]}"; do
        printf "%-50s\t%d\n" $key ${arr[$key]}
    done | sort -rn -k2
}

LAST_LINE=$(cat $CHECK_LINE)
CUR_LINE=0

while read line; do
	((CUR_LINE++))
	if [ $CUR_LINE -le $LAST_LINE ]; then
		continue
	fi
	
	if [ $(( $CUR_LINE - 1 )) -eq $LAST_LINE ]; then
		DATE_BEGIN=$(get_rec_date "$line" )
	fi
	
	DATE_END=$(get_rec_date "$line")
	IP=$(get_ip "$line")
	URL=$(get_rec_url "$line")
	CODE=$(get_rec_code "$line")
	((COUNT_IP["$IP"]++))
	((COUNT_CODES["$CODE"]++))
	if [[ $CODE =~ [4-5]([0-9]{2}) ]]; then
            ((BAD_URL[$URL]++))
        else
            ((GOOD_URL[$URL]++))
        fi
done < $LOGFILE

echo $CUR_LINE > $CHECK_LINE

result=$(
	echo "analyze date between [ $DATE_BEGIN - $DATE_END ]";\
	echo "\ntop $CHECK_IP ip addresses"; \
	echo "###################################################"; \
	sort_arr COUNT_IP | head -$CHECK_IP;
	echo "###################################################"; \
	echo "\ntop $CHECK_URL urls"; \
	echo "###################################################"; \
	sort_arr GOOD_URL | head -$CHECK_URL; \
	echo "###################################################"; \
	echo "\nanalyzing of wrong urls  (5**,4**)"; \
	echo "###################################################"; \
	sort_arr BAD_URL; \
	echo "\nanalyzing of http codes"; \
	echo "###################################################"; \
	sort_arr COUNT_CODES
)

echo -e "$report" | mail -s "Analyzing log of [ $DATE_BEGIN - $DATE_END ]" root

rm $LOCKFILE
