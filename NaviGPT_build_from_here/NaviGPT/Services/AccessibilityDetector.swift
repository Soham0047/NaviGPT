//
//  AccessibilityDetector.swift
//  NaviGPT
//
//  Phase 4A: Enhanced Accessibility Detection
//  Detects accessibility-critical features like curbs, crosswalks, ramps, stairs
//

import Foundation
import Vision
import CoreML
import UIKit
import os.log

/// Accessibility-specific features
enum AccessibilityFeature: Equatable {
    case curb(height: Float, hasCut: Bool)
    case crosswalk(type: CrosswalkType, hasSignal: Bool)
    case tactilePaving(pattern: TactilePattern)
    case stairs(direction: StairDirection, stepCount: Int?)
    case ramp(angle: Float)
    case elevator(floor: String?)
    case door(isOpen: Bool, isAutomatic: Bool)
    case brailleSign
    case guideDog
    
    var description: String {
        switch self {
        case .curb(let height, let hasCut):
            return hasCut ? "Curb cut available" : "Curb ahead, \(height) meters high"
        case .crosswalk(let type, let hasSignal):
            return hasSignal ? "\(type.rawValue) crosswalk with signal" : "\(type.rawValue) crosswalk"
        case .tactilePaving(let pattern):
            return "Tactile paving - \(pattern.rawValue)"
        case .stairs(let direction, let stepCount):
            if let count = stepCount {
                return "Stairs \(direction.rawValue), \(count) steps"
            }
            return "Stairs \(direction.rawValue)"
        case .ramp(let angle):
            return "Ramp, \(Int(angle)) degree incline"
        case .elevator(let floor):
            return floor != nil ? "Elevator to floor \(floor!)" : "Elevator"
        case .door(let isOpen, let isAutomatic):
            return isAutomatic ? "Automatic door" : (isOpen ? "Door open" : "Door closed")
        case .brailleSign:
            return "Braille sign detected"
        case .guideDog:
            return "Guide dog detected"
        }
    }
}

enum CrosswalkType: String {
    case zebra = "Zebra"
    case signaled = "Signaled"
    case unsignaled = "Unmarked"
}

enum TactilePattern: String {
    case warning = "Warning pattern"
    case directional = "Directional pattern"
    case platform = "Platform edge"
}

enum StairDirection: String {
    case up = "going up"
    case down = "going down"
    case unknown = "direction unknown"
}

/// Result of accessibility detection
struct AccessibilityDetectionResult {
    let features: [AccessibilityFeature]
    let processingTime: TimeInterval
    let timestamp: Date
    
    var hasAccessiblePath: Bool {
        features.contains { feature in
            if case .curb(_, let hasCut) = feature {
                return hasCut
            }
            if case .ramp = feature {
                return true
            }
            return false
        }
    }
    
    var navigationGuidance: String {
        if features.isEmpty {
            return "No accessibility features detected"
        }
        
        let descriptions = features.map { $0.description }
        return descriptions.joined(separator: ". ")
    }
}

/// Detects accessibility-specific features
@MainActor
class AccessibilityDetector: ObservableObject {
    
    // MARK: - Properties
    @Published var isProcessing: Bool = false
    @Published var lastResult: AccessibilityDetectionResult?
    
    private let visionProcessor: VisionModelProcessor
    private let logger = Logger(subsystem: "com.navigpt.accessibility", category: "AccessibilityDetector")
    
    // MARK: - Initialization
    init() {
        self.visionProcessor = VisionModelProcessor()
    }
    
    // MARK: - Detection Methods
    
    /// Detect accessibility features in an image
    func detectAccessibilityFeatures(in image: UIImage) async throws -> AccessibilityDetectionResult {
        let startTime = Date()
        isProcessing = true
        defer { isProcessing = false }
        
        logger.info("Starting accessibility feature detection")
        
        var features: [AccessibilityFeature] = []
        
        // Use Vision framework for basic detection
        guard let ciImage = CIImage(image: image) else {
            throw ModelError.invalidInput("Failed to convert image")
        }
        
        // Detect edges and lines (for crosswalks, curbs)
        let edgeFeatures = try await detectEdgesAndLines(ciImage: ciImage)
        features.append(contentsOf: edgeFeatures)
        
        // Detect text (for signs, elevator buttons)
        let textFeatures = try await detectTextFeatures(ciImage: ciImage)
        features.append(contentsOf: textFeatures)
        
        // Detect objects (doors, stairs)
        let objectFeatures = try await detectAccessibilityObjects(image: image)
        features.append(contentsOf: objectFeatures)
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        let result = AccessibilityDetectionResult(
            features: features,
            processingTime: processingTime,
            timestamp: Date()
        )
        
        lastResult = result
        logger.info("Accessibility detection complete: \(features.count) features found")
        
        return result
    }
    
