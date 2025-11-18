import Foundation
import CoreLocation
import CoreGraphics
import os.log

// MARK: - Configuration Management

/// Centralized configuration management for NaviGPT
/// This consolidates all Phase 1 models and configuration into a single file for easy Xcode integration
class NaviGPTCore {
    static let shared = NaviGPTCore()
    let config: ConfigurationManager
    
    private init() {
        self.config = ConfigurationManager()
    }
}

/// Configuration manager with multi-source support
class ConfigurationManager {
    private var configStore: [String: String] = [:]
    private let logger = Logger(subsystem: "com.navigpt.app", category: "Config")
    
    struct Keys {
        static let openAIAPIKey = "OPENAI_API_KEY"
        static let enableLiDAR = "ENABLE_LIDAR"
        static let enableAdvancedVision = "ENABLE_ADVANCED_VISION"
        static let vibrationEnabled = "VIBRATION_ENABLED"
        static let voiceFeedbackEnabled = "VOICE_FEEDBACK_ENABLED"
        static let debugMode = "DEBUG_MODE"
        static let modelQuality = "MODEL_QUALITY"
        static let maxLLMTokens = "MAX_LLM_TOKENS"
        static let obstacleDetectionDistance = "OBSTACLE_DETECTION_DISTANCE"
    }
    
    init() {
        loadConfiguration()
        setDefaults()
    }
    
    private func loadConfiguration() {
        // Load from .env file
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil) {
            loadFromEnvFile(path: envPath)
        }
        
        // Load from Config.plist
        if let plistPath = Bundle.main.path(forResource: "Config", ofType: "plist") {
            loadFromPlist(path: plistPath)
        }
        
        // Load from environment variables
        loadFromEnvironmentVariables()
    }
    
    private func loadFromEnvFile(path: String) {
        do {
            let content = try String(contentsOfFile: path)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") { continue }
                
                let components = trimmedLine.components(separatedBy: "=")
                if components.count >= 2 {
                    let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = components[1...].joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                    configStore[key] = value
                }
            }
        } catch {
            logger.error("Error reading .env file: \(error.localizedDescription)")
        }
    }
    
    private func loadFromPlist(path: String) {
        if let plistData = NSDictionary(contentsOfFile: path) as? [String: String] {
            for (key, value) in plistData where configStore[key] == nil {
                configStore[key] = value
            }
        }
    }
    
    private func loadFromEnvironmentVariables() {
        let envKeys = [Keys.openAIAPIKey, Keys.enableLiDAR, Keys.enableAdvancedVision, Keys.debugMode, Keys.modelQuality]
        for key in envKeys {
            if let value = ProcessInfo.processInfo.environment[key], configStore[key] == nil {
                configStore[key] = value
            }
        }
    }
    
    private func setDefaults() {
        if configStore[Keys.enableLiDAR] == nil { configStore[Keys.enableLiDAR] = "true" }
        if configStore[Keys.enableAdvancedVision] == nil { configStore[Keys.enableAdvancedVision] = "true" }
        if configStore[Keys.vibrationEnabled] == nil { configStore[Keys.vibrationEnabled] = "true" }
        if configStore[Keys.voiceFeedbackEnabled] == nil { configStore[Keys.voiceFeedbackEnabled] = "true" }
        if configStore[Keys.debugMode] == nil { configStore[Keys.debugMode] = "false" }
        if configStore[Keys.modelQuality] == nil { configStore[Keys.modelQuality] = "medium" }
        if configStore[Keys.maxLLMTokens] == nil { configStore[Keys.maxLLMTokens] = "300" }
        if configStore[Keys.obstacleDetectionDistance] == nil { configStore[Keys.obstacleDetectionDistance] = "3.0" }
    }
    
    func getValue(for key: String) -> String? {
        return configStore[key]
    }
    
    func getBoolValue(for key: String, default defaultValue: Bool = false) -> Bool {
        guard let value = configStore[key] else { return defaultValue }
        return value.lowercased() == "true" || value == "1"
    }
    
    func getIntValue(for key: String, default defaultValue: Int = 0) -> Int {
        guard let value = configStore[key] else { return defaultValue }
        return Int(value) ?? defaultValue
    }
    
    func getDoubleValue(for key: String, default defaultValue: Double = 0.0) -> Double {
        guard let value = configStore[key] else { return defaultValue }
        return Double(value) ?? defaultValue
    }
    
    var openAIAPIKey: String? { getValue(for: Keys.openAIAPIKey) }
    var isLiDAREnabled: Bool { getBoolValue(for: Keys.enableLiDAR, default: true) }
    var isAdvancedVisionEnabled: Bool { getBoolValue(for: Keys.enableAdvancedVision, default: true) }
    var isVibrationEnabled: Bool { getBoolValue(for: Keys.vibrationEnabled, default: true) }
    var isVoiceFeedbackEnabled: Bool { getBoolValue(for: Keys.voiceFeedbackEnabled, default: true) }
    var isDebugMode: Bool { getBoolValue(for: Keys.debugMode, default: false) }
    var maxLLMTokens: Int { getIntValue(for: Keys.maxLLMTokens, default: 300) }
    var obstacleDetectionDistance: Double { getDoubleValue(for: Keys.obstacleDetectionDistance, default: 3.0) }
}

// For backward compatibility
typealias ConfigManager = ConfigurationManager
extension ConfigManager {
    static var shared: ConfigManager {
        return NaviGPTCore.shared.config
    }
}

// MARK: - Model Quality

enum ModelQuality: String {
    case low, medium, high
    
    var description: String {
        switch self {
        case .low: return "Low (faster, less accurate)"
        case .medium: return "Medium (balanced)"
        case .high: return "High (slower, more accurate)"
        }
    }
}
