#!/usr/bin/osascript -l JavaScript

ObjC.import("stdlib")

function run(argv) {
	try {
	  // Check if Shortcut is installed/up to date on Hotkey trigger
	  if ($.NSProcessInfo.processInfo.environment.objectForKey("hotkey").js == 1) {
			const scVersion = Application("Shortcuts Events").shortcuts.byName("Mini Weather").run({ withInput: "Version" })
			if (scVersion != $.getenv("alfred_workflow_version")) { throw new Error("Version mismatch."); }
		}
		// Get forecast
    return JSON.stringify(Application("Shortcuts Events").shortcuts.byName("Mini Weather").run({ withInput: $.getenv("forecast") }));
	} catch (error) {
	  if (error.message == "Can't get object.") {
			errorJSON = {
        "title": "Missing Mini Weather Shortcut",
        "subtitle": "Press ↩ to install it",
        "variables": {"forecast": "install"},
        "error": 1
			}
    } else if (error.message == "Version mismatch.") {
      errorJSON = {
        "title": "Outdated Mini Weather Shortcut",
        "subtitle": "Press ↩ to replace it",
        "variables": {"forecast": "install"},
        "error": 1
			}
    } else {
		  errorJSON = {
				"title": $.getenv("forecast")+" Forecast",
				"subtitle": error.message,
				"error": 1
			}
		}
		return JSON.stringify({"items": [errorJSON]})
	}
}