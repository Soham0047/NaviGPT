//
//  ModelTypes.swift
//  NaviGPT
//
//  Created by NaviGPT Team on 11/17/25.
//  Common data types and protocols for ML models
//

import Foundation
import CoreML
import Vision
import CoreGraphics

// MARK: - Processing Protocols

/// Protocol for any ML model processor
protocol ModelProcessor {
    associatedtype InputType
    associatedtype OutputType
    
    func process(_ input: InputType) async throws -> OutputType
    var isProcessing: Bool { get }
}

/// Protocol for models that can be preloaded
protocol PreloadableModel {
    func preload() async throws
    var isLoaded: Bool { get }
}

// MARK: - Common Types

/// Represents a point of interest in 3D space
struct SpatialPoint: Equatable {
    let x: Float
    let y: Float
    let z: Float // depth
    var screenPosition: CGPoint = .zero
    var worldPosition: simd_float3?

    init(x: Float, y: Float, z: Float, screenPosition: CGPoint = .zero, worldPosition: simd_float3? = nil) {
        self.x = x
        self.y = y
        self.z = z
        self.screenPosition = screenPosition
        self.worldPosition = worldPosition
    }

    static func ==(lhs: SpatialPoint, rhs: SpatialPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z &&
               lhs.screenPosition == rhs.screenPosition &&
               lhs.worldPosition == rhs.worldPosition
    }
}

/// Confidence levels for detections
enum DetectionConfidence: Comparable {
    case low      // < 0.5
    case medium   // 0.5 - 0.75
    case high     // 0.75 - 0.9
    case veryHigh // > 0.9

    init(rawValue: Float) {
        switch rawValue {
        case 0..<0.5:
            self = .low
        case 0.5..<0.75:
            self = .medium
        case 0.75..<0.9:
            self = .high
        default:
            self = .veryHigh
        }
    }

    var rawValue: Float {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 0.8
        case .veryHigh: return 0.95
        }
    }

    var description: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }
}

/// Obstacle information combining vision and depth
struct Obstacle: Equatable {
    let id: UUID = UUID()
    let label: String
    let position: SpatialPoint
    var boundingBox: CGRect = .zero
    let confidence: DetectionConfidence
    let distance: Float
    var bearing: Float? = nil // Angle relative to device orientation

    init(label: String, position: SpatialPoint, confidence: DetectionConfidence, distance: Float, boundingBox: CGRect = .zero, bearing: Float? = nil) {
        self.label = label
        self.position = position
        self.confidence = confidence
        self.distance = distance
        self.boundingBox = boundingBox
        self.bearing = bearing
    }

    var isNearby: Bool {
        return distance < 2.0
    }

    var urgencyLevel: Int {
        if distance < 1.5 {
            return 3 // Critical - immediate danger
        } else if distance < 3.0 {
            return 2 // Warning - approaching
        } else if distance < 6.0 {
            return 1 // Info - nearby
        }
        return 0 // None - far away
    }
    
    func describe() -> String {
        let distanceStr = String(format: "%.1f", distance)
        var description = "\(label) at \(distanceStr) meters"
        
        if let bearing = bearing {
            let direction: String
            if bearing < -45 {
                direction = "left"
            } else if bearing > 45 {
                direction = "right"
            } else {
                direction = "ahead"
            }
            description += " \(direction)"
        }
        
        return description
    }
}

/// Environment context from scene understanding
struct SceneContext {
    var sceneType: String = "unknown" // indoor, outdoor, street, etc.
    var confidence: Float = 0.0
    var lighting: LightingCondition = .normal
    var weatherHints: [String] = []

    // Compatibility properties for old API
    var primaryObjects: [String] = []
    var spatialLayout: String = "unknown"
    var lightingConditions: String {
        switch lighting {
        case .bright: return "bright"
        case .normal: return "normal"
        case .dim: return "dim"
        case .dark: return "dark"
        }
    }
    var confidenceScore: Float { return confidence }

    init(sceneType: String = "unknown", confidence: Float = 0.0, lighting: LightingCondition = .normal, weatherHints: [String] = []) {
        self.sceneType = sceneType
        self.confidence = confidence
        self.lighting = lighting
        self.weatherHints = weatherHints
    }

    init(primaryObjects: [String], spatialLayout: String, lightingConditions: String, confidenceScore: Float) {
        self.primaryObjects = primaryObjects
        self.spatialLayout = spatialLayout
        self.confidence = confidenceScore

        // Map string lighting to enum
        switch lightingConditions.lowercased() {
        case "bright": self.lighting = .bright
        case "dim": self.lighting = .dim
        case "dark": self.lighting = .dark
        default: self.lighting = .normal
        }
    }

    enum LightingCondition {
        case bright
        case normal
        case dim
        case dark
    }
}

/// Aggregated environment understanding
struct EnvironmentSnapshot {
    let timestamp: Date
    let obstacles: [Obstacle]
    var sceneContext: SceneContext? = nil
    var depthEstimate: DepthEstimationResult? = nil
    var recognizedText: [String] = []
    var performanceMetrics: ModelPerformanceMetrics? = nil

