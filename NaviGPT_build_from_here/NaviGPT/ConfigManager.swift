import Foundation
import os.log

/// Centralized configuration management for NaviGPT
/// Supports multiple configuration sources with priority: .env > Config.plist > Environment Variables
class ConfigManager {
    static let shared = ConfigManager()
    
    private var config: [String: String] = [:]
    private let logger = Logger(subsystem: "com.navigpt.app", category: "ConfigManager")
    
    // MARK: - Configuration Keys
    
    struct Keys {
        static let openAIAPIKey = "OPENAI_API_KEY"
        static let enableLiDAR = "ENABLE_LIDAR"
        static let enableAdvancedVision = "ENABLE_ADVANCED_VISION"
        static let vibrationEnabled = "VIBRATION_ENABLED"
        static let voiceFeedbackEnabled = "VOICE_FEEDBACK_ENABLED"
        static let debugMode = "DEBUG_MODE"
        static let modelQuality = "MODEL_QUALITY" // "high", "medium", "low"
        static let maxLLMTokens = "MAX_LLM_TOKENS"
        static let obstacleDetectionDistance = "OBSTACLE_DETECTION_DISTANCE"
    }
    
    // MARK: - Initialization
    
    private init() {
        loadConfiguration()
        logConfiguration()
    }
    
    // MARK: - Configuration Loading
    
    private func loadConfiguration() {
        // Priority 1: Load from .env file in the bundle
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil) {
            loadFromEnvFile(path: envPath)
        }
        
        // Priority 2: Check for Config.plist as fallback
        if let plistPath = Bundle.main.path(forResource: "Config", ofType: "plist") {
            loadFromPlist(path: plistPath)
        }
        
        // Priority 3: Load from environment variables (useful for CI/CD)
        loadFromEnvironmentVariables()
        
        // Set defaults for missing values
        setDefaults()
    }
    
    private func setDefaults() {
        // Set default values if not configured
        if config[Keys.enableLiDAR] == nil {
            config[Keys.enableLiDAR] = "true"
        }
        if config[Keys.enableAdvancedVision] == nil {
            config[Keys.enableAdvancedVision] = "true"
        }
        if config[Keys.vibrationEnabled] == nil {
            config[Keys.vibrationEnabled] = "true"
        }
        if config[Keys.voiceFeedbackEnabled] == nil {
            config[Keys.voiceFeedbackEnabled] = "true"
        }
        if config[Keys.debugMode] == nil {
            config[Keys.debugMode] = "false"
        }
        if config[Keys.modelQuality] == nil {
            config[Keys.modelQuality] = "medium"
        }
        if config[Keys.maxLLMTokens] == nil {
            config[Keys.maxLLMTokens] = "300"
        }
        if config[Keys.obstacleDetectionDistance] == nil {
            config[Keys.obstacleDetectionDistance] = "3.0"
        }
    }
    
    private func logConfiguration() {
        logger.info("Configuration loaded with \(self.config.count) entries")
        if isDebugMode {
            logger.debug("Configuration keys: \(Array(self.config.keys).joined(separator: ", "))")
        }
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
                if components.count >= 2 {
                    let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = components[1...].joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                    config[key] = value
                }
            }
            logger.info("Loaded configuration from .env file")
        } catch {
            logger.error("Error reading .env file: \(error.localizedDescription)")
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
            logger.info("Loaded configuration from Config.plist")
        }
    }
    
    private func loadFromEnvironmentVariables() {
        // Load common environment variables
        let envKeys = [
            Keys.openAIAPIKey,
            Keys.enableLiDAR,
            Keys.enableAdvancedVision,
            Keys.debugMode,
            Keys.modelQuality
        ]
        
        for key in envKeys {
            if let value = ProcessInfo.processInfo.environment[key], config[key] == nil {
                config[key] = value
            }
        }
    }
    
    // MARK: - Public API
    
    func getValue(for key: String) -> String? {
        return config[key]
    }
    
    func getBoolValue(for key: String, default defaultValue: Bool = false) -> Bool {
        guard let value = config[key] else { return defaultValue }
        return value.lowercased() == "true" || value == "1"
    }
    
    func getIntValue(for key: String, default defaultValue: Int = 0) -> Int {
        guard let value = config[key] else { return defaultValue }
        return Int(value) ?? defaultValue
    }
    
    func getDoubleValue(for key: String, default defaultValue: Double = 0.0) -> Double {
        guard let value = config[key] else { return defaultValue }
        return Double(value) ?? defaultValue
    }
    
    // MARK: - Specific Getters
    
    var openAIAPIKey: String? {
        getValue(for: Keys.openAIAPIKey)
    }
    
    var isLiDAREnabled: Bool {
        getBoolValue(for: Keys.enableLiDAR, default: true)
    }
    
    var isAdvancedVisionEnabled: Bool {
        getBoolValue(for: Keys.enableAdvancedVision, default: true)
    }
    
    var isVibrationEnabled: Bool {
        getBoolValue(for: Keys.vibrationEnabled, default: true)
    }
    
    var isVoiceFeedbackEnabled: Bool {
        getBoolValue(for: Keys.voiceFeedbackEnabled, default: true)
    }
    
    var isDebugMode: Bool {
        getBoolValue(for: Keys.debugMode, default: false)
    }
    
    var modelQuality: ModelQuality {
        let value = getValue(for: Keys.modelQuality)?.lowercased() ?? "medium"
        return ModelQuality(rawValue: value) ?? .medium
    }
    
    var maxLLMTokens: Int {
        getIntValue(for: Keys.maxLLMTokens, default: 300)
    }
    
    var obstacleDetectionDistance: Double {
        getDoubleValue(for: Keys.obstacleDetectionDistance, default: 3.0)
    }
    
    // MARK: - Dynamic Updates
    
    func updateValue(_ value: String, for key: String) {
        config[key] = value
        logger.info("Updated configuration: \(key) = \(value)")
    }
    
    func reset() {
        config.removeAll()
        loadConfiguration()
        logger.info("Configuration reset to defaults")
    }
}

// MARK: - Supporting Types

enum ModelQuality: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var description: String {
        switch self {
        case .low: return "Low (faster, less accurate)"
        case .medium: return "Medium (balanced)"
        case .high: return "High (slower, more accurate)"
        }
    }
}