tell application "Xcode"
	activate
	delay 2
	
	tell application "System Events"
		tell process "Xcode"
			-- Select NaviGPT folder in Project Navigator
			keystroke "1" using {command down}
			delay 1
			
			-- Add files
			keystroke "a" using {option down, command down}
			delay 2
			
			-- In file dialog, type the path
			keystroke "g" using {shift down, command down}
			delay 1
			
			keystroke "/Users/sohambhowmick/Desktop/NaviGPT/NaviGPT-main/NaviGPT_build_from_here/NaviGPT/NaviGPTCore.swift"
			delay 1
			
			keystroke return
			delay 1
			
			-- Click Add button
			click button "Add" of sheet 1 of window 1
		end tell
	end tell
end tell
