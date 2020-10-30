#!/bin/bash

JQ=/usr/bin/jq
SHUF=/usr/bin/shuf
DATE=/bin/date

if which osascript; then
    DATE=/usr/local/bin/gdate
    JQ=/usr/local/bin/jq
    SHUF=/usr/local/bin/shuf
fi

get_weather () {
    weatherdata=$(curl -s "wttr.in/$1?format=j1")

    temp=$(echo "$weatherdata" | $JQ -r '.current_condition | .[0] | .FeelsLikeF' )
    w_type=$(echo "$weatherdata" | $JQ -r '.current_condition | .[0] | .weatherDesc | .[0] | .value')
}

get_lat_long () {
    loc_json=$(curl -s "https://www.airport-data.com/api/ap_info.json?icao=$1")

    lng=$(echo "$loc_json" | $JQ -r '.longitude')
    lat=$(echo "$loc_json" | $JQ -r '.latitude')
}

get_rise_set_time () {
    utc_sunrise_time=$(echo "$json" | $JQ -r .results.sunrise)
    sunrise=$($DATE +"%-k%M" -d "$utc_sunrise_time")
    utc_sunset_time=$(echo "$json" | $JQ -r .results.sunset)
    sunset=$($DATE +"%-k%M" -d "$utc_sunset_time")
}

get_time_chunk () {
    time_day=$($DATE +%-k%M)
    t_type="Day"

    sunrise="$1"
    sunset="$2"

    if [[ $time_day -lt $sunrise ]]; then
        t_type="Night"
    elif [[ $time_day -gt $sunrise ]] && (( time_day < sunrise + 230 )); then
        t_type="Morning"
    elif (( time_day < sunset - 230 )) && (( time_day > sunrise + 230 )); then
        t_type="Day"
    elif (( time_day > sunset - 230 )) && [[ $time_day < $sunset ]]; then
        t_type="Evening"
    else
        t_type="Night"
    fi
}

get_simple_weather () {
    w_type=$1
    temp=$2

    if echo "$w_type" | grep -i -q -E "[sun|Clear]" && (( temp >= 34 )); then
        w_type="Sun"
    elif echo "$w_type" | grep -i -q -E "[rain|overcast]"; then
        w_type="Rain"
    elif echo "$w_type" | grep -q -i "snow" || ((temp < 34)); then
        w_type="Snow"
    else
        echo "Misc";
    fi
}

set_pape () {
    t_type=$1
    w_type=$2

    if which osascript; then
        PAPE=$(find  "$PAPE_PREFIX"/"$t_type"/"$w_type"/* "$PAPE_PREFIX"/"$t_type"/Misc/* | $SHUF -n 1)
        CMD_STR="tell application \"System Events\" to tell every desktop to set picture to \"$PAPE\""
        osascript -e "$CMD_STR"
    else
        if find  "$PAPE_PREFIX"/"$t_type"/"$w_type"/* "$PAPE_PREFIX"/"$t_type"/Misc/* | /usr/bin/feh --randomize --bg-fill -f -
        then exit 0; fi

        /usr/bin/feh --randomize --bg-fill "$PAPE_PREFIX"/"$t_type"/*
    fi
}

exit_help () {
    echo "USAGE: dynamicWallpaper -p [PAPER_PREFIX] -w [AIRPORT_CALLSIGN]"
    printf "\t-p: The prefix of your wallpaper folder without a trailing /"
    printf "\t-w: Local airport callsign in ICAO [e.g. KSBN], used for both time and weather location"
    exit 1
}

weather="0"

while getopts ":p:w:" opts; do
    case "${opts}" in
        p)
            PAPE_PREFIX=${OPTARG}
            ;;
        w)
            weather=${OPTARG}
            ;;
        *)
            exit_help
            ;;
    esac
done

get_lat_long "$weather"

url="https://api.sunrise-sunset.org/json?lat=$lat&lng=$lng&date=today&formatted=0"
json=$(curl -s "$url")

get_rise_set_time
get_time_chunk "$sunrise" "$sunset"
get_weather "$weather"
get_simple_weather "$w_type" "$temp"

echo "Time Type: $t_type, Weather Type: $w_type"
set_pape "$t_type" "$w_type"
