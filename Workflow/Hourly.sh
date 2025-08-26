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
nightDict='["Clear","Drizzle","Partly Cloudy"]'
# Background Hex code: #66BBFF

jq -Rn \
   --arg currentWeather "${currentWeather//$'\n'/,}" \
   --argjson iconDict "${iconDict}" \
   --argjson nightDict "${nightDict}" \
'
  ($currentWeather / ",,") as $currWttr | { "items":
    [ inputs
      | . / ","
      | (($iconDict[].[.[3]] | select(. != null)) // .[3]) as $equivIcon
      | (($nightDict[] | select(. == $equivIcon) | true) // false) as $iconHasNight
      | ( ((.[5] | tonumber) <= ($currWttr[6] | tonumber)) or ((.[5] | tonumber) > ($currWttr[8] | tonumber)) ) as $isNightTime
      | {
        "title": "\( (.[4] | sub("(?<x>1.*)";"\(.x) ")))        \(.[0])",
        "subtitle": (
            "☂ "+((.[2]|tonumber)*100 | floor | tostring | .+"%"+(3-length)*"  ") +
            (" "*13)+"Feels like: "+(.[1] | .+(5-length)*" ") +
            (" "*8)+.[3]
        ),
        "valid": false,
        "icon": { "path": "images/\(if ($iconHasNight and $isNightTime) then $equivIcon+" (night)" else $equivIcon end).png" }
      }
    ]
  } | [
    {
      "title": "\($currWttr[2]) \($currWttr[3]), \($currWttr[4])",
      "subtitle": "H:\($currWttr[0])  L:\($currWttr[1])        ☀︎ \($currWttr[5])    ☾ \($currWttr[7])",
      "valid": false,
      "icon": { "path": "images/Location.png" }
    }
  ] + .items | .[1].title |= sub(.[0:5]; "Now   ") | { "items": . }
' <<< "${data}"