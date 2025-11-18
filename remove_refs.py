#!/usr/bin/env python3
"""
Remove NaviGPTCore.swift references from Xcode project
"""

import sys
import os

project_file = '/Users/sohambhowmick/Desktop/NaviGPT/NaviGPT-main/NaviGPT_build_from_here/NaviGPT.xcodeproj/project.pbxproj'

# Read current project file
with open(project_file, 'r') as f:
    content = f.read()

# Remove NaviGPTCore.swift references
lines = content.split('\n')
new_lines = []

for line in lines:
    # Skip lines containing NaviGPTCore.swift
    if 'NaviGPTCore.swift' not in line:
        new_lines.append(line)

content = '\n'.join(new_lines)

# Write back
with open(project_file, 'w') as f:
    f.write(content)

print("✅ Removed NaviGPTCore.swift references from project")
