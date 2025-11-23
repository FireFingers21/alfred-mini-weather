#!/bin/zsh --no-rcs

readonly weather_file="${alfred_workflow_cache}/Daily.json"

# Cache forecast, refreshing every 10 mins or every new hour
if [[ ! -f "${weather_file}" ]] || [[ -f "${weather_file}" && ( "$(date -r "${weather_file}" +%s)" -lt "$(date -v -10M +%s)" || "$(date -r "${weather_file}" +%H)" -ne "$(date +%H)" ) ]]; then
    mkdir -p "${alfred_workflow_cache}"
    weather=$({shortcuts run "Mini Weather" <<< "Daily" | cat} 2>&1)
else
    weather=$(< "${weather_file}") && cached=true
fi

# Validate uncached forecast
if [[ ! "${cached}" ]]; then
    if [[ "${weather}" == *"Couldn’t find shortcut"* ]]; then
        jq -cn '{"items":[{"title":"Missing Mini Weather Shortcut","subtitle":"Press ↩ to install it","arg":"install"}]}'
        exit
    elif [[ "${weather}" == "Error"* ]]; then
        jq -cn '{"items":[{"title":"Daily Forecast","subtitle":"'${weather}'","arg":"install"}]}'
        exit
    elif [[ "${weather}" != *"\"version\":\"${alfred_workflow_version}\""* ]]; then
        jq -cn '{"items":[{"title":"Outdated Mini Weather Shortcut","subtitle":"Press ↩ to replace it","arg":"install"}]}'
        exit
    else
        echo -nE "${weather// /}" > "${weather_file}"
    fi
fi

# UI Dictionaries
iconArr='["Clear","Partly Cloudy","Haze","Fog","Windy","Cloudy","Thunderstorm","Rain","Heavy Rain","Drizzle","Snow","Heavy Snow","Freezing Rain"]'
iconDict='[
    {"Mostly Clear": "Clear"},
    {"Breezy": "Windy"},
    {"Mostly Cloudy": "Cloudy"},
    {"Freezing Drizzle": "Drizzle"},
    {"Blizzard": "Heavy Snow"},
    {"Sleet": "Freezing Rain"},
    {"Wintry Mix": "Freezing Rain"},
    {"Mostly Clear (night)": "Clear (night)"}
]'
spaceDict='[ {"Sunday": 8},{"Monday": 7},{"Tuesday": 6},{"Wednesday": 0},{"Thursday": 4},{"Friday": 10},{"Saturday": 5} ]'

# Display Forecast
jq --argjson iconArr "${iconArr}" \
   --argjson iconDict "${iconDict}" \
   --argjson spaceDict "${spaceDict}" \
'(.condition, .day, .high, .low, .pAmount, .pChance, .sunrise, .sunset) |= split("\n") |
    .current as $current | (.current, .version) |= empty |
    [ (to_entries | sort_by(.key))[] | .value ] | transpose |
    { items: map({
        "title": "\(.[1]|tonumber-1 | $spaceDict[.] | (keys|join(""))+(.[]*" ") )      \("H:"+.[2][0:-2]+" / L:"+.[3][0:-2]+" "+.[3][-2:])",
        "subtitle": (
            "☂ "+((.[5]|sub(",";".")|tonumber*100|floor|tostring) | .+"%"+(3-length)*"  ") +
            ((.[4][:-3]|sub(",";".")|tonumber|round|tostring+"mm") | .+(5-length)*"  ") +
            ((" "*13) + (.[0] | sub("(?<x> .*)";"\(.x)  ")+(13-length)*"  ")) +
            (" "*12) + ("☀︎ "+.[6] + "    ☾ "+.[7])
        ),
        "valid": false,
        "icon": {
            "path": (
                (($iconDict[].[.[0]] | select(. != null)) // .[0]) as $equivIcon |
                "images/\(if ($iconArr | index($equivIcon)) then $equivIcon else "77CCFF" end).png"
            )
        }
    })} | [{
        "title": "\($current[0]) \($current[1]), \($current[2])",
        "subtitle": "Currently: \($current[3]) (Feels like: \($current[4]))    \($current[5])",
        "valid": false,
        "icon": { "path": "images/Location.png" }
    }] + .items | .[1].title |= sub(".*(?<!H)  "; "Today                ") | { "items": . }
' "${weather_file}"