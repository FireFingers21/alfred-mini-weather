#!/bin/zsh --no-rcs

# Check if Shortcut is installed and up to date
if [[ -z "${loading}" ]]; then
    scOutput="$(shortcuts run "Mini Weather" <<< "Version" | cat)"
    if [[ -z "${scOutput}" ]]; then
        title="Missing Mini Weather Shortcut"
        subtitle="Press ↩ to install it"
        action="install"
    elif [[ "${scOutput}" != "${alfred_workflow_version}" ]]; then
        title="Outdated Mini Weather Shortcut"
        subtitle="Press ↩ to replace it"
        action="install"
    fi
fi

# List weather options
cat << EOB
{"variables": { "loading": 0 },
"items": [
	{
		"title": "${title:=${forecast:=Hourly} Forecast}",
		"subtitle": "${subtitle:=${loading:+Loading...}}",
		"arg": "",
		"valid": "${${loading///true}/true0/0}",
		"variables": { "forecast": "${action:=${forecast}}" }
	},
	{
		"title": "${${loading:=${${forecast/Hourly/Daily Forecast}:#Daily}}:#0}",
		"arg": "",
		"variables": { "forecast": "Daily" }
	}
]}
EOB