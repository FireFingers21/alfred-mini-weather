#!/bin/zsh --no-rcs

[[ "$(jq '.items[].error' <<< ${weather})" == "1" ]] && echo "${weather}" && exit

weather=$(echo ${weather} | sed 's/, , /\n/g')
data="$(rs -c, -C, -T <<< "${${weather// /}//, /,}")"
currentWeather="$(tail -n 1 <<< "${${weather// /}//, /,}")"
iconDict='[
    {"Mostly Clear": "Clear"},
    {"Breezy": "Windy"},
    {"Mostly Cloudy": "Cloudy"},
    {"Freezing Drizzle": "Drizzle"},
    {"Blizzard": "Heavy snow"},
    {"Sleet": "Freezing Rain"},
    {"Wintry Mix": "Freezing Rain"},
    {"Mostly Clear (night)": "Clear (night)"}
]'
spaceDict='[
    {"Sunday": 8},{"Monday": 7},{"Tuesday": 6},{"Wednesday": 0},{"Thursday": 4},{"Friday": 10},{"Saturday": 5}
]'
# Background Hex code: #66BBFF

jq -Rn \
   --arg currentWeather "${currentWeather//$'\n'/,}" \
   --argjson iconDict "${iconDict}" \
   --argjson spaceDict "${spaceDict}" \
'
  ($currentWeather / ",,") as $currWttr | { "items":
    [ inputs
      | . / ","
      | {
        "title": "\(.[5]+($spaceDict[].[.[5]] | select(. != null)*" "))      \("H:"+.[0][0:-2]+" / L:"+.[1][0:-2]+" "+.[1][-2:])",
        "subtitle": (
            "☂ "+((.[2]|tonumber)*100 | floor | tostring | .+"%"+(3-length)*"  ") +
            ((.[3][:-3]|tonumber|round|tostring+"mm") | .+(5-length)*"  ") +
            ((" "*10) + (.[4] | sub("(?<x> .*)";"\(.x)  ")+(13-length)*"  ")) +
            (" "*12) + ("☀︎ "+.[6] + "    ☾ "+.[7])
        ),
        "valid": false,
        "icon": { "path": "images/\(($iconDict[].[.[4]] | select(. != null)) // .[4]).png" }
      }
    ]
  } | [
    {
      "title": "\($currWttr[0]) \($currWttr[1]), \($currWttr[2])",
      "subtitle": "Currently: \($currWttr[3]) (Feels like: \($currWttr[4]))    \($currWttr[5])",
      "valid": false,
      "icon": { "path": "images/Location.png" }
    }
  ] + .items | .[1].title |= sub(".*(?<!H)  "; "Today                ") | { "items": . }
' <<< "${data}"