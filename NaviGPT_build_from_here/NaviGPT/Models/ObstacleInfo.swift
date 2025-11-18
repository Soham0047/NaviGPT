import Foundation
import CoreLocation
import CoreGraphics

/// Represents information about a detected obstacle
struct ObstacleInfo: Identifiable, Equatable {
    let id: UUID
    let type: ObstacleType
    let distance: Double // meters
    let position: ObstaclePosition
    let confidence: Float // 0.0 to 1.0
    let timestamp: Date
    let location: CGPoint? // position in camera frame
    
    init(
        id: UUID = UUID(),
        type: ObstacleType,
        distance: Double,
        position: ObstaclePosition,
        confidence: Float = 1.0,
        timestamp: Date = Date(),
        location: CGPoint? = nil
    ) {
        self.id = id
        self.type = type
        self.distance = distance
        self.position = position
        self.confidence = confidence
        self.timestamp = timestamp
        self.location = location
    }
    
    /// Returns severity level based on distance
    var severity: ObstacleSeverity {
        switch distance {
        case 0..<0.5:
            return .critical
        case 0.5..<1.0:
            return .urgent
        case 1.0..<2.0:
            return .warning
        case 2.0..<3.0:
            return .caution
        default:
            return .info
        }
    }
    
    /// Returns appropriate vibration intensity
    var vibrationIntensity: Double {
        switch severity {
        case .critical:
            return 1.0
        case .urgent:
            return 0.8
        case .warning:
            return 0.6
        case .caution:
            return 0.4
        case .info:
            return 0.2
        }
    }
    
    /// Returns vibration interval in seconds
    var vibrationInterval: TimeInterval {
        switch severity {
        case .critical:
            return 0.2
        case .urgent:
            return 0.5
        case .warning:
            return 1.0
        case .caution:
            return 1.5
        case .info:
            return 3.0
        }
    }
}

enum ObstacleType: String, Codable, CaseIterable {
    case person
    case vehicle
    case bicycle
    case animal
    case furniture
    case wall
    case door
    case stairs
    case curb
    case pole
    case tree
    case construction
    case unknown
    
    var displayName: String {
        switch self {
        case .person: return "Person"
        case .vehicle: return "Vehicle"
        case .bicycle: return "Bicycle"
        case .animal: return "Animal"
        case .furniture: return "Furniture"
        case .wall: return "Wall"
        case .door: return "Door"
        case .stairs: return "Stairs"
        case .curb: return "Curb"
        case .pole: return "Pole"
        case .tree: return "Tree"
        case .construction: return "Construction"
        case .unknown: return "Obstacle"
        }
    }
    
    var isMoving: Bool {
        [.person, .vehicle, .bicycle, .animal].contains(self)
    }
}

enum ObstaclePosition: String, Codable {
    case center
    case left
    case right
    case farLeft
    case farRight
    
    var clockPosition: String {
        switch self {
        case .center: return "12 o'clock"
        case .left: return "10 o'clock"
        case .right: return "2 o'clock"
        case .farLeft: return "9 o'clock"
        case .farRight: return "3 o'clock"
        }
    }
    
    var description: String {
        switch self {
        case .center: return "ahead"
        case .left: return "on your left"
        case .right: return "on your right"
        case .farLeft: return "far left"
        case .farRight: return "far right"
        }
    }
}

enum ObstacleSeverity: Int, Comparable {
    case info = 0
    case caution = 1
    case warning = 2
    case urgent = 3
    case critical = 4
    
    static func < (lhs: ObstacleSeverity, rhs: ObstacleSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
