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
spaceDict='[
    {"Sunday": 8},{"Monday": 7},{"Tuesday": 6},{"Wednesday": 0},{"Thursday": 4},{"Friday": 10},{"Saturday": 5}
]'
dayOfWeek="$(($(date +%w)+1))"

jq --argjson iconArr "${iconArr}" \
   --argjson iconDict "${iconDict}" \
   --argjson spaceDict "${spaceDict}" \
   --arg dayOfWeek "${dayOfWeek}" \
'.[] | (.condition, .day, .high, .low, .pAmount, .pChance, .sunrise, .sunset) |= split("\n") |
    .current as $current | .current |= empty |
    (.day[0] | if (. == $dayOfWeek) then true else false end) as $sundayFirst |
    [ to_entries[] | [.value[]] ] | transpose |
    { items: map({
        "title": "\(.[1]|tonumber-1 | $spaceDict[.] | (keys|join(""))+(.[]*" ") )      \("H:"+.[2][0:-2]+" / L:"+.[3][0:-2]+" "+.[3][-2:])",
        "subtitle": (
            "☂ "+((.[5]|sub(",";".")|tonumber*100|floor|tostring) | .+"%"+(3-length)*"  ") +
            ((.[4][:-3]|sub(",";".")|tonumber|round|tostring+"mm") | .+(5-length)*"  ") +
            ((" "*13) + (.[0] | sub("(?<x> .*)";"\(.x)  ")+(13-length)*"  ")) +
            (" "*12) + ("☀︎ "+.[6] + "    ☾ "+.[7])
        ),
        "valid": false,
        "sundayFirst": "\($sundayFirst)",
        "icon": {
            "path": (
                (($iconDict[].[.[0]] | select(. != null)) // .[0]) as $equivIcon |
                "images/\(if ($iconArr | index($equivIcon)) then $equivIcon else "66BBFF" end).png"
            )
        }
    })} | [
        {
            "title": "\($current[0]) \($current[1]), \($current[2])",
            "subtitle": "Currently: \($current[3]) (Feels like: \($current[4]))    \($current[5])",
            "valid": false,
            "icon": { "path": "images/Location.png" }
        }
    ] + .items | .[1].title |= sub(".*(?<!H)  "; "Today                ") | { "items": . }
' <<< "${weather// /}"