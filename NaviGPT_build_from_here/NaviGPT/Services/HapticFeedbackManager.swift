import UIKit
import CoreHaptics

/// Manages haptic feedback for navigation and obstacle detection
/// Provides distance-based vibration, directional cues, and obstacle type differentiation
@MainActor
class HapticFeedbackManager: ObservableObject {
    static let shared = HapticFeedbackManager()
    
    // MARK: - Properties
    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool = false
    
    @Published var isEnabled: Bool = true
    @Published var intensity: Double = 1.0 // 0.0 to 1.0
    
    // Debouncing
    private var lastHapticTime: Date = .distantPast
    private let minimumHapticInterval: TimeInterval = 0.3
    
    // MARK: - Haptic Pattern Types
    enum HapticPattern {
        case obstacleDetected(distance: Double, severity: ObstacleSeverity)
        case directionLeft(intensity: Double)
        case directionRight(intensity: Double)
        case directionAhead(intensity: Double)
        case clearPath
        case warning
        case navigationTurn(direction: String)
        case success
        case error
    }
    
    // MARK: - Initialization
    private init() {
        checkHapticsSupport()
        setupHapticEngine()
    }
    
    // MARK: - Setup
    
    /// Check if device supports haptics
    private func checkHapticsSupport() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        if !supportsHaptics {
            print("⚠️ Device does not support haptics")
        }
    }
    
    /// Initialize the haptic engine
    private func setupHapticEngine() {
        guard supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // Handle engine reset
            engine?.resetHandler = { [weak self] in
                print("🔄 Haptic engine reset")
                do {
                    try self?.engine?.start()
                } catch {
                    print("❌ Failed to restart haptic engine: \(error)")
                }
            }
            
            // Handle engine stopped
            engine?.stoppedHandler = { reason in
                print("⏹️ Haptic engine stopped: \(reason)")
            }
            
            print("✅ Haptic engine initialized")
        } catch {
            print("❌ Failed to create haptic engine: \(error)")
            supportsHaptics = false
        }
    }
    
    // MARK: - Public Interface
    
    /// Play haptic feedback for a specific pattern
    func playHaptic(_ pattern: HapticPattern) {
        guard isEnabled, supportsHaptics else { return }
        
        // Debouncing (except for critical warnings)
        if case .warning = pattern {
            // Allow warnings through
        } else if Date().timeIntervalSince(lastHapticTime) < minimumHapticInterval {
            return
        }
        
        lastHapticTime = Date()
        
        do {
            let events = createHapticEvents(for: pattern)
            let hapticPattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: hapticPattern)
            try player?.start(atTime: 0)
        } catch {
            print("❌ Failed to play haptic: \(error)")
        }
    }
    
    /// Play haptic for obstacle detection (primary use case)
    func playObstacleHaptic(distance: Double, severity: ObstacleSeverity, direction: String? = nil) {
        guard isEnabled else { return }
        
        // Play distance-based haptic
        playHaptic(.obstacleDetected(distance: distance, severity: severity))
        
        // Add directional haptic if provided
        if let direction = direction {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s delay
                if direction.contains("left") {
                    playHaptic(.directionLeft(intensity: calculateIntensity(distance: distance)))
                } else if direction.contains("right") {
                    playHaptic(.directionRight(intensity: calculateIntensity(distance: distance)))
                } else if direction.contains("ahead") || direction.contains("front") {
                    playHaptic(.directionAhead(intensity: calculateIntensity(distance: distance)))
                }
            }
        }
    }
    
    /// Simple notification haptics (non-Core Haptics)
    func playSimpleHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Pattern Creation
    
    /// Create haptic events for a specific pattern
    private func createHapticEvents(for pattern: HapticPattern) -> [CHHapticEvent] {
        switch pattern {
        case .obstacleDetected(let distance, let severity):
            return createObstaclePattern(distance: distance, severity: severity)
            
        case .directionLeft(let intensity):
            return createDirectionalPattern(direction: .left, intensity: intensity)
            
        case .directionRight(let intensity):
            return createDirectionalPattern(direction: .right, intensity: intensity)
            
        case .directionAhead(let intensity):
            return createDirectionalPattern(direction: .ahead, intensity: intensity)
            
        case .clearPath:
            return createClearPathPattern()
            
        case .warning:
            return createWarningPattern()
            
        case .navigationTurn(let direction):
            return createNavigationTurnPattern(direction: direction)
            
        case .success:
            return createSuccessPattern()
            
        case .error:
            return createErrorPattern()
        }
    }
    
    // MARK: - Specific Pattern Implementations
    
    /// Obstacle detection pattern: intensity increases as distance decreases
    private func createObstaclePattern(distance: Double, severity: ObstacleSeverity) -> [CHHapticEvent] {
        let baseIntensity = calculateIntensity(distance: distance)
        let adjustedIntensity = Float(min(baseIntensity * intensity, 1.0))
        
        // Shorter, sharper vibrations for closer obstacles
        let duration: TimeInterval = distance < 2.0 ? 0.15 : 0.1
        
        // More pulses for higher severity
        let pulseCount: Int
        switch severity {
        case .critical: pulseCount = 3
        case .urgent: pulseCount = 2
        case .warning: pulseCount = 2
        case .caution: pulseCount = 1
        case .info: pulseCount = 1
        }
        
        var events: [CHHapticEvent] = []
        for i in 0..<pulseCount {
            let time = TimeInterval(i) * (duration + 0.05)
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: adjustedIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: time
            ))
        }
        
        return events
    }
    
    /// Directional pattern: left/right/ahead
    private func createDirectionalPattern(direction: Direction, intensity: Double) -> [CHHapticEvent] {
        let adjustedIntensity = Float(min(intensity * self.intensity, 1.0))
        
        switch direction {
        case .left:
            // Two quick taps on the left
            return [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: adjustedIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: adjustedIntensity * 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0.1)
            ]
            
        case .right:
            // Two quick taps on the right (slightly longer interval)
            return [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: adjustedIntensity * 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: adjustedIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0.12)
            ]
            
        case .ahead:
            // Single strong tap
            return [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: adjustedIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ], relativeTime: 0)
            ]
        }
    }
    
    /// Clear path: gentle confirmation
    private func createClearPathPattern() -> [CHHapticEvent] {
        return [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.3 * intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0)
        ]
    }
    
    /// Warning: urgent attention needed
    private func createWarningPattern() -> [CHHapticEvent] {
        let warningIntensity = Float(0.9 * intensity)
        return [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: warningIntensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: warningIntensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ], relativeTime: 0.1),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: warningIntensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ], relativeTime: 0.2)
        ]
    }
    
    /// Navigation turn: rhythmic pattern for turns
    private func createNavigationTurnPattern(direction: String) -> [CHHapticEvent] {
        let turnIntensity = Float(0.6 * intensity)
        
        // "turn right" gets ascending intensity, "turn left" gets descending
        let intensities: [Float] = direction.contains("right") ? 
            [turnIntensity * 0.6, turnIntensity * 0.8, turnIntensity] :
            [turnIntensity, turnIntensity * 0.8, turnIntensity * 0.6]
        
        return intensities.enumerated().map { index, intensity in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: TimeInterval(index) * 0.15)
        }
    }
    
    /// Success: positive confirmation
    private func createSuccessPattern() -> [CHHapticEvent] {
        return [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.5 * intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.7 * intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0.1)
        ]
    }
    
    /// Error: negative feedback
    private func createErrorPattern() -> [CHHapticEvent] {
        return [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.7 * intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.5 * intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ], relativeTime: 0.08)
        ]
    }
    
    // MARK: - Helper Methods
    
    private enum Direction {
        case left, right, ahead
    }
    
    /// Calculate haptic intensity based on obstacle distance
    private func calculateIntensity(distance: Double) -> Double {
        // Closer = stronger vibration
        // 0-1m: 100% intensity
        // 1-3m: 70% intensity
        // 3-5m: 40% intensity
        // 5m+: 20% intensity
        
        if distance < 1.0 {
            return 1.0
        } else if distance < 3.0 {
            return 0.7
        } else if distance < 5.0 {
            return 0.4
        } else {
            return 0.2
        }
    }
    
    // MARK: - Lifecycle Management
    
    func stopEngine() {
        engine?.stop()
    }
    
    func restartEngine() {
        guard supportsHaptics else { return }
        do {
            try engine?.start()
        } catch {
            print("❌ Failed to restart haptic engine: \(error)")
        }
    }
}
