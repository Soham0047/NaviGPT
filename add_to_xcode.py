#!/usr/bin/env python3
"""
Script to add new Swift files to Xcode project
"""

import sys
import subprocess
import os

# Files to add
files_to_add = [
    'NaviGPT/NaviGPTCore.swift'
]

project_dir = '/Users/sohambhowmick/Desktop/NaviGPT/NaviGPT-main/NaviGPT_build_from_here'
project_file = os.path.join(project_dir, 'NaviGPT.xcodeproj/project.pbxproj')

def add_file_manually():
    """Add file using PlistBuddy and manual UUID generation"""
    import uuid
    
    # Read current project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Generate UUIDs for new entries
    file_ref_uuid = str(uuid.uuid4()).replace('-', '')[:24].upper()
    build_file_uuid = str(uuid.uuid4()).replace('-', '')[:24].upper()
    
    # Find the PBXBuildFile section
    pbx_build_file_section = content.find('/* Begin PBXBuildFile section */')
    if pbx_build_file_section == -1:
        print("Error: Could not find PBXBuildFile section")
        return False
    
    # Add new PBXBuildFile entry
    new_build_file = f"\t\t{build_file_uuid} /* NaviGPTCore.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* NaviGPTCore.swift */; }};\n"
    
    # Find where to insert (after section header)
    insert_pos = content.find('\n', pbx_build_file_section) + 1
    content = content[:insert_pos] + new_build_file + content[insert_pos:]
    
    # Find PBXFileReference section
    file_ref_section = content.find('/* Begin PBXFileReference section */')
    if file_ref_section == -1:
        print("Error: Could not find PBXFileReference section")
        return False
    
    # Add new PBXFileReference entry
    new_file_ref = f"\t\t{file_ref_uuid} /* NaviGPTCore.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NaviGPTCore.swift; sourceTree = \"<group>\"; }};\n"
    
    insert_pos = content.find('\n', file_ref_section) + 1
    content = content[:insert_pos] + new_file_ref + content[insert_pos:]
    
    # Find the NaviGPT group's children array
    # Search for the group containing other Swift files
    navigpt_group_pattern = 'children = ('
    # Look for the main NaviGPT folder group
    
    # First, let's find the group with ContentView.swift to know where to add
    content_view_pos = content.find('ContentView.swift')
    if content_view_pos != -1:
        # Backtrack to find the children array containing this file
        search_start = content.rfind('children = (', 0, content_view_pos)
        if search_start != -1:
            # Find the closing of this children array
            children_end = content.find(');', search_start)
            # Add our file reference before the closing
            content = content[:children_end] + f"\t\t\t\t{file_ref_uuid} /* NaviGPTCore.swift */,\n\t\t\t" + content[children_end:]
    
    # Find PBXSourcesBuildPhase section
    sources_phase = content.find('/* Sources */ = {')
    if sources_phase != -1:
        # Find the files array in this section
        files_start = content.find('files = (', sources_phase)
        if files_start != -1:
            files_end = content.find(');', files_start)
            # Add our build file reference
            content = content[:files_end] + f"\t\t\t\t{build_file_uuid} /* NaviGPTCore.swift in Sources */,\n\t\t\t" + content[files_end:]
    
    # Write back
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"Successfully added NaviGPTCore.swift to project")
    print(f"  File Reference UUID: {file_ref_uuid}")
    print(f"  Build File UUID: {build_file_uuid}")
    return True

if __name__ == '__main__':
    print("Adding NaviGPTCore.swift to Xcode project...")
    success = add_file_manually()
    if success:
        print("\n✅ File added successfully!")
        print("You may need to clean and rebuild the project in Xcode.")
        sys.exit(0)
    else:
        print("\n❌ Failed to add file")
        sys.exit(1)
