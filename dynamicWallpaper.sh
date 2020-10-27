#!/bin/bash

function get_weather () {
    WEATHERDATA=$(curl -s "wttr.in/$1?format=j1")

    TEMP=$(echo $WEATHERDATA | jq '.current_condition | .[0] | .FeelsLikeF' )
    W_TYPE=$(echo $WEATHERDATA | jq '.current_condition | .[0] | .weatherDesc | .[0] | .value')
}

function get_rise_set_time () {
    T=$(echo $JSON | jq .results.sunrise | sed s/\"//g)
    SUNRISE=$(date +"%H%M" -d $T | sed 's/^0//')
    T=$(echo $JSON | jq .results.sunset | sed s/\"//g)
    SUNSET=$(date +"%H%M" -d $T | sed 's/^0//')
}

function get_time_chunk () {
    TIMEDAY=$(date +%H%M | sed 's/^0//')
    T_TYPE="Day"

    SUNRISE="$1"
    SUNSET="$2"

    if [[ $TIMEDAY -lt $SUNRISE ]]; then
        T_TYPE="Night"
    elif [[ $TIMEDAY -gt $SUNRISE ]] && (( TIMEDAY < SUNRISE + 400 )); then
        T_TYPE="Morning"
    elif (( TIMEDAY < SUNSET - 400 )) && (( TIMEDAY > SUNRISE + 400 )); then
        T_TYPE="Day"
    elif (( TIMEDAY > SUNSET - 400 )) && [[ $TIMEDAY < $SUNSET ]]; then
        T_TYPE="Evening"
    else
        T_TYPE="Night"
    fi
}

function get_simple_weather () {
    W_TYPE=$1
    TEMP=$2

    if [ $(echo $W_TYPE | grep "sun") ] && (( Temp > 34 )); then
        W_TYPE="sun_"
    elif [ $(echo $W_TYPE | grep "[rain|overcast]") ]; then
        W_TYPE="rain_"
    elif [ $(echo $WTYPE | grep "snow") ] || ((Temp < 34)); then
        W_TYPE="snow_"
    else
        echo "";
    fi
}

function exit_help () {
    echo "USAGE: dynamicWallpaper -p [PAPER_PREFIX] -w [AIRPORT CALLSIGN]"
    echo "\t-p: The prefix of your wallpaper folder without a trailing /"
    echo "\t-w: Optional argument specifying whether or not to use weather data, use your local airport callsign [e.g. LAX]"
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

URL="https://api.sunrise-sunset.org/json?lat=41.6833813&lng=-86.2500066&date=today&formatted=0"
JSON=$(curl -s $URL)

get_rise_set_time
get_time_chunk "$SUNRISE" "$SUNSET"

if [ $WEATHER != "0" ]; then
    get_weather $WEATHER
    echo $T_TYPE $W_TYPE $TEMP

    get_simple_weather $W_TYPE $TEMP

    /usr/bin/feh --randomize --bg-fill "$PAPE_PREFIX"/"$T_TYPE"/"$W_TYPE"*
    if [ $? -eq 0 ]; then exit 0; fi
fi

/usr/bin/feh --randomize --bg-fill "$PAPE_PREFIX"/"$T_TYPE"/*
