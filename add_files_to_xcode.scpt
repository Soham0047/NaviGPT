#!/usr/bin/osascript

# AppleScript to add files to Xcode project
# This script opens Xcode and adds the necessary files

tell application "Xcode"
    activate
    
    set projectPath to "/Users/sohambhowmick/Desktop/NaviGPT/NaviGPT-main/NaviGPT_build_from_here/NaviGPT.xcodeproj"
    open projectPath
    
    delay 2
    
    display dialog "Please manually add the following files to the NaviGPT target:

1. ConfigManager.swift
2. Models/ObstacleInfo.swift
3. Models/NavigationContext.swift
4. Models/VisionModels.swift

Add tests to NaviGPTTests target:
1. Tests/ConfigManagerTests.swift
2. Tests/ObstacleInfoTests.swift

Then rebuild the project." buttons {"OK"} default button "OK"
end tell
