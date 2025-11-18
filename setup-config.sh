#!/bin/bash

# NaviGPT Configuration Setup Script

echo "🚀 NaviGPT Configuration Setup"
echo "=============================="

# Check if .env.example exists
if [ ! -f ".env.example" ]; then
    echo "❌ Error: .env.example file not found!"
    echo "Make sure you're running this script from the project root directory."
    exit 1
fi

# Create .env file from template if it doesn't exist
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "✅ Created .env file from template"
else
    echo "⚠️  .env file already exists, skipping creation"
fi

# Create Config.plist from template if it doesn't exist
if [ -f "NaviGPT_build_from_here/NaviGPT/Config.plist.example" ]; then
    if [ ! -f "NaviGPT_build_from_here/NaviGPT/Config.plist" ]; then
        cp "NaviGPT_build_from_here/NaviGPT/Config.plist.example" "NaviGPT_build_from_here/NaviGPT/Config.plist"
        echo "✅ Created Config.plist file from template"
    else
        echo "⚠️  Config.plist file already exists, skipping creation"
    fi
fi

echo ""
echo "📝 Next Steps:"
echo "1. Edit the .env file and add your OpenAI API key:"
echo "   OPENAI_API_KEY=your_actual_api_key_here"
echo ""
echo "2. In Xcode, make sure ConfigManager.swift is added to your project"
echo ""
echo "3. If using Config.plist method, add Config.plist to your Xcode project bundle"
echo ""
echo "4. Get your OpenAI API key from: https://platform.openai.com/api-keys"
echo ""
echo "For detailed instructions, see CONFIGURATION_SETUP.md"
echo ""
echo "🔐 Security Note: Never commit .env or Config.plist files to version control!"