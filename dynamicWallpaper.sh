#!/bin/bash
[[ "$(uname -s)" = "Darwin" ]] && PATH="/usr/local/bin:${PATH}" && export PATH
command -v gdate >/dev/null 2>&1 && date() { command gdate "${@}"; }

get_weather () {
    weatherdata=$(curl -s "wttr.in/$1?format=j1")

    temp=$(echo "$weatherdata" | jq -r '.current_condition | .[0] | .FeelsLikeF' )
    w_type=$(echo "$weatherdata" | jq -r '.current_condition | .[0] | .weatherDesc | .[0] | .value')
}

get_lat_long () {
    loc_json=$(curl -s "https://www.airport-data.com/api/ap_info.json?iata=$1")

    lng=$(echo "$loc_json" | jq -r '.longitude')
    lat=$(echo "$loc_json" | jq -r '.latitude')
}

get_rise_set_time () {
    utc_sunrise_time=$(echo "$json" | jq -r .results.sunrise)
    sunrise=$(date +"%-k%M" -d "$utc_sunrise_time")
    utc_sunset_time=$(echo "$json" | jq -r .results.sunset)
    sunset=$(date +"%-k%M" -d "$utc_sunset_time")
}

get_time_chunk () {
    time_day=$(date +%-k%M)
    t_type="Day"

    sunrise="$1"
    sunset="$2"

    if (( time_day < sunrise )); then
        t_type="Night"
    elif (( time_day >= sunrise )) && (( time_day < sunrise + 230 )); then
        t_type="Morning"
    elif (( time_day < sunset - 230 )) && (( time_day > sunrise + 230 )); then
        t_type="Day"
    elif (( time_day > sunset - 230 )) && (( time_day < sunset )); then
        t_type="Evening"
    else
        t_type="Night"
    fi
}

get_simple_weather () {
    w_type=$1
    temp=$2

    if echo "$w_type" | grep -i -q -E "sun|clear" && (( temp >= 34 )); then
        w_type="Sun"
    elif echo "$w_type" | grep -i -q -E "rain|overcast|Light drizzle"; then
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

    if ! pape=$(find "$pape_prefix"/"$t_type"/"$w_type"/* "$pape_prefix"/"$t_type"/Misc/* | shuf -n 1); then
        pape=$(find "$pape_prefix"/"$t_type"/* | shuf -n 1)
    fi

    if [[ $embed -eq 1 ]]; then
        convert $pape <( curl -s wttr.in/$1_qp0.png ) -geometry +50+50 -composite embed_pape.png
        pape="$(pwd)/embed_pape.png"
    fi

    echo "$pape"

    if which osascript; then
        cmd_str="tell application \"System Events\" to tell every desktop to set picture to \"$pape\""
        osascript -e "$cmd_str"
    else
        case $XDG_CURRENT_DESKTOP in
            *XFCE*)
                export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"
                    xfconf-query -c xfce4-desktop -l | \
                grep --color=never last-image | \
                while read -r path; do xfconf-query --channel xfce4-desktop --property "$path" -s "$pape"; done
                ;;
            *)
                feh --randomize --bg-fill "$pape"
                ;;
        esac

    fi

    if [[ $use_wal -eq 1 ]]; then
        if ! which wal; then
            PATH="$HOME/.local/bin":${PATH} && export PATH
        fi

        if which wal; then
            wal -i "$pape" -n --saturate 1.0
        else
            echo "Trying to use wal but it's not installed"
        fi
    fi
}

exit_help () {
    echo "ERROR: $1"
    echo "USAGE: dynamicWallpaper -p [PAPER_PREFIX] -w [AIRPORT_CALLSIGN]"
    printf "\t-p: The prefix of your wallpaper folder without a trailing /\n"
    printf "\t-w: Local airport callsign in ICAO [e.g. KSBN], used for both time and weather location \n"
    printf "\t--wal: Use pywal if it's installed\n"
    exit 1
}


# TODO Fine tune this with the actual variables
#if [ $# -eq 0 ]; then
#if [ $# -ne 4 ]; then
	#exit_help
#else

weather="0"
pape_prefix="0"
use_wal=0
embed=0

while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in
        -p)
            pape_prefix="$2"
            shift; shift
            ;;
        -w)
            weather="$2"
            shift; shift
            ;;
        --wal)
            use_wal=1
            shift;
            ;;
        -e)
            embed=1
            shift;
            ;;
        *)
            exit_help "Unrecognized argument"
            ;;
    esac
done

if [[ "$pape_prefix" == "0" ]] || [[ "$weather" == "0" ]]; then
    exit_help "Either the paper prefix or airport code is unset"
fi

get_lat_long "$weather"

url="https://api.sunrise-sunset.org/json?lat=$lat&lng=$lng&date=today&formatted=0"
json=$(curl -s "$url")

get_rise_set_time
get_time_chunk "$sunrise" "$sunset"
get_weather "$weather"

echo "Real Weather: $w_type"
get_simple_weather "$w_type" "$temp"
echo "Time Type: $t_type, Weather Type: $w_type"

if [[ "$t_type" == "Night" ]] && [[ "$w_type" == "Sun" ]]; then
    w_type="Misc"
fi

set_pape "$t_type" "$w_type"
