#!/usr/bin/env python3
"""
Fix the path for NaviGPTCore.swift in the Xcode project
"""

import sys
import os

project_file = '/Users/sohambhowmick/Desktop/NaviGPT/NaviGPT-main/NaviGPT_build_from_here/NaviGPT.xcodeproj/project.pbxproj'

# Read current project file
with open(project_file, 'r') as f:
    content = f.read()

# Fix the path - it should be relative to the NaviGPT directory
# Replace the absolute path with just the filename
content = content.replace(
    'path = NaviGPTCore.swift;',
    'path = NaviGPTCore.swift;'
)

# Actually, let's look for the NaviGPTCore.swift reference and see what's there
if 'NaviGPTCore.swift' in content:
    print("Found NaviGPTCore.swift references in project file")
    
    # Find the file reference entry
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if 'NaviGPTCore.swift' in line:
            print(f"Line {i}: {line}")

with open(project_file, 'w') as f:
    f.write(content)

print("Project file checked/updated")
