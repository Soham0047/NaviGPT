//
//  Phase3Tests.swift
//  NaviGPTTests
//
//  Phase 3: Real-Time Processing & Integration Tests
//  Tests for camera processing and enhanced LiDAR functionality
//

import XCTest
import AVFoundation
import ARKit
import CoreML
@testable import NaviGPT

@MainActor
final class Phase3Tests: XCTestCase {

    var realTimeCameraProcessor: RealTimeCameraProcessor!
    var enhancedLiDARProcessor: EnhancedLiDARProcessor!

    override func setUp() async throws {
        try await super.setUp()
        realTimeCameraProcessor = RealTimeCameraProcessor()
        enhancedLiDARProcessor = EnhancedLiDARProcessor()
    }

    override func tearDown() async throws {
        realTimeCameraProcessor = nil
        enhancedLiDARProcessor = nil
        try await super.tearDown()
    }

    // MARK: - Real-Time Camera Processor Tests

    func testCameraProcessorInitialization() {
        XCTAssertNotNil(realTimeCameraProcessor, "RealTimeCameraProcessor should initialize")
        XCTAssertFalse(realTimeCameraProcessor.isProcessing, "Should not be processing initially")
        XCTAssertEqual(realTimeCameraProcessor.currentFPS, 0.0, "Initial FPS should be 0")
        XCTAssertTrue(realTimeCameraProcessor.detectedObjects.isEmpty, "Should have no detected objects initially")
    }

    func testCameraProcessorConfiguration() {
        var config = RealTimeCameraProcessor.Configuration()

        // Test default configuration
        XCTAssertEqual(config.targetFPS, 30, "Default FPS should be 30")
        XCTAssertTrue(config.enableObjectDetection, "Object detection should be enabled by default")
        XCTAssertTrue(config.enableDepthEstimation, "Depth estimation should be enabled by default")
        XCTAssertEqual(config.confidenceThreshold, 0.5, "Default confidence threshold should be 0.5")

        // Test configuration modification
        config.targetFPS = 60
        config.confidenceThreshold = 0.7
        XCTAssertEqual(config.targetFPS, 60, "FPS should be modifiable")
        XCTAssertEqual(config.confidenceThreshold, 0.7, "Confidence threshold should be modifiable")
    }

    func testProcessImageWithoutModels() async throws {
        // Create a test image
        let testImage = createTestImage()

        do {
            let snapshot = try await realTimeCameraProcessor.processImage(testImage)

            // Verify snapshot structure
            XCTAssertNotNil(snapshot, "Should return environment snapshot")
            XCTAssertNotNil(snapshot.timestamp, "Snapshot should have timestamp")
            XCTAssertNotNil(snapshot.sceneContext, "Snapshot should have scene context")

            // Performance metrics should exist
            XCTAssertNotNil(snapshot.performanceMetrics, "Should have performance metrics")

        } catch {
            // Expected to fail if models are not present
            XCTAssertTrue(error is ModelError, "Should throw ModelError when models are missing")
        }
    }

    func testCameraPerformanceMetrics() {
        XCTAssertEqual(realTimeCameraProcessor.processingLatency, 0.0, "Initial latency should be 0")
        XCTAssertEqual(realTimeCameraProcessor.currentFPS, 0.0, "Initial FPS should be 0")
    }

    // MARK: - Enhanced LiDAR Processor Tests

    func testLiDARProcessorInitialization() {
        XCTAssertNotNil(enhancedLiDARProcessor, "EnhancedLiDARProcessor should initialize")
        XCTAssertFalse(enhancedLiDARProcessor.isProcessing, "Should not be processing initially")
        XCTAssertTrue(enhancedLiDARProcessor.trackedObstacles.isEmpty, "Should have no tracked obstacles initially")
        XCTAssertNil(enhancedLiDARProcessor.depthMap, "Should have no depth map initially")
    }

    func testLiDARConfiguration() {
        var config = EnhancedLiDARProcessor.Configuration()

        // Test default configuration
        XCTAssertTrue(config.enableMLDepthFusion, "ML depth fusion should be enabled by default")
        XCTAssertEqual(config.obstacleDistanceThreshold, 5.0, "Default distance threshold should be 5.0 meters")
        XCTAssertEqual(config.trackingTimeout, 2.0, "Default tracking timeout should be 2.0 seconds")
        XCTAssertEqual(config.depthMapResolution, 256, "Default depth map resolution should be 256")
        XCTAssertTrue(config.spatialAudioEnabled, "Spatial audio should be enabled by default")

        // Test configuration modification
        config.obstacleDistanceThreshold = 10.0
        config.trackingTimeout = 3.0
        XCTAssertEqual(config.obstacleDistanceThreshold, 10.0, "Distance threshold should be modifiable")
        XCTAssertEqual(config.trackingTimeout, 3.0, "Tracking timeout should be modifiable")
    }

