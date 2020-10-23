#!/bin/bash
URL="https://api.sunrise-sunset.org/json?lat=41.6833813&lng=-86.2500066&date=today"
JSON=$(curl -s $URL)

function weather () {
    curl "wttr.in/$1"
}

function setESTTime () {
    UTCSUNRISE=$(echo $JSON | jq .results.sunrise | cut -d \" -f 2 | cut -d ' ' -f 1 | sed s/:/./g | sed -r 's/(.*)\./\1/g')
    UTCSUNSET=$(echo $JSON | jq .results.sunset | cut -d \" -f 2 | cut -d ' ' -f 1 | sed s/:/./g | sed -r 's/(.*)\./\1/g')

    if [ "$1" = 0 ]; then
        ESTTIME=$(echo "$UTCSUNRISE-4.0000" | bc)
        ESTTIME=$(printf "%07.4f\n" "$ESTTIME")
        ESTTIME=$(echo $ESTTIME | tr -d '.' | sed -e "s/.\{2\}/&\:/g" | sed 's/://g' | cut -c 1,2,3,4 | sed 's/^0//')
    else
        ESTTIME=$(echo "$UTCSUNSET+8.0000" | bc)
        ESTTIME=$(printf "%07.4f\n" "$ESTTIME")
        ESTTIME=$(echo $ESTTIME | tr -d '.' | sed -e "s/.\{2\}/&\:/g" | sed 's/://g' | cut -c 1,2,3,4)
    fi
}

setESTTime 0
ESTSUNRISE=$ESTTIME
setESTTime 1
ESTSUNSET=$ESTTIME

# WEATHERDATA=$(curl "wttr.in/KSBN")

TIMEYEAR=$(date | cut -f 2,3 -d ' ')
TIMEDAY=$(date +%H%M | sed 's/^0//')
# TEMP=$(echo $WEATHERDATA | tail -n 4 | awk '{print $2}' | head -n 1)
# WEATHER=$(echo $WEATHERDATA | tail -n 1 | awk '{print $3}')

WTYPE="Day"

# echo "$ESTSUNRISE"
# echo "$ESTSUNSET"
# echo "$TIMEDAY"

if [[ $TIMEDAY -lt $ESTSUNRISE ]]; then
    WTYPE="Night"
elif [[ $TIMEDAY -gt $ESTSUNRISE ]] && (( TIMEDAY < ESTSUNRISE + 400 )); then
    WTYPE="Morning"
elif (( TIMEDAY -lt ESTSUNSET - 400 )) && (( TIMEDAY > ESTSUNRISE + 400 )); then
    WTYPE="Day"
elif (( TIMEDAY -gt ESTSUNSET - 400 )) && [[ $TIMEDAY < $ESTSUNSET ]]; then
    WTYPE="Evening"
else
    WTYPE="Night"
fi

# echo $WTYPE

/usr/bin/feh --randomize --bg-fill /home/wtheisen/Dropbox/Wallpapers/"$WTPYE"/*
