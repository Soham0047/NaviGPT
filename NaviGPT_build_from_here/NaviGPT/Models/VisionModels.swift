import Foundation
import CoreGraphics
import Vision

/// Represents detected objects from vision processing
struct VisionDetection: Identifiable {
    let id: UUID
    let label: String
    let confidence: Float
    let boundingBox: CGRect
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        label: String,
        confidence: Float,
        boundingBox: CGRect,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.timestamp = timestamp
    }
    
    /// Returns position relative to frame center
    var position: ObstaclePosition {
        let centerX = boundingBox.midX
        
        switch centerX {
        case 0..<0.2:
            return .farLeft
        case 0.2..<0.4:
            return .left
        case 0.4..<0.6:
            return .center
        case 0.6..<0.8:
            return .right
        default:
            return .farRight
        }
    }
    
    /// Estimated priority based on size and position
    var priority: Int {
        let sizeWeight = boundingBox.width * boundingBox.height
        let positionWeight: CGFloat = position == .center ? 1.5 : 1.0
        return Int(sizeWeight * positionWeight * 100)
    }
}

/// Text detected via OCR
struct TextDetection: Identifiable {
    let id: UUID
    let text: String
    let confidence: Float
    let boundingBox: CGRect
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        text: String,
        confidence: Float,
        boundingBox: CGRect,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.timestamp = timestamp
    }
}

/// Scene understanding result from multimodal LLM
struct SceneDescription {
    let summary: String
    let detailedDescription: String?
    let warnings: [String]
    let landmarks: [String]
    let navigationAdvice: String?
    let confidence: Float
    let timestamp: Date
    
    init(
        summary: String,
        detailedDescription: String? = nil,
        warnings: [String] = [],
        landmarks: [String] = [],
        navigationAdvice: String? = nil,
        confidence: Float = 1.0,
        timestamp: Date = Date()
    ) {
        self.summary = summary
        self.detailedDescription = detailedDescription
        self.warnings = warnings
        self.landmarks = landmarks
        self.navigationAdvice = navigationAdvice
        self.confidence = confidence
        self.timestamp = timestamp
    }
    
    /// Returns the most appropriate output for voice feedback
    var spokenOutput: String {
        var output = summary
        
        if !warnings.isEmpty {
            output += ". " + warnings.joined(separator: ". ")
        }
        
        if let advice = navigationAdvice {
            output += ". " + advice
        }
        
        return output
    }
}
