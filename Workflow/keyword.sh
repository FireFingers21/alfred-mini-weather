#!/bin/zsh --no-rcs

# Cache version check
readonly version_file="${alfred_workflow_cache}/Version.json"
if [[ "$(< ${version_file})" != "${alfred_workflow_version}" ]]; then
    mkdir -p "${alfred_workflow_cache}"
    scVersion="$(shortcuts run "Mini Weather" <<< "Version" > "${version_file}")"
fi

# Check if Shortcut is installed and up to date
scVersion="$(< ${version_file})"
if [[ -z "${scVersion}" ]]; then
    jq -cn '{"items":[{"title":"Missing Mini Weather Shortcut","subtitle":"Press ↩ to install it","arg":"install"}]}'
    exit
elif [[ "${scVersion}" != "${alfred_workflow_version}" ]]; then
    jq -cn '{"items":[{"title":"Outdated Mini Weather Shortcut","subtitle":"Press ↩ to replace it","arg":"install"}]}'
    exit
else
    # List weather options
    jq -cn '{"items": [
    	{ "title":"Hourly Forecast", "arg":"Hourly" },
    	{ "title":"Daily Forecast", "arg":"Daily" }
    ]}'
fi