    func testDepthMapStructure() {
        let width = 256
        let height = 192
        let depthValues = Array(repeating: Float(1.5), count: width * height)

        let depthMap = DepthMap(
            width: width,
            height: height,
            data: depthValues,
            timestamp: Date()
        )

        XCTAssertEqual(depthMap.width, width, "Width should match")
        XCTAssertEqual(depthMap.height, height, "Height should match")
        XCTAssertEqual(depthMap.data.count, width * height, "Data count should match dimensions")

        // Test depth access
        if let depth = depthMap.depthAt(x: 100, y: 100) {
            XCTAssertEqual(depth, 1.5, "Should retrieve correct depth value")
        } else {
            XCTFail("Should return depth value for valid coordinates")
        }

        // Test out of bounds
        XCTAssertNil(depthMap.depthAt(x: -1, y: 0), "Should return nil for negative x")
        XCTAssertNil(depthMap.depthAt(x: width, y: 0), "Should return nil for x >= width")
        XCTAssertNil(depthMap.depthAt(x: 0, y: -1), "Should return nil for negative y")
        XCTAssertNil(depthMap.depthAt(x: 0, y: height), "Should return nil for y >= height")
    }

    func testTrackedObstacleStructure() {
        let position = SpatialPoint(x: 1.0, y: 0.5, z: 2.0)
        let obstacle = TrackedObstacle(
            id: UUID(),
            position: position,
            velocity: simd_float3(0.1, 0, 0.2),
            distance: 2.24,
            lastSeen: Date(),
            detectionCount: 5,
            confidence: 0.8
        )

        XCTAssertEqual(obstacle.position.x, 1.0)
        XCTAssertEqual(obstacle.position.y, 0.5)
        XCTAssertEqual(obstacle.position.z, 2.0)
        XCTAssertEqual(obstacle.distance, 2.24)
        XCTAssertEqual(obstacle.detectionCount, 5)
        XCTAssertEqual(obstacle.confidence, 0.8)
    }

    func testSpatialGuidanceStructure() {
        let guidance = SpatialGuidance(
            direction: .pi / 4, // 45 degrees
            distance: 1.5,
            intensity: 0.7,
            type: .staticObstacle
        )

        XCTAssertEqual(guidance.direction, .pi / 4, accuracy: 0.01)
        XCTAssertEqual(guidance.distance, 1.5)
        XCTAssertEqual(guidance.intensity, 0.7)
        XCTAssertEqual(guidance.type, .staticObstacle)
    }

    func testPathAnalysisStructure() {
        let warning = PathWarning(
            type: .movingObstacle,
            position: SpatialPoint(x: 1.0, y: 0, z: 2.0),
            timeToImpact: 3.0,
            severity: .high
        )

        let analysis = PathAnalysis(
            clearPath: false,
            warnings: [warning],
            recommendedDirection: .pi / 4
        )

        XCTAssertFalse(analysis.clearPath, "Path should not be clear with warnings")
        XCTAssertEqual(analysis.warnings.count, 1, "Should have one warning")
        XCTAssertEqual(analysis.recommendedDirection, .pi / 4, accuracy: 0.01)
    }

    func testObstacleTrackerInitialization() {
        let tracker = ObstacleTracker()

        let detection = DetectedObstacle(
            id: UUID(),
            position: SpatialPoint(x: 1.0, y: 0, z: 2.0),
            distance: 2.24,
            size: CGSize(width: 0.5, height: 1.0),
            timestamp: Date()
        )

        let tracked = tracker.updateTracking(with: [detection], timestamp: Date())

        XCTAssertEqual(tracked.count, 1, "Should track one obstacle")
        XCTAssertEqual(tracked[0].detectionCount, 1, "Detection count should be 1 for new obstacle")
        XCTAssertEqual(tracked[0].confidence, 0.3, "Initial confidence should be low")
    }