    init(timestamp: Date, obstacles: [Obstacle], sceneContext: SceneContext? = nil, depthEstimate: DepthEstimationResult? = nil, recognizedText: [String] = [], performanceMetrics: ModelPerformanceMetrics? = nil) {
        self.timestamp = timestamp
        self.obstacles = obstacles
        self.sceneContext = sceneContext
        self.depthEstimate = depthEstimate
        self.recognizedText = recognizedText
        self.performanceMetrics = performanceMetrics
    }

    var obstacleCount: Int {
        return obstacles.count
    }

    var nearbyObstacleCount: Int {
        return obstacles.filter { $0.isNearby }.count
    }

    var criticalObstacles: [Obstacle] {
        return obstacles.filter { $0.urgencyLevel >= 2 }.sorted { $0.distance < $1.distance }
    }

    func generateNavigationGuidance() -> String {
        if criticalObstacles.isEmpty {
            return "Path is clear"
        }

        let descriptions = criticalObstacles.prefix(3).map { $0.describe() }
        return "Caution: " + descriptions.joined(separator: "; ")
    }
}

// MARK: - Model Performance Metrics

/// Tracks performance metrics for model inference
struct ModelPerformanceMetrics {
    var modelType: ModelType? = nil
    var modelName: String = "Unknown"
    let inferenceTime: TimeInterval
    var preprocessingTime: TimeInterval = 0
    var postprocessingTime: TimeInterval = 0
    let totalTime: TimeInterval
    var preprocessTime: TimeInterval { preprocessingTime } // Alias
    var postprocessTime: TimeInterval { postprocessingTime } // Alias
    var timestamp: Date = Date()

    init(inferenceTime: TimeInterval, preprocessTime: TimeInterval = 0, postprocessTime: TimeInterval = 0, totalTime: TimeInterval, modelName: String = "Unknown", modelType: ModelType? = nil, timestamp: Date = Date()) {
        self.inferenceTime = inferenceTime
        self.preprocessingTime = preprocessTime
        self.postprocessingTime = postprocessTime
        self.totalTime = totalTime
        self.modelName = modelName
        self.modelType = modelType
        self.timestamp = timestamp
    }

    var fps: Double {
        return 1.0 / totalTime
    }
    
    var performanceLevel: PerformanceLevel {
        if totalTime < 0.033 { // > 30 FPS
            return .excellent
        } else if totalTime < 0.066 { // > 15 FPS
            return .good
        } else if totalTime < 0.1 { // > 10 FPS
            return .acceptable
        } else {
            return .poor
        }
    }
    
    enum PerformanceLevel {
        case excellent
        case good
        case acceptable
        case poor
    }
}

/// Aggregated statistics for model performance
struct ModelStatistics {
    var totalInferences: Int = 0
    var averageInferenceTime: TimeInterval = 0
    var minInferenceTime: TimeInterval = .infinity
    var maxInferenceTime: TimeInterval = 0
    var failureCount: Int = 0
    
    mutating func recordInference(time: TimeInterval) {
        totalInferences += 1
        averageInferenceTime = ((averageInferenceTime * Double(totalInferences - 1)) + time) / Double(totalInferences)
        minInferenceTime = min(minInferenceTime, time)
        maxInferenceTime = max(maxInferenceTime, time)
    }
    
    mutating func recordFailure() {
        failureCount += 1
    }
    
    var successRate: Double {
        guard totalInferences > 0 else { return 0 }
        return Double(totalInferences - failureCount) / Double(totalInferences)
    }
}

// MARK: - Model Types

/// Types of ML models supported
enum ModelType: String, CaseIterable {
    case objectDetection = "YOLOv8"
    case depthEstimation = "DepthEstimation"
    case sceneUnderstanding = "SceneClassifier"
    case textRecognition = "OCR"

    var fileName: String {
        switch self {
        case .objectDetection: return "YOLOv8"
        case .depthEstimation: return "DepthEstimation"
        case .sceneUnderstanding: return "SceneClassifier"
        case .textRecognition: return "TextRecognition"
        }
    }
}

// MARK: - Depth Estimation Result

/// Result from depth estimation
struct DepthEstimationResult {
    let depthMap: [Float]
    let width: Int
    let height: Int
    let timestamp: Date
    var obstacles: [DetectedObstacle] = []
    var spatialGuidance: String = ""

    init(depthMap: [Float], width: Int, height: Int, timestamp: Date = Date(), obstacles: [DetectedObstacle] = [], spatialGuidance: String = "") {
        self.depthMap = depthMap
        self.width = width
        self.height = height
        self.timestamp = timestamp
        self.obstacles = obstacles
        self.spatialGuidance = spatialGuidance
    }
}

/// Simple obstacle detected from depth
struct DetectedObstacle: Identifiable {
    let id: UUID
    let position: SpatialPoint
    let distance: Float
    let size: CGSize

    init(id: UUID = UUID(), position: SpatialPoint, distance: Float, size: CGSize) {
        self.id = id
        self.position = position
        self.distance = distance
        self.size = size
    }
}

