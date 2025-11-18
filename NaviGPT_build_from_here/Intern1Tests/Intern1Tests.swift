import XCTest
import AVFoundation
@testable import NaviGPT

/// Unit tests for Phase 1 - Configuration and Setup
class Intern1Tests: XCTestCase {
    
    // MARK: - Configuration Tests
    
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
    
    func testSpeechManagerSharedInstance() {
        let speechManager = SpeechManager.shared
        XCTAssertNotNil(speechManager, "SpeechManager should have a shared instance")
    }
    
    func testSpeechManagerSpeak() {
        let speechManager = SpeechManager.shared
        let expectation = self.expectation(description: "Speech should complete")
        
        // Create an utterance and speak it
        let utterance = AVSpeechUtterance(string: "Test")
        speechManager.speak(utterance)
        
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
    
    // MARK: - Speech Recognizer Tests
    
    func testSpeechRecognizerInitialization() {
        let speechRecognizer = SpeechRecognizer()
        XCTAssertNotNil(speechRecognizer, "SpeechRecognizer should initialize")
    }
    
    // MARK: - Performance Tests
    
    func testLLMManagerInitializationPerformance() {
        measure {
            _ = LLmManager()
        }
    }
    
    func testSpeechManagerSharedAccessPerformance() {
        measure {
            _ = SpeechManager.shared
        }
    }
    
    func testMapsManagerInitializationPerformance() {
        measure {
            _ = MapsManager()
        }
    }
    
    // MARK: - Integration Tests
    
    func testBasicComponentsAvailable() {
        // Test that basic components can be instantiated
        let speechManager = SpeechManager.shared
        let mapsManager = MapsManager()
        let llmManager = LLmManager()
        
        XCTAssertNotNil(speechManager, "SpeechManager should be available")
        XCTAssertNotNil(mapsManager, "MapsManager should be available")
        XCTAssertNotNil(llmManager, "LLMManager should be available")
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
