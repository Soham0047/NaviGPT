//
//  ObstacleAudioManager.swift
//  NaviGPT
//
//  Phase 3: UI Integration
//  Manages audio feedback for detected obstacles using speech synthesis
//

import Foundation
import AVFoundation

/// Manages intelligent audio feedback for detected obstacles
@MainActor
class ObstacleAudioManager: ObservableObject {

    // MARK: - Properties

    private let speechManager = SpeechManager.shared
    private let hapticManager = HapticFeedbackManager.shared

    @Published var isEnabled: Bool = true
    @Published var lastAnnouncementTime: Date?

    // MARK: - Configuration

    struct Configuration {
        var minimumAnnouncementInterval: TimeInterval = 1.5 // Faster feedback
        var urgencyThreshold: Int = 0 // Announce all detected obstacles
        var maxObstaclesPerAnnouncement: Int = 3 // More objects per announcement
        var speechRate: Float = 0.6 // Faster speech for real-time
        var speakDistance: Bool = true
        var speakDirection: Bool = true // Enable direction for navigation
    }

    var configuration = Configuration()

    // MARK: - State Tracking

    private var lastAnnouncedObstacles: Set<String> = []
    private var announcementHistory: [Date] = []

    // MARK: - Public Methods

    /// Announce critical obstacles with intelligent filtering and debouncing
    func announceObstacles(_ obstacles: [ObstacleInfo]) {
        guard isEnabled else { return }

        // Filter obstacles by urgency
        let relevant = obstacles.filter { $0.distance < 10.0 }
        guard !relevant.isEmpty else { return }

        // Check debouncing
        if let last = lastAnnouncementTime,
           Date().timeIntervalSince(last) < configuration.minimumAnnouncementInterval {
            return
        }

        // Generate compact signature (label + approximate distance)
        let obstacleSignatures = Set(relevant.map { "\($0.type.displayName)-\(Int($0.distance))" })
        
        // Only announce if obstacles have changed significantly
        let hasNewObstacles = !obstacleSignatures.isSubset(of: lastAnnouncedObstacles)
        guard hasNewObstacles else { return }

        // Generate and speak announcement
        let description = generateObstacleDescription(relevant)
        speak(description, priority: .high)
        
        // Play haptic feedback for closest obstacle
        if let closest = relevant.first {
            hapticManager.playObstacleHaptic(
                distance: closest.distance,
                severity: closest.severity,
                direction: configuration.speakDirection ? closest.position.description : nil
            )
        }

        // Update state
        lastAnnouncementTime = Date()
        lastAnnouncedObstacles = obstacleSignatures
        announcementHistory.append(Date())

        // Clean up old history (keep last 10)
        if announcementHistory.count > 10 {
            announcementHistory.removeFirst(announcementHistory.count - 10)
        }
    }

    /// Announce spatial guidance from LiDAR processor
    func announceSpatialGuidance(_ guidance: [SpatialGuidance]) {
        guard isEnabled else { return }
        guard !guidance.isEmpty else { return }

        // Only announce high-intensity guidance
        let urgent = guidance.filter { $0.intensity > 0.7 }
        guard !urgent.isEmpty else { return }

        let description = generateSpatialDescription(urgent)
        speak(description, priority: .medium)
        
        // Play warning haptic for urgent guidance
        if urgent.contains(where: { $0.type == .immediateDanger }) {
            hapticManager.playHaptic(.warning)
        }
    }

    /// Announce path analysis warnings
    func announcePathAnalysis(_ analysis: PathAnalysis) {
        guard isEnabled else { return }

        if !analysis.clearPath && !analysis.warnings.isEmpty {
            let description = generatePathWarningDescription(analysis)
            speak(description, priority: .high)
        } else if analysis.clearPath {
            // Optionally announce clear path
            // speak("Path is clear", priority: .low)
        }
    }

    /// Stop any ongoing speech
    func stopSpeaking() {
        speechManager.stopSpeaking()
    }

    // MARK: - Private Methods

    private func speak(_ text: String, priority: Priority) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = configuration.speechRate

        // Adjust volume and pitch based on priority
        switch priority {
        case .high:
            utterance.volume = 1.0
            utterance.pitchMultiplier = 1.1
        case .medium:
            utterance.volume = 0.8
            utterance.pitchMultiplier = 1.0
        case .low:
            utterance.volume = 0.6
            utterance.pitchMultiplier = 0.9
        }