    // MARK: - Private Detection Methods
    
    private func detectEdgesAndLines(ciImage: CIImage) async throws -> [AccessibilityFeature] {
        var features: [AccessibilityFeature] = []
        
        let lineRequest = VNDetectRectanglesRequest()
        lineRequest.minimumConfidence = 0.5
        lineRequest.maximumObservations = 10
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([lineRequest])
                
                guard let observations = lineRequest.results else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Analyze rectangles for crosswalks and curbs
                for observation in observations {
                    let aspectRatio = observation.boundingBox.width / observation.boundingBox.height
                    
                    // Horizontal lines might be curbs or crosswalks
                    if aspectRatio > 2.0 && observation.boundingBox.minY < 0.5 {
                        // Likely a crosswalk or curb in lower half of image
                        if observation.boundingBox.width > 0.6 {
                            features.append(.crosswalk(type: .zebra, hasSignal: false))
                        } else {
                            features.append(.curb(height: 0.15, hasCut: false))
                        }
                    }
                }
                
                continuation.resume(returning: features)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectTextFeatures(ciImage: CIImage) async throws -> [AccessibilityFeature] {
        var features: [AccessibilityFeature] = []
        
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([textRequest])
                
                guard let observations = textRequest.results else {
                    continuation.resume(returning: [])
                    return
                }
                
                for observation in observations {
                    guard let text = observation.topCandidates(1).first?.string.lowercased() else { continue }
                    
                    // Detect elevator-related text
                    if text.contains("floor") || text.contains("level") {
                        features.append(.elevator(floor: text))
                    }
                    
                    // Detect braille indicators
                    if text.contains("braille") || text.contains("⠃⠗⠁⠊⠇⠇⠑") {
                        features.append(.brailleSign)
                    }
                    
                    // Detect crosswalk signals
                    if text.contains("walk") || text.contains("cross") {
                        features.append(.crosswalk(type: .signaled, hasSignal: true))
                    }
                }
                
                continuation.resume(returning: features)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectAccessibilityObjects(image: UIImage) async throws -> [AccessibilityFeature] {
        var features: [AccessibilityFeature] = []
        
        // Use existing vision processor for object detection
        let result = try await visionProcessor.detectObjects(in: image)
        
        for object in result.objects {
            let label = object.label.lowercased()
            
            // Detect doors
            if label.contains("door") {
                features.append(.door(isOpen: false, isAutomatic: false))
            }
            
            // Detect stairs
            if label.contains("stairs") || label.contains("steps") {
                features.append(.stairs(direction: .unknown, stepCount: nil))
            }
            
            // Detect dogs (might be guide dogs)
            if label.contains("dog") {
                features.append(.guideDog)
            }
        }
        
        return features
    }
    
    /// Classify crosswalk type
    func classifyCrosswalk(in image: UIImage, region: CGRect) async throws -> CrosswalkType {
        // Analyze the region for crosswalk patterns
        // This is a simplified version - in production, would use ML model
        return .zebra
    }
    
    /// Detect curb cuts using depth data
    func detectCurbCut(depthMap: [Float], width: Int, height: Int) -> [CGPoint] {
        var curbCuts: [CGPoint] = []
        
        // Analyze depth map for sudden elevation changes
        // Look for gradual slopes (curb cuts) vs sharp drops (curbs)
        let sampleRate = 10
        
        for y in stride(from: 0, to: height, by: sampleRate) {
            for x in stride(from: 0, to: width, by: sampleRate) {
                let index = y * width + x
                guard index < depthMap.count else { continue }
                
                let depth = depthMap[index]
                
                // Check neighboring depths for gradual slope
                if x + sampleRate < width && y + sampleRate < height {
                    let nextIndex = (y + sampleRate) * width + x
                    if nextIndex < depthMap.count {
                        let depthDiff = abs(depth - depthMap[nextIndex])
                        
                        // Gradual slope indicates curb cut
                        if depthDiff > 0.05 && depthDiff < 0.15 {
                            curbCuts.append(CGPoint(x: x, y: y))
                        }
                    }
                }
            }
        }
        
        return curbCuts
    }
    
    /// Generate spoken guidance for accessibility features
    func generateGuidance(for features: [AccessibilityFeature]) -> String {
        guard !features.isEmpty else {
            return "No accessibility features detected nearby"
        }
        
        // Prioritize most important features
        var guidance: [String] = []
        
        for feature in features.prefix(3) {
            guidance.append(feature.description)
        }
        
        return guidance.joined(separator: ". ")
    }
}
