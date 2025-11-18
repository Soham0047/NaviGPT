import XCTest
@testable import NaviGPT

final class ConfigManagerTests: XCTestCase {
    
    var configManager: ConfigManager!
    
    override func setUpWithError() throws {
        configManager = ConfigManager.shared
    }
    
    override func tearDownWithError() throws {
        configManager = nil
    }
    
    // MARK: - Default Values Tests
    
    func testDefaultConfigurationValues() {
        // Test that defaults are properly set
        XCTAssertTrue(configManager.isLiDAREnabled, "LiDAR should be enabled by default")
        XCTAssertTrue(configManager.isAdvancedVisionEnabled, "Advanced vision should be enabled by default")
        XCTAssertTrue(configManager.isVibrationEnabled, "Vibration should be enabled by default")
        XCTAssertTrue(configManager.isVoiceFeedbackEnabled, "Voice feedback should be enabled by default")
        XCTAssertFalse(configManager.isDebugMode, "Debug mode should be disabled by default")
    }
    
    func testModelQualityDefault() {
        XCTAssertEqual(configManager.modelQuality, .medium, "Model quality should default to medium")
    }
    
    func testMaxLLMTokensDefault() {
        XCTAssertEqual(configManager.maxLLMTokens, 300, "Max LLM tokens should default to 300")
    }
    
    func testObstacleDetectionDistanceDefault() {
        XCTAssertEqual(configManager.obstacleDetectionDistance, 3.0, accuracy: 0.01, "Obstacle detection distance should default to 3.0")
    }
    
    // MARK: - Boolean Value Tests
    
    func testGetBoolValueWithTrueString() {
        configManager.updateValue("true", for: "TEST_BOOL")
        XCTAssertTrue(configManager.getBoolValue(for: "TEST_BOOL"))
    }
    
    func testGetBoolValueWithFalseString() {
        configManager.updateValue("false", for: "TEST_BOOL")
        XCTAssertFalse(configManager.getBoolValue(for: "TEST_BOOL"))
    }
    
    func testGetBoolValueWithNumericOne() {
        configManager.updateValue("1", for: "TEST_BOOL")
        XCTAssertTrue(configManager.getBoolValue(for: "TEST_BOOL"))
    }
    
    func testGetBoolValueWithNumericZero() {
        configManager.updateValue("0", for: "TEST_BOOL")
        XCTAssertFalse(configManager.getBoolValue(for: "TEST_BOOL"))
    }
    
    func testGetBoolValueWithDefault() {
        XCTAssertFalse(configManager.getBoolValue(for: "NONEXISTENT_KEY", default: false))
        XCTAssertTrue(configManager.getBoolValue(for: "NONEXISTENT_KEY", default: true))
    }
    
    // MARK: - Integer Value Tests
    
    func testGetIntValueValid() {
        configManager.updateValue("42", for: "TEST_INT")
        XCTAssertEqual(configManager.getIntValue(for: "TEST_INT"), 42)
    }
    
    func testGetIntValueInvalid() {
        configManager.updateValue("not_a_number", for: "TEST_INT")
        XCTAssertEqual(configManager.getIntValue(for: "TEST_INT", default: 10), 10)
    }
    
    func testGetIntValueWithDefault() {
        XCTAssertEqual(configManager.getIntValue(for: "NONEXISTENT_KEY", default: 100), 100)
    }
    
    // MARK: - Double Value Tests
    
    func testGetDoubleValueValid() {
        configManager.updateValue("3.14", for: "TEST_DOUBLE")
        XCTAssertEqual(configManager.getDoubleValue(for: "TEST_DOUBLE"), 3.14, accuracy: 0.001)
    }
    
    func testGetDoubleValueInvalid() {
        configManager.updateValue("not_a_number", for: "TEST_DOUBLE")
        XCTAssertEqual(configManager.getDoubleValue(for: "TEST_DOUBLE", default: 2.5), 2.5, accuracy: 0.001)
    }
    
    func testGetDoubleValueWithDefault() {
        XCTAssertEqual(configManager.getDoubleValue(for: "NONEXISTENT_KEY", default: 1.5), 1.5, accuracy: 0.001)
    }
    
    // MARK: - Update Value Tests
    
    func testUpdateValue() {
        configManager.updateValue("new_value", for: "TEST_KEY")
        XCTAssertEqual(configManager.getValue(for: "TEST_KEY"), "new_value")
    }
    
    func testUpdateExistingValue() {
        configManager.updateValue("initial_value", for: "TEST_KEY")
        configManager.updateValue("updated_value", for: "TEST_KEY")
        XCTAssertEqual(configManager.getValue(for: "TEST_KEY"), "updated_value")
    }
    
    // MARK: - Model Quality Tests
    
    func testModelQualityLow() {
        configManager.updateValue("low", for: ConfigManager.Keys.modelQuality)
        XCTAssertEqual(configManager.modelQuality, .low)
    }
    
    func testModelQualityMedium() {
        configManager.updateValue("medium", for: ConfigManager.Keys.modelQuality)
        XCTAssertEqual(configManager.modelQuality, .medium)
    }
    
    func testModelQualityHigh() {
        configManager.updateValue("high", for: ConfigManager.Keys.modelQuality)
        XCTAssertEqual(configManager.modelQuality, .high)
    }
    
    func testModelQualityInvalid() {
        configManager.updateValue("invalid", for: ConfigManager.Keys.modelQuality)
        XCTAssertEqual(configManager.modelQuality, .medium, "Should default to medium for invalid values")
    }
    
    // MARK: - Performance Tests
    
    func testGetValuePerformance() {
        measure {
            for _ in 0..<1000 {
                _ = configManager.getValue(for: ConfigManager.Keys.openAIAPIKey)
            }
        }
    }
    
    func testUpdateValuePerformance() {
        measure {
            for i in 0..<100 {
                configManager.updateValue("value_\(i)", for: "PERF_TEST_KEY")
            }
        }
    }
}

// MARK: - ModelQuality Tests

final class ModelQualityTests: XCTestCase {
    
    func testModelQualityRawValues() {
        XCTAssertEqual(ModelQuality.low.rawValue, "low")
        XCTAssertEqual(ModelQuality.medium.rawValue, "medium")
        XCTAssertEqual(ModelQuality.high.rawValue, "high")
    }
    
    func testModelQualityDescription() {
        XCTAssertFalse(ModelQuality.low.description.isEmpty)
        XCTAssertFalse(ModelQuality.medium.description.isEmpty)
        XCTAssertFalse(ModelQuality.high.description.isEmpty)
    }
    
    func testModelQualityInitFromRawValue() {
        XCTAssertEqual(ModelQuality(rawValue: "low"), .low)
        XCTAssertEqual(ModelQuality(rawValue: "medium"), .medium)
        XCTAssertEqual(ModelQuality(rawValue: "high"), .high)
        XCTAssertNil(ModelQuality(rawValue: "invalid"))
    }
}
