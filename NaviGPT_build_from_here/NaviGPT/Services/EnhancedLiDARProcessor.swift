//
//  EnhancedLiDARProcessor.swift
//  NaviGPT
//
//  Phase 3: Real-Time Processing & Integration
//  Advanced LiDAR processing with ML depth fusion and obstacle tracking
//

import Foundation
import ARKit
import CoreML
import simd

/// Enhanced LiDAR processor with ML depth fusion and real-time tracking
@MainActor
class EnhancedLiDARProcessor: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var isProcessing: Bool = false
    @Published var trackedObstacles: [TrackedObstacle] = []
    @Published var depthMap: DepthMap?
    @Published var spatialAudioGuidance: [SpatialGuidance] = []

    // MARK: - Dependencies
    private let depthEstimator: DepthEstimationProcessor?
    private var arSession: ARSession?

    // MARK: - Tracking State
    private var obstacleTracker: ObstacleTracker
    private var depthMapHistory: [DepthMap] = []
    private let maxHistorySize = 5

    // MARK: - Configuration
    struct Configuration {
        var enableMLDepthFusion: Bool = true
        var obstacleDistanceThreshold: Float = 5.0 // meters
        var trackingTimeout: TimeInterval = 2.0 // seconds
        var depthMapResolution: Int = 256
        var spatialAudioEnabled: Bool = true
    }

    var configuration = Configuration()

    // MARK: - Initialization
    init(depthEstimator: DepthEstimationProcessor? = nil) {
        self.depthEstimator = depthEstimator
        self.obstacleTracker = ObstacleTracker()
        super.init()
    }

    // MARK: - Public Methods

    /// Start LiDAR processing with AR session
    func startProcessing(with session: ARSession) {
        self.arSession = session
        self.isProcessing = true
    }

    /// Stop LiDAR processing
    func stopProcessing() {
        self.arSession = nil
        self.isProcessing = false
        self.trackedObstacles.removeAll()
        self.depthMapHistory.removeAll()
    }

    /// Process an AR frame with LiDAR data
    func processARFrame(_ frame: ARFrame) async throws -> EnhancedDepthResult {
        let startTime = Date()

        // Extract LiDAR depth data
        guard let depthData = frame.sceneDepth?.depthMap else {
            throw LiDARError.noDepthData
        }

        // Process depth map
        let processedDepthMap = processDepthMap(depthData, camera: frame.camera)

        // Fuse with ML depth estimation if enabled
        var fusedDepthMap = processedDepthMap
        if configuration.enableMLDepthFusion {
            fusedDepthMap = try await fuseWithMLDepth(processedDepthMap, frame: frame)
        }

        // Detect obstacles from depth data
        let detectedObstacles = detectObstacles(from: fusedDepthMap, frame: frame)

        // Track obstacles over time
        let tracked = obstacleTracker.updateTracking(with: detectedObstacles, timestamp: Date())
        self.trackedObstacles = tracked

        // Generate spatial audio guidance
        if configuration.spatialAudioEnabled {
            self.spatialAudioGuidance = generateSpatialGuidance(from: tracked)
        }

        // Store in history
        storeDepthMapInHistory(fusedDepthMap)

        let processingTime = Date().timeIntervalSince(startTime)

        return EnhancedDepthResult(
            depthMap: fusedDepthMap,
            obstacles: detectedObstacles,
            trackedObstacles: tracked,
            spatialGuidance: spatialAudioGuidance,
            processingTime: processingTime
        )
    }

    /// Get predictive path analysis based on tracked obstacles
    func getPredictivePathAnalysis() -> PathAnalysis {
        let movingObstacles = trackedObstacles.filter { $0.velocity.length > 0.1 }

        var warnings: [PathWarning] = []

        for obstacle in movingObstacles {
            // Predict future position (1 second ahead)
            let predictedPosition = obstacle.position + obstacle.velocity * 1.0

            // Check if predicted position intersects with user path
            if predictedPosition.z < 2.0 && abs(predictedPosition.x) < 1.0 {
                warnings.append(PathWarning(
                    type: .movingObstacle,
                    position: predictedPosition,
                    timeToImpact: calculateTimeToImpact(obstacle),
                    severity: .high
                ))
            }
        }

        return PathAnalysis(
            clearPath: warnings.isEmpty,
            warnings: warnings,
            recommendedDirection: calculateRecommendedDirection()
        )
    }

    // MARK: - Private Methods

    private func processDepthMap(_ depthData: CVPixelBuffer, camera: ARCamera) -> DepthMap {
        let width = CVPixelBufferGetWidth(depthData)
        let height = CVPixelBufferGetHeight(depthData)

        CVPixelBufferLockBaseAddress(depthData, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthData, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(depthData) else {
            return DepthMap(width: 0, height: 0, data: [], timestamp: Date())
        }

        let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
        let pixelCount = width * height
        var depthValues: [Float] = []

        for i in 0..<pixelCount {
            depthValues.append(floatBuffer[i])
        }

        return DepthMap(
            width: width,
            height: height,
            data: depthValues,
            timestamp: Date(),
            cameraTransform: camera.transform
        )
    }

    private func fuseWithMLDepth(_ lidarDepth: DepthMap, frame: ARFrame) async throws -> DepthMap {
        // This would integrate ML-based depth estimation with LiDAR data
        // For now, we'll use LiDAR as primary and ML as fallback
        // In future, implement weighted fusion based on confidence

        return lidarDepth // Placeholder for now
    }

    private func detectObstacles(from depthMap: DepthMap, frame: ARFrame) -> [DetectedObstacle] {
        var obstacles: [DetectedObstacle] = []

        // Grid-based obstacle detection
        let gridSize = 16
        let cellWidth = depthMap.width / gridSize
        let cellHeight = depthMap.height / gridSize

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let startIdx = (row * cellHeight * depthMap.width) + (col * cellWidth)

                var sumDepth: Float = 0
                var validCount = 0

                // Sample cell
                for y in 0..<cellHeight {
                    for x in 0..<cellWidth {
                        let idx = startIdx + (y * depthMap.width) + x
                        if idx < depthMap.data.count {
                            let depth = depthMap.data[idx]
                            if depth > 0.1 && depth < configuration.obstacleDistanceThreshold {
                                sumDepth += depth
                                validCount += 1
                            }
                        }
                    }
                }

                // If enough valid depth points, create obstacle
                if validCount > (cellWidth * cellHeight) / 4 {
                    let avgDepth = sumDepth / Float(validCount)

                    // Convert to 3D position
                    let centerX = Float(col) / Float(gridSize) - 0.5
                    let centerY = Float(row) / Float(gridSize) - 0.5

                    let position = SpatialPoint(
                        x: centerX * 2.0 * avgDepth,
                        y: centerY * 2.0 * avgDepth,
                        z: avgDepth
                    )

                    obstacles.append(DetectedObstacle(
                        id: UUID(),
                        position: position,
                        distance: avgDepth,
                        size: CGSize(
                            width: Double(cellWidth) / Double(depthMap.width),
                            height: Double(cellHeight) / Double(depthMap.height)
                        )
                    ))
                }
            }
        }

        return obstacles
    }

    private func generateSpatialGuidance(from obstacles: [TrackedObstacle]) -> [SpatialGuidance] {
        var guidance: [SpatialGuidance] = []

        // Generate guidance for obstacles within critical distance
        let criticalObstacles = obstacles.filter { $0.distance < 2.0 }

        for obstacle in criticalObstacles {
            let direction = atan2(obstacle.position.x, obstacle.position.z)
            let distance = obstacle.distance

            var intensity: Float
            if distance < 0.5 {
                intensity = 1.0 // Maximum warning
            } else if distance < 1.0 {
                intensity = 0.7
            } else {
                intensity = 0.4
            }

            guidance.append(SpatialGuidance(
                direction: direction,
                distance: distance,
                intensity: intensity,
                type: determineObstacleType(obstacle)
            ))
        }

        return guidance
    }

    private func determineObstacleType(_ obstacle: TrackedObstacle) -> GuidanceType {
        if obstacle.velocity.length > 0.5 {
            return .movingObstacle
        } else if obstacle.distance < 0.5 {
            return .immediateDanger
        } else {
            return .staticObstacle
        }
    }

    private func calculateTimeToImpact(_ obstacle: TrackedObstacle) -> TimeInterval {
        let velocity = obstacle.velocity.length
        if velocity < 0.01 {
            return .infinity
        }
        return Double(obstacle.distance / velocity)
    }

    private func calculateRecommendedDirection() -> Float {
        // Analyze tracked obstacles and suggest safest direction
        // Returns angle in radians (-π to π, 0 = straight ahead)

        guard !trackedObstacles.isEmpty else {
            return 0 // Straight ahead if no obstacles
        }

        // Check left and right sectors
        let leftObstacles = trackedObstacles.filter { $0.position.x < 0 && $0.distance < 3.0 }
        let rightObstacles = trackedObstacles.filter { $0.position.x > 0 && $0.distance < 3.0 }

        if leftObstacles.count < rightObstacles.count {
            return -.pi / 4 // Suggest left
        } else if rightObstacles.count < leftObstacles.count {
            return .pi / 4 // Suggest right
        }

        return 0 // Straight ahead
    }

    private func storeDepthMapInHistory(_ depthMap: DepthMap) {
        depthMapHistory.append(depthMap)
        if depthMapHistory.count > maxHistorySize {
            depthMapHistory.removeFirst()
        }
    }
}

