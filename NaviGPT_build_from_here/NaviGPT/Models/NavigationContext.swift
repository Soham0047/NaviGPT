import Foundation
import CoreLocation

/// Represents navigation context and state
struct NavigationContext {
    let currentLocation: CLLocation?
    let destination: CLLocation?
    let routeSteps: [NavigationStep]
    let currentStepIndex: Int
    let distanceToNextStep: Double?
    let bearing: Double? // degrees from north
    
    var currentStep: NavigationStep? {
        guard currentStepIndex < routeSteps.count else { return nil }
        return routeSteps[currentStepIndex]
    }
    
    var nextStep: NavigationStep? {
        let nextIndex = currentStepIndex + 1
        guard nextIndex < routeSteps.count else { return nil }
        return routeSteps[nextIndex]
    }
    
    var isNavigating: Bool {
        destination != nil && !routeSteps.isEmpty
    }
    
    var progress: Double {
        guard !routeSteps.isEmpty else { return 0.0 }
        return Double(currentStepIndex) / Double(routeSteps.count)
    }
}

struct NavigationStep: Identifiable {
    let id: UUID
    let instruction: String
    let distance: Double // meters
    let coordinate: CLLocationCoordinate2D
    let maneuver: ManeuverType
    let streetName: String?
    
    init(
        id: UUID = UUID(),
        instruction: String,
        distance: Double,
        coordinate: CLLocationCoordinate2D,
        maneuver: ManeuverType,
        streetName: String? = nil
    ) {
        self.id = id
        self.instruction = instruction
        self.distance = distance
        self.coordinate = coordinate
        self.maneuver = maneuver
        self.streetName = streetName
    }
}

enum ManeuverType: String, Codable {
    case straight = "continue"
    case turnLeft = "turn_left"
    case turnRight = "turn_right"
    case sharpLeft = "sharp_left"
    case sharpRight = "sharp_right"
    case slightLeft = "slight_left"
    case slightRight = "slight_right"
    case uturn = "u_turn"
    case arrive = "arrive"
    case depart = "depart"
    
    var description: String {
        switch self {
        case .straight: return "Continue straight"
        case .turnLeft: return "Turn left"
        case .turnRight: return "Turn right"
        case .sharpLeft: return "Make a sharp left"
        case .sharpRight: return "Make a sharp right"
        case .slightLeft: return "Bear left"
        case .slightRight: return "Bear right"
        case .uturn: return "Make a U-turn"
        case .arrive: return "Arrive at destination"
        case .depart: return "Start your route"
        }
    }
}
