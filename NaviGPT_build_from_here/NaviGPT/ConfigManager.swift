import Foundation

class ConfigManager {
    static let shared = ConfigManager()
    
    private var config: [String: String] = [:]
    
    private init() {
        loadConfiguration()
    }
    
    private func loadConfiguration() {
        // First try to load from .env file in the bundle
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil) {
            loadFromEnvFile(path: envPath)
        }
        
        // Also check for Config.plist as fallback
        if let plistPath = Bundle.main.path(forResource: "Config", ofType: "plist") {
            loadFromPlist(path: plistPath)
        }
        
        // Load from environment variables (useful for CI/CD)
        loadFromEnvironmentVariables()
    }
    
    private func loadFromEnvFile(path: String) {
        do {
            let content = try String(contentsOfFile: path)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip empty lines and comments
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                // Parse key=value pairs
                let components = trimmedLine.components(separatedBy: "=")
                if components.count == 2 {
                    let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    config[key] = value
                }
            }
        } catch {
            print("Error reading .env file: \(error)")
        }
    }
    
    private func loadFromPlist(path: String) {
        if let plistData = NSDictionary(contentsOfFile: path) as? [String: String] {
            for (key, value) in plistData {
                // Don't override values from .env file
                if config[key] == nil {
                    config[key] = value
                }
            }
        }
    }
    
    private func loadFromEnvironmentVariables() {
        // Load common environment variables
        let envKeys = ["OPENAI_API_KEY", "DATABASE_URL", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"]
        
        for key in envKeys {
            if let value = ProcessInfo.processInfo.environment[key] {
                config[key] = value
            }
        }
    }
    
    func getValue(for key: String) -> String? {
        return config[key]
    }
    
    func getOpenAIAPIKey() -> String? {
        return getValue(for: "OPENAI_API_KEY")
    }
    
    // Add other specific getters as needed
    func getDatabaseURL() -> String? {
        return getValue(for: "DATABASE_URL")
    }
}