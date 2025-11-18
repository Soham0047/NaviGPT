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
struct SpatialPoint {
    let x: Float
    let y: Float
    let z: Float // depth
    let screenPosition: CGPoint
    let worldPosition: simd_float3?
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
struct Obstacle {
    let id: UUID = UUID()
    let label: String
    let position: SpatialPoint
    let boundingBox: CGRect
    let confidence: DetectionConfidence
    let distance: Float
    let bearing: Float? // Angle relative to device orientation
    
    var isNearby: Bool {
        return distance < 2.0
    }
    
    var urgencyLevel: Int {
        if distance < 1.0 {
            return 3 // Critical
        } else if distance < 2.0 {
            return 2 // Warning
        } else if distance < 5.0 {
            return 1 // Info
        }
        return 0 // None
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
    let sceneType: String // indoor, outdoor, street, etc.
    let confidence: Float
    let lighting: LightingCondition
    let weatherHints: [String]
    
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
    let sceneContext: SceneContext?
    let depthEstimate: DepthEstimationResult?
    let recognizedText: [String]
    
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
    let modelType: ModelType
    let inferenceTime: TimeInterval
    let preprocessingTime: TimeInterval
    let postprocessingTime: TimeInterval
    let totalTime: TimeInterval
    let timestamp: Date
    
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
