repeat
	if application "CoreServicesUIAgent" is running then
		tell application "System Events" to tell process "CoreServicesUIAgent"
			if exists (button "OK" of window 1) then
				click (button "OK" of window 1)
			end if
		end tell
	end if
	delay 1
end repeat
