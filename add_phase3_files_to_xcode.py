#!/usr/bin/env python3
"""
Script to add Phase 3 Swift files to Xcode project
"""

import sys
import os
import uuid

# Get the project directory dynamically
script_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = os.path.join(script_dir, 'NaviGPT_build_from_here')
project_file = os.path.join(project_dir, 'NaviGPT.xcodeproj/project.pbxproj')

# Files to add to main target (NaviGPT)
main_target_files = [
    ('NaviGPT/Services/RealTimeCameraProcessor.swift', 'RealTimeCameraProcessor.swift'),
    ('NaviGPT/Services/EnhancedLiDARProcessor.swift', 'EnhancedLiDARProcessor.swift'),
]

def generate_uuid():
    """Generate a UUID in Xcode format (24 uppercase hex chars)"""
    return str(uuid.uuid4()).replace('-', '')[:24].upper()

def add_files_to_project():
    """Add all Phase 3 files to the Xcode project"""

    # Read current project file
    print(f"Reading project file: {project_file}")
    with open(project_file, 'r') as f:
        content = f.read()

    # Store UUIDs for all files
    file_uuids = {}

    # Process main target files
    print("\n=== Adding Phase 3 Files ===")
    for file_path, file_name in main_target_files:
        print(f"Processing: {file_name}")

        # Check if file already exists in project
        if file_name in content:
            print(f"  ⚠️  {file_name} already in project, skipping...")
            continue

        file_ref_uuid = generate_uuid()
        build_file_uuid = generate_uuid()
        file_uuids[file_name] = (file_ref_uuid, build_file_uuid, file_path)

        # Add to PBXBuildFile section
        pbx_build_file_section = content.find('/* Begin PBXBuildFile section */')
        insert_pos = content.find('\n', pbx_build_file_section) + 1
        new_build_file = f"\t\t{build_file_uuid} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {file_name} */; }};\n"
        content = content[:insert_pos] + new_build_file + content[insert_pos:]

        # Add to PBXFileReference section
        file_ref_section = content.find('/* Begin PBXFileReference section */')
        insert_pos = content.find('\n', file_ref_section) + 1
        new_file_ref = f"\t\t{file_ref_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = \"<group>\"; }};\n"
        content = content[:insert_pos] + new_file_ref + content[insert_pos:]

        # Add to NaviGPT/Services group's children array
        # Find Services group
        services_group_marker = content.find('/* Services */')
        if services_group_marker != -1:
            # Find the children array for Services group
            search_start = content.rfind('children = (', 0, services_group_marker + 100)
            if search_start != -1:
                children_end = content.find(');', search_start)
                content = content[:children_end] + f"\t\t\t\t{file_ref_uuid} /* {file_name} */,\n\t\t\t" + content[children_end:]
        else:
            # Fall back to adding to main NaviGPT group
            content_view_pos = content.find('ContentView.swift')
            if content_view_pos != -1:
                search_start = content.rfind('children = (', 0, content_view_pos)
                if search_start != -1:
                    children_end = content.find(');', search_start)
                    content = content[:children_end] + f"\t\t\t\t{file_ref_uuid} /* {file_name} */,\n\t\t\t" + content[children_end:]

        # Add to main target's PBXSourcesBuildPhase
        # Find the NaviGPT target's Sources phase
        navigpt_target = content.find('E1F569CB2C501D880010BF96 /* Sources */')
        if navigpt_target != -1:
            files_start = content.find('files = (', navigpt_target)
            files_end = content.find(');', files_start)
            content = content[:files_end] + f"\t\t\t\t{build_file_uuid} /* {file_name} in Sources */,\n\t\t\t" + content[files_end:]

        print(f"  ✅ Added {file_name}")

    # Write back
    print(f"\nWriting updated project file...")
    with open(project_file, 'w') as f:
        f.write(content)

    print("\n" + "="*50)
    print("✅ Successfully added all Phase 3 files!")
    print("="*50)
    print("\nFiles added to NaviGPT target:")
    for path, name in main_target_files:
        print(f"  • {name}")
    print("\n⚠️  You may need to:")
    print("  1. Clean the build folder in Xcode (Shift+Cmd+K)")
    print("  2. Rebuild the project (Cmd+B)")
    print("  3. Verify files appear in Project Navigator")

    return True

if __name__ == '__main__':
    print("="*50)
    print("Adding Phase 3 Files to Xcode Project")
    print("="*50)

    # Verify project file exists
    if not os.path.exists(project_file):
        print(f"\n❌ Error: Project file not found at {project_file}")
        sys.exit(1)

    # Add all files
    try:
        success = add_files_to_project()
        if success:
            sys.exit(0)
        else:
            print("\n❌ Failed to add files")
            sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
