on run argv
	set x to 0
	set argv_count to count of argv
	if argv_count is not equal to 1 then
		return "Usage: osascript close-security-issue-popups.applescript <popup-count-data-file-path>. \nPass exactly one file path argument to the apple script"
	end if
	set count_file to item 1 of argv
	repeat
		if application "CoreServicesUIAgent" is running then
			tell application "System Events" to tell process "CoreServicesUIAgent"
				if exists (button "OK" of window 1) then
					set x to x + 1
					do shell script "echo " & x & " > " & count_file
					click (button "OK" of window 1)
				end if
			end tell
		end if
		delay 1
	end repeat
end run
