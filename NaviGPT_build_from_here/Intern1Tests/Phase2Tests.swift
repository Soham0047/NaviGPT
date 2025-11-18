//
//  Phase2Tests.swift
//  NaviGPTTests
//
//  Created by NaviGPT Team on 11/17/25.
//  Unit tests for CoreML model integration layer
//

import XCTest
import CoreML
import Vision
import UIKit
@testable import NaviGPT

@MainActor
final class Phase2Tests: XCTestCase {
    
    var modelManager: CoreMLModelManager!
    var visionProcessor: VisionModelProcessor!
    var depthProcessor: DepthEstimationProcessor!
    
    override func setUp() async throws {
        try await super.setUp()
        modelManager = CoreMLModelManager.shared
        visionProcessor = VisionModelProcessor()
        depthProcessor = DepthEstimationProcessor()
    }
    
    override func tearDown() async throws {
        modelManager.unloadAllModels()
        try await super.tearDown()
    }
    
    // MARK: - CoreMLModelManager Tests
    
    func testModelManagerInitialization() {
        XCTAssertNotNil(modelManager, "ModelManager should initialize")
        XCTAssertFalse(modelManager.isLoading, "Should not be loading initially")
        XCTAssertTrue(modelManager.loadedModels.isEmpty, "No models should be loaded initially")
    }
    
    func testModelManagerSingleton() {
        let instance1 = CoreMLModelManager.shared
        let instance2 = CoreMLModelManager.shared
        XCTAssertTrue(instance1 === instance2, "Should return same singleton instance")
    }
    
    func testModelTypeEnumeration() {
        let allTypes: [ModelType] = [.objectDetection, .depthEstimation, .sceneUnderstanding, .textRecognition]
        
        for modelType in allTypes {
            XCTAssertFalse(modelType.fileName.isEmpty, "Model type \(modelType) should have a filename")
            XCTAssertFalse(modelType.rawValue.isEmpty, "Model type \(modelType) should have a raw value")
        }
    }
    
