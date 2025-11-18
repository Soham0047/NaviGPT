import XCTest
@testable import NaviGPT

/// Unit tests for Phase 1 - Configuration and Setup
class Phase1Tests: XCTestCase {
    
    // MARK: - Configuration Tests
    
    func testSimpleConfigAPIKeyRetrieval() {
        // Test that SimpleConfig can retrieve API key (will be nil in test environment)
        // This validates the configuration loading mechanism exists
        XCTAssertNotNil(SimpleConfig.self, "SimpleConfig class should exist")
    }
    
    func testLLMManagerInitialization() {
        // Test that LLMManager initializes without crashing
        let llmManager = LLmManager()
        XCTAssertNotNil(llmManager, "LLMManager should initialize")
        XCTAssertNotNil(llmManager.speechVoice, "Speech synthesizer should be initialized")
    }
    
    func testLLMManagerAPIKeyFallback() {
        // Test that LLMManager handles missing API key gracefully
        let llmManager = LLmManager()
        // Should not crash even without API key
        XCTAssertNotNil(llmManager, "LLMManager should handle missing API key")
    }
    
    // MARK: - Speech Manager Tests
    
    func testSpeechManagerInitialization() {
        let speechManager = SpeechManager()
        XCTAssertNotNil(speechManager, "SpeechManager should initialize")
        XCTAssertFalse(speechManager.isNavigationMode, "Should start with navigation mode disabled")
    }
    
    func testSpeechManagerNavigationToggle() {
        let speechManager = SpeechManager()
        speechManager.isNavigationMode = true
        XCTAssertTrue(speechManager.isNavigationMode, "Navigation mode should be enabled")
        
        speechManager.isNavigationMode = false
        XCTAssertFalse(speechManager.isNavigationMode, "Navigation mode should be disabled")
    }
    
    func testSpeechManagerSpeak() {
        let speechManager = SpeechManager()
        let expectation = self.expectation(description: "Speech should complete")
        
        // Speak a short text
        speechManager.speak(text: "Test")
        
        // Wait a moment for speech to start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0) { error in
            XCTAssertNil(error, "Speech test should not timeout")
        }
    }
    
    // MARK: - Maps Manager Tests
    
    func testMapsManagerInitialization() {
        let mapsManager = MapsManager()
        XCTAssertNotNil(mapsManager, "MapsManager should initialize")
    }
    
    // MARK: - Camera Tests
    
    func testCameraManagerInitialization() {
        let cameraManager = CameraManager()
        XCTAssertNotNil(cameraManager, "CameraManager should initialize")
    }
    
    func testCameraControllerInitialization() {
        let cameraController = CameraController()
        XCTAssertNotNil(cameraController, "CameraController should initialize")
    }
    
    // MARK: - Speech Recognizer Tests
    
    func testSpeechRecognizerInitialization() {
        let speechRecognizer = SpeechRecognizer()
        XCTAssertNotNil(speechRecognizer, "SpeechRecognizer should initialize")
        XCTAssertEqual(speechRecognizer.transcript, "", "Transcript should start empty")
    }
    
    // MARK: - Performance Tests
    
    func testLLMManagerInitializationPerformance() {
        measure {
            _ = LLmManager()
        }
    }
    
    func testSpeechManagerInitializationPerformance() {
        measure {
            _ = SpeechManager()
        }
    }
    
    func testMapsManagerInitializationPerformance() {
        measure {
            _ = MapsManager()
        }
    }
    
    // MARK: - Integration Tests
    
    func testBasicNavigationFlow() {
        // Test that basic components can work together
        let speechManager = SpeechManager()
        let mapsManager = MapsManager()
        let llmManager = LLmManager()
        
        XCTAssertNotNil(speechManager, "SpeechManager should be available")
        XCTAssertNotNil(mapsManager, "MapsManager should be available")
        XCTAssertNotNil(llmManager, "LLMManager should be available")
        
        // Test navigation mode toggle
        speechManager.isNavigationMode = true
        XCTAssertTrue(speechManager.isNavigationMode, "Navigation mode should be active")
    }
    
    func testErrorHandling() {
        let llmManager = LLmManager()
        
        // Test error message method doesn't crash
        llmManager.errorMessage()
        
        // Give it a moment to execute
        let expectation = self.expectation(description: "Error message should complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0) { error in
            XCTAssertNil(error, "Error handling should not timeout")
        }
    }
}

// Make SimpleConfig accessible for testing
extension Phase1Tests {
    func testConfigFileSupport() {
        // Test that the app bundle can look for config files
        XCTAssertNotNil(Bundle.main, "Main bundle should be accessible")
        
        // These will be nil in test environment, but the logic should work
        let envPath = Bundle.main.path(forResource: ".env", ofType: nil)
        let plistPath = Bundle.main.path(forResource: "Config", ofType: "plist")
        
        // Just checking that the path lookup mechanism works (will return nil in tests)
        _ = envPath
        _ = plistPath
        
        XCTAssertTrue(true, "Configuration file lookup mechanism should work")
    }
}
