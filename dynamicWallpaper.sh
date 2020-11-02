#!/bin/bash
[[ "$(uname -s)" = "Darwin" ]] && PATH="/usr/local/bin:${PATH}"
export PATH
command -v gdate >/dev/null 2>&1 && date() { command gdate "${@}"; }

get_weather () {
    weatherdata=$(curl -s "wttr.in/$1?format=j1")

    temp=$(echo "$weatherdata" | jq -r '.current_condition | .[0] | .FeelsLikeF' )
    w_type=$(echo "$weatherdata" | jq -r '.current_condition | .[0] | .weatherDesc | .[0] | .value')
}

get_lat_long () {
    loc_json=$(curl -s "https://www.airport-data.com/api/ap_info.json?icao=$1")

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


    if which osascript; then
        pape=$(find  "$pape_prefix"/"$t_type"/"$w_type"/* "$pape_prefix"/"$t_type"/Misc/* | shuf -n 1)
        cmd_str="tell application \"System Events\" to tell every desktop to set picture to \"$pape\""
        osascript -e "$cmd_str"
    else
        pape=$(find  "$pape_prefix"/"$t_type"/"$w_type"/* "$pape_prefix"/"$t_type"/Misc/* | shuf -n 1)
    case "$(w)" in
	(*xfce*)
		export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"
        	xfconf-query -c xfce4-desktop -l | \
		grep --color=never last-image | \
		while read -r path; do xfconf-query --channel xfce4-desktop --property "$path" -s "$pape"; done
	;;
	(*cinnamon*)
	# You might find something useful in one of these gists:
	# https://gist.github.com/rawiriblundell/2f4712037b2a06155a02a37878ab0c5a
	# https://gist.github.com/rawiriblundell/7e0a302b0ebfe121fedeedb22f521d87
	:
  	;;
	(*etc*)
	:
	;;

	''|*)
    	# Then as a catch-all, try feh here
    	feh --randomize --bg-fill "$pape"
  	;;
    esac
    fi
}

exit_help () {
    echo "USAGE: dynamicWallpaper -p [PAPER_PREFIX] -w [AIRPORT_CALLSIGN]"
    printf "\t-p: The prefix of your wallpaper folder without a trailing /\n"
    printf "\t-w: Local airport callsign in ICAO [e.g. KSBN], used for both time and weather location \n"
    exit 1
}

weather="0"

# TODO Fine tune this with the actual variables
#if [ $# -eq 0 ]; then
#if [ $# -ne 4 ]; then
	#exit_help
#else
while getopts ":p:w:" opts; do
    case "${opts}" in
        p)
            pape_prefix=${OPTARG}
            ;;
        w)
            weather=${OPTARG}
            ;;
        *)
            exit_help
            ;;
    esac
done
#fi

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
