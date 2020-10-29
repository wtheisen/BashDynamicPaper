#!/bin/bash

JQ=/usr/bin/jq
SHUF=/usr/bin/shuf
DATE=/bin/date
if which osascript; then
    DATE=/usr/local/bin/gdate
    JQ=/usr/local/bin/jq
    SHUF=/usr/local/bin/shuf
fi

function get_weather () {
    WEATHERDATA=$(curl -s "wttr.in/$1?format=j1")

    TEMP=$(echo $WEATHERDATA | $JQ '.current_condition | .[0] | .FeelsLikeF' )
    W_TYPE=$(echo $WEATHERDATA | $JQ '.current_condition | .[0] | .weatherDesc | .[0] | .value')
}

function get_lat_long () {
    LOC_JSON=$(curl -s "https://www.airport-data.com/api/ap_info.json?icao=$1")

    LAT=$(echo $LOC_JSON | $JQ '.latitude' | sed 's/"//g')
    LNG=$(echo $LOC_JSON | $JQ '.longitude' | sed 's/"//g')
}

function get_rise_set_time () {
    T=$(echo $JSON | $JQ .results.sunrise | sed 's/"//g')
    SUNRISE=$($DATE +"%H%M" -d $T | sed 's/^0//')
    T=$(echo $JSON | $JQ .results.sunset | sed 's/"//g')
    SUNSET=$($DATE +"%H%M" -d $T | sed 's/^0//')
}

function get_time_chunk () {
    TIMEDAY=$($DATE +%H%M | sed 's/^0//')
    T_TYPE="Day"

    SUNRISE="$1"
    SUNSET="$2"

    if [[ $TIMEDAY -lt $SUNRISE ]]; then
        T_TYPE="Night"
    elif [[ $TIMEDAY -gt $SUNRISE ]] && (( TIMEDAY < SUNRISE + 230 )); then
        T_TYPE="Morning"
    elif (( TIMEDAY < SUNSET - 230 )) && (( TIMEDAY > SUNRISE + 230 )); then
        T_TYPE="Day"
    elif (( TIMEDAY > SUNSET - 230 )) && [[ $TIMEDAY < $SUNSET ]]; then
        T_TYPE="Evening"
    else
        T_TYPE="Night"
    fi
}

function get_simple_weather () {
    W_TYPE=$(echo $1 | sed 's/\"//g')
    TEMP=$(echo $2 | sed 's/\"//g')

    if [ $(echo $W_TYPE | grep -i -E "[sun|Clear]") ] && (( TEMP >= 34 )); then
        W_TYPE="Sun"
    elif [ $(echo $W_TYPE | grep -i -E "[rain|overcast]") ]; then
        W_TYPE="Rain"
    elif [ $(echo $WTYPE | grep -i "snow") ] || ((TEMP < 34)); then
        W_TYPE="Snow"
    else
        echo "Misc";
    fi
}

function set_pape () {
    T_TYPE=$1
    W_TYPE=$2

    if which osascript; then
        PAPE=$(find  "$PAPE_PREFIX"/"$T_TYPE"/"$W_TYPE"/* "$PAPE_PREFIX"/"$T_TYPE"/Misc/* | shuf -n 1)
        CMD_STR="tell application \"System Events\" to tell every desktop to set picture to \""$PAPE"\""
        osascript -e "$CMD_STR"
    else
        find  "$PAPE_PREFIX"/"$T_TYPE"/"$W_TYPE"/* "$PAPE_PREFIX"/"$T_TYPE"/Misc/* | /usr/bin/feh --randomize --bg-fill -f -
        if [ $? -eq 0 ]; then exit 0; fi

        /usr/bin/feh --randomize --bg-fill "$PAPE_PREFIX"/"$T_TYPE"/*
    fi
}

function exit_help () {
    echo "USAGE: dynamicWallpaper -p [PAPER_PREFIX] -w [AIRPORT_CALLSIGN]"
    echo "\t-p: The prefix of your wallpaper folder without a trailing /"
    echo "\t-w: Local airport callsign in ICAO [e.g. KSBN], used for both time and weather location"
    exit 1
}

WEATHER="0"

while getopts ":p:w:" opts; do
    case "${opts}" in
        p)
            PAPE_PREFIX=${OPTARG}
            ;;
        w)
            WEATHER=${OPTARG}
            ;;
        *)
            exit_help
            ;;
    esac
done

get_lat_long $WEATHER

URL="https://api.sunrise-sunset.org/json?lat=$LAT&lng=$LNG&date=today&formatted=0"
JSON=$(curl -s $URL)

get_rise_set_time
get_time_chunk $SUNRISE $SUNSET
get_weather $WEATHER
get_simple_weather $W_TYPE $TEMP

set_pape $T_TYPE $W_TYPE