// MARK: - Supporting Types

/// Represents a depth map with metadata
struct DepthMap {
    let width: Int
    let height: Int
    let data: [Float]
    let timestamp: Date
    var cameraTransform: simd_float4x4?

    func depthAt(x: Int, y: Int) -> Float? {
        guard x >= 0, x < width, y >= 0, y < height else {
            return nil
        }
        let index = y * width + x
        guard index < data.count else { return nil }
        return data[index]
    }
}

/// Tracked obstacle with temporal information
struct TrackedObstacle: Identifiable {
    let id: UUID
    var position: SpatialPoint
    var velocity: simd_float3
    var distance: Float
    var lastSeen: Date
    var detectionCount: Int
    var confidence: Float
}

/// Spatial audio guidance information
struct SpatialGuidance: Equatable {
    let direction: Float // radians
    let distance: Float // meters
    let intensity: Float // 0-1
    let type: GuidanceType
}

enum GuidanceType {
    case staticObstacle
    case movingObstacle
    case immediateDanger
}

/// Result of enhanced depth processing
struct EnhancedDepthResult {
    let depthMap: DepthMap
    let obstacles: [DetectedObstacle]
    let trackedObstacles: [TrackedObstacle]
    let spatialGuidance: [SpatialGuidance]
    let processingTime: TimeInterval
}

