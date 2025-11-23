#!/bin/zsh --no-rcs

readonly weather_file="${alfred_workflow_cache}/Hourly.json"

# Cache forecast, refreshing every 10 mins or every new hour
if [[ ! -f "${weather_file}" ]] || [[ -f "${weather_file}" && ( "$(date -r "${weather_file}" +%s)" -lt "$(date -v -10M +%s)" || "$(date -r "${weather_file}" +%H)" -ne "$(date +%H)" ) ]]; then
    mkdir -p "${alfred_workflow_cache}"
    weather=$({shortcuts run "Mini Weather" <<< "Hourly" | cat} 2>&1)
else
    weather=$(< "${weather_file}") && cached=true
fi

# Validate uncached forecast
if [[ ! "${cached}" ]]; then
    if [[ "${weather}" == *"Couldn’t find shortcut"* ]]; then
        jq -cn '{"items":[{"title":"Missing Mini Weather Shortcut","subtitle":"Press ↩ to install it","arg":"install"}]}'
        exit
    elif [[ "${weather}" == "Error"* ]]; then
        jq -cn '{"items":[{"title":"Hourly Forecast","subtitle":"'${weather}'","arg":"install"}]}'
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
nightDict='["Clear","Drizzle","Partly Cloudy"]'

# Display Forecast
jq --argjson iconArr "${iconArr}" \
   --argjson iconDict "${iconDict}" \
   --argjson nightDict "${nightDict}" \
'(.condition, .feelsLike, .hours12, .hours24, .pChance, .temp) |= split("\n") |
    .current as $current | (.current, .version) |= empty |
    [ (to_entries | sort_by(.key))[] | .value ] | transpose |
    { items: map({
        "title": "\( (.[2] | sub("(?<x>1.*)";"\(.x) ")))        \(.[5])",
        "subtitle": (
            "☂ "+((.[4]|sub(",";".")|tonumber*100|floor|tostring) | .+"%"+(3-length)*"  ") +
            (" "*13)+"Feels like: "+(.[1] | .+(5-length)*" ") +
            (" "*8)+.[0]
        ),
        "valid": false,
        "icon": {
            "path": (
                (($iconDict[].[.[0]] | select(. != null)) // .[0]) as $equivIcon |
                (($nightDict[] | select(. == $equivIcon) | true) // false) as $iconHasNight |
                ( ((.[3] | gsub("[^0-9]";"") | tonumber) <= ($current[6] | tonumber)) or ((.[3] | gsub("[^0-9]";"") | tonumber) > ($current[8] | tonumber)) ) as $isNightTime |
                (if ($iconHasNight and $isNightTime) then $equivIcon+" (night)" else $equivIcon end) as $equivIconNight |
                "images/\(if ($iconArr | index($equivIcon)) then $equivIconNight else "77CCFF" end).png"
            )
        }
    })} | [{
        "title": "\($current[2]) \($current[3]), \($current[4])",
        "subtitle": "H:\($current[0])  L:\($current[1])        ☀︎ \($current[5])    ☾ \($current[7])",
        "valid": false,
        "icon": { "path": "images/Location.png" }
    }] + .items | .[1].title |= sub(.[0:5]; "Now   ") | { "items": . }
' "${weather_file}"