    func testObstacleTracking() {
        let tracker = ObstacleTracker()
        let now = Date()

        // First detection
        let detection1 = DetectedObstacle(
            id: UUID(),
            position: SpatialPoint(x: 1.0, y: 0, z: 2.0),
            distance: 2.0,
            size: CGSize(width: 0.5, height: 1.0),
            timestamp: now
        )

        var tracked = tracker.updateTracking(with: [detection1], timestamp: now)
        XCTAssertEqual(tracked.count, 1, "Should track one obstacle")
        let trackedId = tracked[0].id

        // Second detection - same obstacle moved slightly
        let detection2 = DetectedObstacle(
            id: UUID(),
            position: SpatialPoint(x: 1.1, y: 0, z: 2.1),
            distance: 2.1,
            size: CGSize(width: 0.5, height: 1.0),
            timestamp: now.addingTimeInterval(0.1)
        )

        tracked = tracker.updateTracking(with: [detection2], timestamp: now.addingTimeInterval(0.1))
        XCTAssertEqual(tracked.count, 1, "Should still track one obstacle")
        XCTAssertEqual(tracked[0].id, trackedId, "Should maintain same ID")
        XCTAssertGreaterThan(tracked[0].detectionCount, 1, "Detection count should increase")
        XCTAssertGreaterThan(tracked[0].confidence, 0.3, "Confidence should increase")
    }

    func testSpatialPointOperations() {
        let point1 = SpatialPoint(x: 1.0, y: 2.0, z: 3.0)
        let point2 = SpatialPoint(x: 4.0, y: 5.0, z: 6.0)

        // Test distance calculation
        let distance = point1.distance(to: point2)
        let expectedDistance = sqrt(9.0 + 9.0 + 9.0) // sqrt((4-1)^2 + (5-2)^2 + (6-3)^2)
        XCTAssertEqual(distance, Float(expectedDistance), accuracy: 0.01)

        // Test subtraction
        let diff = point2 - point1
        XCTAssertEqual(diff.x, 3.0)
        XCTAssertEqual(diff.y, 3.0)
        XCTAssertEqual(diff.z, 3.0)
    }

    // MARK: - Integration Tests

    func testPhase3ComponentsIntegration() {
        // Test that Phase 3 components work together
        XCTAssertNotNil(realTimeCameraProcessor, "Camera processor should exist")
        XCTAssertNotNil(enhancedLiDARProcessor, "LiDAR processor should exist")

        // Verify configurations are compatible
        let cameraConfig = realTimeCameraProcessor.configuration
        let lidarConfig = enhancedLiDARProcessor.configuration

        XCTAssertTrue(cameraConfig.enableDepthEstimation || lidarConfig.enableMLDepthFusion,
                     "At least one depth source should be enabled")
    }

    func testPerformanceTargets() {
        // Verify performance targets are reasonable
        let targetFPS = realTimeCameraProcessor.configuration.targetFPS
        XCTAssertGreaterThanOrEqual(targetFPS, 15, "Target FPS should be at least 15")
        XCTAssertLessThanOrEqual(targetFPS, 60, "Target FPS should not exceed 60")

        let threshold = realTimeCameraProcessor.configuration.confidenceThreshold
        XCTAssertGreaterThanOrEqual(threshold, 0.3, "Confidence threshold should be reasonable")
        XCTAssertLessThanOrEqual(threshold, 0.9, "Confidence threshold should not be too high")
    }

    // MARK: - Helper Methods

    private func createTestImage() -> UIImage {
        // Create a simple test image
        let size = CGSize(width: 640, height: 480)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Draw some simple shapes to simulate objects
            UIColor.blue.setFill()
            context.fill(CGRect(x: 100, y: 100, width: 100, height: 100))

            UIColor.red.setFill()
            context.fill(CGRect(x: 400, y: 200, width: 80, height: 150))
        }

        return image
    }
}

// MARK: - Performance Tests

extension Phase3Tests {

    func testCameraProcessorPerformance() throws {
        let testImage = createTestImage()

        measure {
            Task {
                do {
                    _ = try await realTimeCameraProcessor.processImage(testImage)
                } catch {
                    // Expected to fail without models
                }
            }
        }
    }

    func testDepthMapAccess Performance() {
        let width = 256
        let height = 192
        let depthValues = (0..<(width * height)).map { _ in Float.random(in: 0.1...10.0) }
        let depthMap = DepthMap(width: width, height: height, data: depthValues, timestamp: Date())

        measure {
            for _ in 0..<1000 {
                let x = Int.random(in: 0..<width)
                let y = Int.random(in: 0..<height)
                _ = depthMap.depthAt(x: x, y: y)
            }
        }
    }
}
