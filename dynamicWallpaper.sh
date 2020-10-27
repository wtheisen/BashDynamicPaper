#!/bin/bash
URL="https://api.sunrise-sunset.org/json?lat=41.6833813&lng=-86.2500066&date=today"
JSON=$(curl -s $URL)

function get_weather () {
    WEATHERDATA=$(curl "wttr.in/$1?format=j1")

    TEMP=$(echo $WEATHERDATA | jq '.current_condition | .[0] | .FeelsLikeF' )
    W_TYPE=$(echo $WEATHERDATA | jq '.current_condition | .[0] | .weatherDesc | .[0] | .value')
}

function set_EST_time () {
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

function get_time_chunk () {
    TIMEDAY=$(date +%H%M | sed 's/^0//')
    T_TYPE="Day"

    ESTSUNRISE="$1"
    ESTSUNSET="$2"

    if [[ $TIMEDAY -lt $ESTSUNRISE ]]; then
        T_TYPE="Night"
    elif [[ $TIMEDAY -gt $ESTSUNRISE ]] && (( TIMEDAY < ESTSUNRISE + 400 )); then
        T_TYPE="Morning"
    elif (( TIMEDAY < ESTSUNSET - 400 )) && (( TIMEDAY > ESTSUNRISE + 400 )); then
        T_TYPE="Day"
    elif (( TIMEDAY > ESTSUNSET - 400 )) && [[ $TIMEDAY < $ESTSUNSET ]]; then
        T_TYPE="Evening"
    else
        T_TYPE="Night"
    fi
}

function get_simple_weather () {
    W_TYPE=$1
    TEMP=$2

    if [ $(echo $W_TYPE | grep "sun") ] && (( Temp > 40 )); then
        W_TYPE="sun_"
    elif [ $(echo $W_TYPE | grep "[rain|overcast]") ]; then
        W_TYPE="rain_"
    elif [ $(echo $WTYPE | grep "snow") ] || ((Temp < 40)); then
        W_TYPE="snow_"
    else
        echo "";
    fi
}

function exit_help () {
    echo "USAGE: dynamicWallpaper -p [PAPER_PREFIX] -w [1]"
    echo "\t-p: The prefix of your wallpaper folder without a trailing /"
    echo "\t-w: Optional argument specifying whether or not to use weather data"
    exit 1
}

WEATHER=0

while getopts ":p:w" opts; do
    case "${opts}" in
        p)
            PAPE_PREFIX=${OPTARG}
            ;;
        w)
            WEATHER=1
            ;;
        *)
            exit_help
            ;;
    esac
done

set_EST_time 0
ESTSUNRISE=$ESTTIME
set_EST_time 1
ESTSUNSET=$ESTTIME
get_time_chunk "$ESTSUNRISE" "$ESTSUNSET"

if [[ $WEATHER -ne 0 ]]; then
    get_weather "KSBN"
    get_simple_weather $W_TYPE $TEMP

    /usr/bin/feh --randomize --bg-fill "$PAPE_PREFIX"/"$T_TYPE"/"$W_TYPE"*
else
    /usr/bin/feh --randomize --bg-fill "$PAPE_PREFIX"/"$T_TYPE"/*
fi
