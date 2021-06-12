#!/bin/bash

[[ "$(uname -s)" = "Darwin" ]] && PATH="/usr/local/bin:${PATH}" && export PATH
command -v gdate >/dev/null 2>&1 && date() { command gdate "${@}"; }

get_weather () {
    # weatherdata=$(curl -s "wttr.in/$1?format=j1")
    weatherdata=$(curl -s "wttr.in/?format=j1")

    temp=$(echo "$weatherdata" | jq -r '.current_condition[0].temp_F' )
    w_type=$(echo "$weatherdata" | jq -r '.current_condition[0].weatherDesc[0].value')
    sunrise=$(echo "$weatherdata" | jq -r '.weather[0].astronomy[0].sunrise' | tr -d ":AM[:space:]" | sed 's/^0//')
    sunset=$(echo "$weatherdata" | jq -r '.weather[0].astronomy[0].sunset'| tr -d ":PM[:space:]" | sed 's/^0//')
    sunset=$((sunset + 1200))
}

get_time_chunk () {
    time_day=$(date +%-k%M)

    echo "$sunrise ~ $time_day ~ $sunset"

    t_type="Day"

    if (( time_day < sunrise )); then
        t_type="Night"
    elif (( time_day >= sunrise )) && (( time_day < sunrise + 130 )); then
        t_type="Morning"
    elif (( time_day < sunset - 130 )) && (( time_day > sunrise + 130 )); then
        t_type="Day"
    elif (( time_day > sunset - 100 )) && (( time_day < sunset )); then
        t_type="Evening"
    else
        t_type="Night"
    fi
}

get_simple_weather () {
    echo "Temp: $temp"

    if echo "$w_type" | grep -i -q -E "sun|clear" && (( temp >= 34 )); then
        w_type="Sun"
    elif echo "$w_type" | grep -q -i "snow" || ((temp < 34)); then
        w_type="Snow"
    elif echo "$w_type" | grep -i -q -E "rain|overcast|Light drizzle"; then
        w_type="Rain"
    else
        echo "Misc";
    fi
}


set_pape () {
    if ! pape=$(find "$pape_prefix"/"$t_type"/"$w_type"/* "$pape_prefix"/"$t_type"/Misc/* | shuf -n 1); then
        pape=$(find "$pape_prefix"/"$t_type"/* | shuf -n 1)
    fi


    if [[ $embed -eq 1 ]]; then
        if which osascript; then
            res=$(/usr/sbin/system_profiler SPDisplaysDataType | grep Resolution | awk '{print $2, $4}' | tr " " "x")
        else
            pos_res=$(xrandr | grep \ connected | awk '{if ($3 == "primary") {print $4} else {print $3} }' | cut -f 1 -d '+')
            res=$(echo "$pos_res" | head -n 1)
        fi

        echo "Res: $res"
        convert "$pape" -resize "$res" resized_pape.png
        pape="resized_pape.png"

        rm embed_pape_*
        convert <( curl -s "wttr.in/_tqp0.png" ) weather_report.png
        convert "$pape" "weather_report.png" -gravity center -geometry +0+0 -composite "embed_pape.png"
        stamped_pape="embed_pape_$(date +%T).png"
        cp embed_pape.png "$stamped_pape"
        pape="$stamped_pape"
    fi

    if which osascript; then
        rm ~/Pictures/Weather\ Wallpaper/*.png
        cp "$pape" ~/Pictures/Weather\ Wallpaper/
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

    rm weather_report.png
    rm resized_pape.png
}

exit_help () {
    echo "ERROR: $1"
    echo "USAGE: dynamicWallpaper -p [PAPER_PREFIX] -w [AIRPORT_CALLSIGN]"
    printf "\t-p: The prefix of your wallpaper folder without a trailing /\n"
    printf "\t-e: Embed a little weather preview png in the wallpaper\n"
    printf "\t--iata: Local airport callsign in IATA [e.g. SBN], used for the time parameters\n"
    printf "\t--zip: If you're in the US and at some distance from an airport, use your zipcode instead\n"
    printf "\t--wal: Use pywal if it's installed\n"
    exit 1
}

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

if [[ "$pape_prefix" == "0" ]]; then
    exit_help "Either the paper prefix or airport code is unset"
fi

get_weather
get_time_chunk

echo "Real Weather: $w_type"
get_simple_weather
echo "Time Type: $t_type, Weather Type: $w_type"

if [[ "$t_type" == "Night" ]] && [[ "$w_type" == "Sun" ]]; then
    w_type="Misc"
fi

set_pape
