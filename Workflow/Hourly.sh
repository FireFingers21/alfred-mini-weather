#!/bin/zsh --no-rcs

[[ "$(jq '.items[].error' <<< ${weather})" == "1" ]] && echo "${weather}" && exit

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

jq --argjson iconArr "${iconArr}" \
   --argjson iconDict "${iconDict}" \
   --argjson nightDict "${nightDict}" \
'.[] | (.condition, .temp, .feelsLike, .hours12, .hours24, .pChance) |= split("\n") |
    .current as $current | .current |= empty |
    [ to_entries[] | [.value[]] ] | transpose |
    { items: map({
        "title": "\( (.[3] | sub("(?<x>1.*)";"\(.x) ")))        \(.[1])",
        "subtitle": (
            "☂ "+((.[5]|sub(",";".")|tonumber*100|floor|tostring) | .+"%"+(3-length)*"  ") +
            (" "*13)+"Feels like: "+(.[2] | .+(5-length)*" ") +
            (" "*8)+.[0]
        ),
        "valid": false,
        "icon": {
            "path": (
                (($iconDict[].[.[0]] | select(. != null)) // .[0]) as $equivIcon |
                (($nightDict[] | select(. == $equivIcon) | true) // false) as $iconHasNight |
                ( ((.[4] | tonumber) <= ($current[6] | tonumber)) or ((.[4] | tonumber) > ($current[8] | tonumber)) ) as $isNightTime |
                (if ($iconHasNight and $isNightTime) then $equivIcon+" (night)" else $equivIcon end) as $equivIconNight |
                "images/\(if ($iconArr | index($equivIcon)) then $equivIconNight else "66BBFF" end).png"
            )
        }
    })} | [
      {
        "title": "\($current[2]) \($current[3]), \($current[4])",
        "subtitle": "H:\($current[0])  L:\($current[1])        ☀︎ \($current[5])    ☾ \($current[7])",
        "valid": false,
        "icon": { "path": "images/Location.png" }
      }
    ] + .items | .[1].title |= sub(.[0:5]; "Now   ") | { "items": . }
' <<< "${weather// /}"