        // Interrupt for high priority
        let interrupt = (priority == .high)
        speechManager.speak(utterance, interrupt: interrupt)
    }

    private func generateObstacleDescription(_ obstacles: [ObstacleInfo]) -> String {
        // Sort by distance (closest first)
        let sorted = obstacles.sorted { $0.distance < $1.distance }

        // Take only the configured maximum
        let top = Array(sorted.prefix(configuration.maxObstaclesPerAnnouncement))

        // Generate descriptions
        let descriptions = top.map { obstacle -> String in
            var parts: [String] = []

            // Label
            parts.append(obstacle.type.displayName.lowercased())

            // Direction
            if configuration.speakDirection {
                parts.append(obstacle.position.description)
            }

            // Distance
            if configuration.speakDistance {
                let distanceText = formatDistance(Float(obstacle.distance))
                parts.append("at \(distanceText)")
            }

            return parts.joined(separator: " ")
        }

        // Create final message
        if descriptions.count == 1 {
            return "Caution: \(descriptions[0])"
        } else {
            return "Caution: " + descriptions.joined(separator: ", and ")
        }
    }

    private func generateSpatialDescription(_ guidance: [SpatialGuidance]) -> String {
        // Find the most urgent guidance
        guard let mostUrgent = guidance.max(by: { $0.intensity < $1.intensity }) else {
            return ""
        }

        let direction = getDirectionFromRadians(mostUrgent.direction)
        let distance = formatDistance(mostUrgent.distance)

        switch mostUrgent.type {
        case .movingObstacle:
            return "Warning: Moving obstacle \(direction) at \(distance)"
        case .immediateDanger:
            return "Danger: Immediate obstacle \(direction)"
        case .staticObstacle:
            return "Obstacle \(direction) at \(distance)"
        }
    }

    private func generatePathWarningDescription(_ analysis: PathAnalysis) -> String {
        let highPriority = analysis.warnings.filter { $0.severity == .high || $0.severity == .critical }

        if !highPriority.isEmpty {
            let count = highPriority.count
            if count == 1 {
                return "Warning: Path blocked ahead"
            } else {
                return "Warning: Multiple obstacles blocking path"
            }
        } else {
            return "Caution: Obstacles detected"
        }
    }

    private func getDirection(from bearing: Float?) -> String {
        guard let bearing = bearing else { return "ahead" }

        switch bearing {
        case -180...(-135): return "behind you on the left"
        case -135...(-90): return "to your left behind"
        case -90...(-45): return "on your left"
        case -45...(-15): return "slightly left"
        case -15...15: return "ahead"
        case 15...45: return "slightly right"
        case 45...90: return "on your right"
        case 90...135: return "to your right behind"
        case 135...180: return "behind you on the right"
        default: return "ahead"
        }
    }

    private func getDirectionFromRadians(_ radians: Float) -> String {
        let degrees = radians * 180 / .pi
        return getDirection(from: degrees)
    }

    private func formatDistance(_ distance: Float) -> String {
        if distance < 1.0 {
            return "less than one meter"
        } else if distance < 2.0 {
            return String(format: "%.1f meters", distance)
        } else {
            return "\(Int(distance)) meters"
        }
    }

    // MARK: - Supporting Types

    enum Priority {
        case low
        case medium
        case high
    }
}

// MARK: - Configuration Presets

extension ObstacleAudioManager.Configuration {
    static var verbose: Self {
        var config = Self()
        config.minimumAnnouncementInterval = 2.0
        config.maxObstaclesPerAnnouncement = 3
        config.speakDistance = true
        config.speakDirection = true
        return config
    }

    static var concise: Self {
        var config = Self()
        config.minimumAnnouncementInterval = 5.0
        config.maxObstaclesPerAnnouncement = 1
        config.speakDistance = true
        config.speakDirection = false
        return config
    }

    static var urgent: Self {
        var config = Self()
        config.minimumAnnouncementInterval = 1.0
        config.urgencyThreshold = 3 // Only critical
        config.maxObstaclesPerAnnouncement = 1
        config.speakDistance = false
        config.speakDirection = true
        return config
    }
}