/// Path analysis with warnings
struct PathAnalysis {
    let clearPath: Bool
    let warnings: [PathWarning]
    let recommendedDirection: Float
}

struct PathWarning {
    enum WarningType {
        case staticObstacle
        case movingObstacle
        case suddenObstacle
    }

    enum Severity {
        case low, medium, high, critical
    }

    let type: WarningType
    let position: SpatialPoint
    let timeToImpact: TimeInterval
    let severity: Severity
}

// MARK: - Obstacle Tracker

/// Tracks obstacles across frames
class ObstacleTracker {
    private var trackedObstacles: [TrackedObstacle] = []
    private let matchingThreshold: Float = 0.5 // meters
    private let trackingTimeout: TimeInterval = 2.0

    func updateTracking(with detections: [DetectedObstacle], timestamp: Date) -> [TrackedObstacle] {
        var updatedTracking: [TrackedObstacle] = []
        var matchedDetections = Set<UUID>()

        // Match existing tracked obstacles with new detections
        for tracked in trackedObstacles {
            var bestMatch: DetectedObstacle?
            var bestDistance: Float = .infinity

            for detection in detections where !matchedDetections.contains(detection.id) {
                let distance = tracked.position.distance(to: detection.position)
                if distance < matchingThreshold && distance < bestDistance {
                    bestMatch = detection
                    bestDistance = distance
                }
            }

            if let match = bestMatch {
                // Update existing obstacle
                let timeDelta = Float(timestamp.timeIntervalSince(tracked.lastSeen))
                let velocity = (match.position - tracked.position) / timeDelta

                updatedTracking.append(TrackedObstacle(
                    id: tracked.id,
                    position: match.position,
                    velocity: simd_float3(velocity.x, velocity.y, velocity.z),
                    distance: match.distance,
                    lastSeen: timestamp,
                    detectionCount: tracked.detectionCount + 1,
                    confidence: min(1.0, tracked.confidence + 0.1)
                ))

                matchedDetections.insert(match.id)
            } else if timestamp.timeIntervalSince(tracked.lastSeen) < trackingTimeout {
                // Keep tracking even without detection (temporary occlusion)
                updatedTracking.append(tracked)
            }
        }

        // Add new detections as new tracked obstacles
        for detection in detections where !matchedDetections.contains(detection.id) {
            updatedTracking.append(TrackedObstacle(
                id: detection.id,
                position: detection.position,
                velocity: simd_float3(0, 0, 0),
                distance: detection.distance,
                lastSeen: timestamp,
                detectionCount: 1,
                confidence: 0.3
            ))
        }

        trackedObstacles = updatedTracking
        return trackedObstacles
    }
}

// MARK: - Helper Extensions

extension SpatialPoint {
    func distance(to other: SpatialPoint) -> Float {
        let dx = x - other.x
        let dy = y - other.y
        let dz = z - other.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }

    static func -(lhs: SpatialPoint, rhs: SpatialPoint) -> SpatialPoint {
        return SpatialPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    static func +(lhs: SpatialPoint, rhs: simd_float3) -> SpatialPoint {
        return SpatialPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    static func /(lhs: SpatialPoint, rhs: Float) -> SpatialPoint {
        return SpatialPoint(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs)
    }
}

extension simd_float3 {
    var length: Float {
        return sqrt(x*x + y*y + z*z)
    }

    static func *(lhs: simd_float3, rhs: Float) -> simd_float3 {
        return simd_float3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }
}

// MARK: - Error Types

enum LiDARError: Error, LocalizedError {
    case noDepthData
    case arSessionNotAvailable
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .noDepthData:
            return "No LiDAR depth data available"
        case .arSessionNotAvailable:
            return "AR session not available"
        case .processingFailed:
            return "LiDAR processing failed"
        }
    }
}
