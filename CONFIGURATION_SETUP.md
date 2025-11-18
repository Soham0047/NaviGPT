# NaviGPT Configuration Setup

This project uses environment variables to store sensitive information like API keys. Follow these steps to set up your configuration:

## Method 1: Using .env file (Recommended for development)

1. Copy the `.env.example` file to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file and replace `your_openai_api_key_here` with your actual OpenAI API key:
   ```
   OPENAI_API_KEY=sk-proj-your-actual-api-key-here
   ```

## Method 2: Using Config.plist (Alternative method)

1. Copy the `Config.plist.example` file to `Config.plist`:
   ```bash
   cp Config.plist.example Config.plist
   ```

2. Edit the `Config.plist` file and replace the placeholder values with your actual API keys.

3. Make sure to add `Config.plist` to your Xcode project if you choose this method.

## Method 3: Using Environment Variables (Production/CI-CD)

Set environment variables directly in your system or CI/CD pipeline:
```bash
export OPENAI_API_KEY=your_actual_api_key_here
```

## Adding ConfigManager to Xcode Project

If you're setting up this project in Xcode, make sure to:

1. Add `ConfigManager.swift` to your Xcode project:
   - Right-click on the NaviGPT folder in Xcode
   - Select "Add Files to 'NaviGPT'"
   - Choose `ConfigManager.swift`

2. If using the Config.plist method, also add `Config.plist` to your project bundle.

## Security Notes

- **Never commit your `.env` or `Config.plist` files** to version control
- The `.gitignore` file is already configured to ignore these files
- Use the `.example` files as templates for other developers
- For production deployments, use secure environment variable management

## Getting Your OpenAI API Key

1. Go to [OpenAI API Platform](https://platform.openai.com/)
2. Sign in to your account
3. Navigate to API Keys section
4. Create a new secret key
5. Copy the key and use it in your configuration

## Troubleshooting

If you see the warning "OpenAI API key not found" in the console:
- Check that your `.env` file exists and contains the correct API key
- Verify that `Config.plist` has the right key if using that method
- Ensure the ConfigManager.swift file is included in your Xcode project

## Project Structure

```
NaviGPT/
├── .env.example          # Template for environment variables
├── .env                  # Your actual environment variables (ignored by git)
├── .gitignore           # Configured to ignore sensitive files
├── NaviGPT_build_from_here/
│   └── NaviGPT/
│       ├── ConfigManager.swift     # Configuration management
│       ├── Config.plist.example    # Template for plist configuration
│       ├── Config.plist           # Your actual plist config (ignored by git)
│       └── llmManager.swift       # Updated to use ConfigManager
```