    func testModelLoadingWithoutFiles() async {
        // This test expects failure since we don't have actual model files yet
        do {
            try await modelManager.loadModel(.objectDetection)
            XCTFail("Should fail to load non-existent model")
        } catch let error as ModelError {
            switch error {
            case .modelNotFound(let type):
                XCTAssertEqual(type, .objectDetection, "Should report correct model type")
            case .loadingFailed:
                XCTAssertTrue(true, "Expected loading failure without model files")
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Should throw ModelError, got: \(error)")
        }
    }
    
    func testModelUnloading() {
        // Add mock loaded model to test unloading
        modelManager.loadedModels.insert(.objectDetection)
        XCTAssertTrue(modelManager.isModelLoaded(.objectDetection))
        
        modelManager.unloadModel(.objectDetection)
        XCTAssertFalse(modelManager.isModelLoaded(.objectDetection))
    }
    
    func testUnloadAllModels() {
        // Add multiple mock models
        modelManager.loadedModels.insert(.objectDetection)
        modelManager.loadedModels.insert(.depthEstimation)
        
        XCTAssertEqual(modelManager.loadedModels.count, 2)
        
        modelManager.unloadAllModels()
        XCTAssertTrue(modelManager.loadedModels.isEmpty)
    }
    
    func testIsModelLoaded() {
        XCTAssertFalse(modelManager.isModelLoaded(.objectDetection))
        
        modelManager.loadedModels.insert(.objectDetection)
        XCTAssertTrue(modelManager.isModelLoaded(.objectDetection))
    }
    
    // MARK: - VisionModelProcessor Tests
    
    func testVisionProcessorInitialization() {
        XCTAssertNotNil(visionProcessor, "VisionProcessor should initialize")
        XCTAssertFalse(visionProcessor.isProcessing, "Should not be processing initially")
        XCTAssertNil(visionProcessor.lastResult, "Should have no results initially")
    }
    
    func testDetectedObjectStructure() {
        let object = DetectedObject(
            label: "Test",
            confidence: 0.95,
            boundingBox: CGRect(x: 0, y: 0, width: 100, height: 100),
            distance: 2.5
        )
        
        XCTAssertEqual(object.label, "Test")
        XCTAssertEqual(object.confidence, 0.95)
        XCTAssertEqual(object.distance, 2.5)
        XCTAssertNotNil(object.id)
    }
    
    func testBoundingBoxConversion() {
        let normalizedBox = CGRect(x: 0.5, y: 0.5, width: 0.2, height: 0.3)
        let imageSize = CGSize(width: 1000, height: 1000)
        
        let converted = visionProcessor.convertBoundingBox(normalizedBox, imageSize: imageSize)
        
        XCTAssertEqual(converted.width, 200, accuracy: 0.1)
        XCTAssertEqual(converted.height, 300, accuracy: 0.1)
    }
    
    func testDescribeObjects() {
        let objects = [
            DetectedObject(label: "Person", confidence: 0.95, boundingBox: .zero, distance: 3.0),
            DetectedObject(label: "Car", confidence: 0.85, boundingBox: .zero, distance: 5.0)
        ]
        
        let description = visionProcessor.describeObjects(objects)
        
        XCTAssertTrue(description.contains("Person"))
        XCTAssertTrue(description.contains("Car"))
        XCTAssertTrue(description.contains("95%"))
        XCTAssertTrue(description.contains("3.0m"))
    }
    
    func testDescribeEmptyObjects() {
        let description = visionProcessor.describeObjects([])
        XCTAssertEqual(description, "No objects detected")
    }
    
    // MARK: - DepthEstimationProcessor Tests
    
    func testDepthProcessorInitialization() {
        XCTAssertNotNil(depthProcessor, "DepthProcessor should initialize")
        XCTAssertFalse(depthProcessor.isProcessing, "Should not be processing initially")
        XCTAssertNil(depthProcessor.lastResult, "Should have no results initially")
    }
    
    func testLiDARAvailabilityCheck() {
        // This will vary by device, just ensure it's set
        let hasLiDAR = depthProcessor.hasLiDAR
        XCTAssertNotNil(hasLiDAR, "LiDAR availability should be determined")
    }
    
    func testDepthPointStructure() {
        let point = DepthPoint(x: 0.5, y: 0.5, depth: 2.0, confidence: 0.9)
        
        XCTAssertEqual(point.x, 0.5)
        XCTAssertEqual(point.y, 0.5)
        XCTAssertEqual(point.depth, 2.0)
        XCTAssertEqual(point.confidence, 0.9)
    }
    
    func testDepthProcessingConfig() {
        let config = DepthProcessingConfig()
        
        XCTAssertTrue(config.useARKitDepth)
        XCTAssertTrue(config.useCoreMLDepth)
        XCTAssertEqual(config.samplingRate, 10)
        XCTAssertEqual(config.maxDepthRange, 10.0)
        
        depthProcessor.updateConfig(config)
    }
    
    func testObstacleDetection() {
        let depthPoints = [
            DepthPoint(x: 0.5, y: 0.5, depth: 1.5, confidence: 1.0), // Obstacle
            DepthPoint(x: 0.6, y: 0.5, depth: 5.0, confidence: 1.0), // Not obstacle
            DepthPoint(x: 0.7, y: 0.5, depth: 0.8, confidence: 1.0)  // Obstacle
        ]
        
        let result = DepthEstimationResult(
            depthMap: nil,
            averageDepth: 2.5,
            minDepth: 0.8,
            maxDepth: 5.0,
            depthPoints: depthPoints,
            processingTime: 0.1,
            timestamp: Date()
        )
        
        let obstacles = depthProcessor.detectObstacles(from: result, proximityThreshold: 2.0)
        
        XCTAssertEqual(obstacles.count, 2, "Should detect 2 obstacles within threshold")
        XCTAssertTrue(obstacles.allSatisfy { $0.depth < 2.0 }, "All obstacles should be within threshold")
    }
    
    func testDescribeDepthScenario() {
        let clearResult = DepthEstimationResult(
            depthMap: nil,
            averageDepth: 8.0,
            minDepth: 5.0,
            maxDepth: 10.0,
            depthPoints: [],
            processingTime: 0.1,
            timestamp: Date()
        )
        
        let description = depthProcessor.describeDepthScenario(clearResult)
        XCTAssertTrue(description.contains("Clear path"), "Should describe clear path")
    }
    
    // MARK: - ModelTypes Tests
    
    func testDetectionConfidence() {
        let low = DetectionConfidence(rawValue: 0.3)
        let medium = DetectionConfidence(rawValue: 0.6)
        let high = DetectionConfidence(rawValue: 0.8)
        let veryHigh = DetectionConfidence(rawValue: 0.95)
        
        XCTAssertEqual(low, .low)
        XCTAssertEqual(medium, .medium)
        XCTAssertEqual(high, .high)
        XCTAssertEqual(veryHigh, .veryHigh)
        
        XCTAssertTrue(veryHigh > high)
        XCTAssertTrue(high > medium)
        XCTAssertTrue(medium > low)
    }
    
    func testObstacleUrgencyLevel() {
        let criticalObstacle = Obstacle(
            label: "Wall",
            position: SpatialPoint(x: 0, y: 0, z: 0.5, screenPosition: .zero, worldPosition: nil),
            boundingBox: .zero,
            confidence: .high,
            distance: 0.5,
            bearing: 0
        )
        
        let warningObstacle = Obstacle(
            label: "Person",
            position: SpatialPoint(x: 0, y: 0, z: 1.5, screenPosition: .zero, worldPosition: nil),
            boundingBox: .zero,
            confidence: .high,
            distance: 1.5,
            bearing: 0
        )
        
        let infoObstacle = Obstacle(
            label: "Car",
            position: SpatialPoint(x: 0, y: 0, z: 4.0, screenPosition: .zero, worldPosition: nil),
            boundingBox: .zero,
            confidence: .high,
            distance: 4.0,
            bearing: 0
        )
        
        XCTAssertEqual(criticalObstacle.urgencyLevel, 3)
        XCTAssertEqual(warningObstacle.urgencyLevel, 2)
        XCTAssertEqual(infoObstacle.urgencyLevel, 1)
        
        XCTAssertTrue(criticalObstacle.isNearby)
        XCTAssertTrue(warningObstacle.isNearby)
        XCTAssertFalse(infoObstacle.isNearby)
    }
    
    func testObstacleDescription() {
        let obstacle = Obstacle(
            label: "Person",
            position: SpatialPoint(x: 0, y: 0, z: 2.5, screenPosition: .zero, worldPosition: nil),
            boundingBox: .zero,
            confidence: .high,
            distance: 2.5,
            bearing: -60
        )
        
        let description = obstacle.describe()
        
        XCTAssertTrue(description.contains("Person"))
        XCTAssertTrue(description.contains("2.5"))
        XCTAssertTrue(description.contains("left"))
    }
    
    func testEnvironmentSnapshot() {
        let obstacles = [
            Obstacle(label: "Wall", position: SpatialPoint(x: 0, y: 0, z: 0.5, screenPosition: .zero, worldPosition: nil),
                    boundingBox: .zero, confidence: .high, distance: 0.5, bearing: 0),
            Obstacle(label: "Chair", position: SpatialPoint(x: 0, y: 0, z: 1.5, screenPosition: .zero, worldPosition: nil),
                    boundingBox: .zero, confidence: .medium, distance: 1.5, bearing: 30),
            Obstacle(label: "Table", position: SpatialPoint(x: 0, y: 0, z: 5.0, screenPosition: .zero, worldPosition: nil),
                    boundingBox: .zero, confidence: .low, distance: 5.0, bearing: -30)
        ]
        
        let snapshot = EnvironmentSnapshot(
            timestamp: Date(),
            obstacles: obstacles,
            sceneContext: nil,
            depthEstimate: nil,
            recognizedText: []
        )
        
        XCTAssertEqual(snapshot.obstacleCount, 3)
        XCTAssertEqual(snapshot.nearbyObstacleCount, 2)
        XCTAssertEqual(snapshot.criticalObstacles.count, 2)
        
        let guidance = snapshot.generateNavigationGuidance()
        XCTAssertTrue(guidance.contains("Caution"))
    }
    
    func testModelPerformanceMetrics() {
        let metrics = ModelPerformanceMetrics(
            modelType: .objectDetection,
            inferenceTime: 0.020,
            preprocessingTime: 0.005,
            postprocessingTime: 0.005,
            totalTime: 0.030,
            timestamp: Date()
        )
        
        XCTAssertEqual(metrics.fps, 1.0 / 0.030, accuracy: 0.001)
        XCTAssertEqual(metrics.performanceLevel, .excellent)
    }
    
    func testModelStatistics() {
        var stats = ModelStatistics()
        
        stats.recordInference(time: 0.030)
        stats.recordInference(time: 0.040)
        stats.recordInference(time: 0.050)
        stats.recordFailure()
        
        XCTAssertEqual(stats.totalInferences, 3)
        XCTAssertEqual(stats.failureCount, 1)
        XCTAssertEqual(stats.minInferenceTime, 0.030)
        XCTAssertEqual(stats.maxInferenceTime, 0.050)
        XCTAssertEqual(stats.averageInferenceTime, 0.040, accuracy: 0.001)
        XCTAssertEqual(stats.successRate, 2.0/3.0, accuracy: 0.01)
    }
    
    // MARK: - Performance Tests
    
    func testModelManagerPerformance() {
        measure {
            let manager = CoreMLModelManager.shared
            _ = manager.isModelLoaded(.objectDetection)
        }
    }
    
    func testVisionProcessorCreationPerformance() {
        measure {
            _ = VisionModelProcessor()
        }
    }
    
    func testDepthProcessorCreationPerformance() {
        measure {
            _ = DepthEstimationProcessor()
        }
    }
    
    // MARK: - Integration Tests
    
    func testModelManagerVisionProcessorIntegration() async {
        let manager = CoreMLModelManager.shared
        let processor = VisionModelProcessor()
        
        // Both should be able to coexist
        XCTAssertNotNil(manager)
        XCTAssertNotNil(processor)
        XCTAssertFalse(processor.isProcessing)
    }
    
    func testFullPipelineComponents() async {
        // Test that all components can be instantiated together
        let manager = CoreMLModelManager.shared
        let visionProc = VisionModelProcessor()
        let depthProc = DepthEstimationProcessor()
        
        XCTAssertNotNil(manager)
        XCTAssertNotNil(visionProc)
        XCTAssertNotNil(depthProc)
        
        // Verify they can interact with shared state
        XCTAssertTrue(manager.loadedModels.isEmpty)
    }
}
