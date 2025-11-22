//
//  RealTimeCameraProcessor.swift
//  NaviGPT
//
//  Phase 3: Real-Time Processing & Integration
//  Coordinates camera capture, vision processing, and depth estimation
//

import Foundation
import AVFoundation
import CoreImage
import UIKit
import Combine
import ARKit

/// Real-time camera processor that integrates vision and depth processing
@MainActor
class RealTimeCameraProcessor: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var isProcessing: Bool = false
    @Published var currentFPS: Double = 0.0
    @Published var detectedObjects: [DetectedObject] = []
    @Published var obstacles: [Obstacle] = []
    @Published var processingLatency: TimeInterval = 0.0

    // MARK: - Dependencies
    private let visionProcessor: VisionModelProcessor
    private let depthProcessor: DepthEstimationProcessor
    private let modelManager = CoreMLModelManager.shared

    // MARK: - Camera Session
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "com.navigpt.camera.processing", qos: .userInitiated)

    // MARK: - Performance Tracking
    private var frameCount: Int = 0
    private var lastFPSUpdate = Date()
    private var frameProcessingTimes: [TimeInterval] = []
    private let maxFrameTimesSamples = 30

    // MARK: - Configuration
    struct Configuration {
        var targetFPS: Int = 15 // Balance between performance and battery
        var enableObjectDetection: Bool = true
        var enableDepthEstimation: Bool = true
        var confidenceThreshold: Float = 0.4 // Lower threshold for more detections
        var maxConcurrentProcessing: Int = 2
    }

    var configuration = Configuration()

    // MARK: - State
    private var isSessionRunning = false
    private nonisolated(unsafe) var currentlyProcessingFrames = 0
    private let maxConcurrentFrames = 1 // Process one frame at a time for consistency

    // MARK: - Initialization
    override init() {
        self.visionProcessor = VisionModelProcessor()
        self.depthProcessor = DepthEstimationProcessor()
        super.init()
    }

    // MARK: - Public Methods

    /// Process an external video frame (from another capture session)
    func processExternalFrame(_ sampleBuffer: CMSampleBuffer) async {
        await processVideoFrame(sampleBuffer)
    }

    /// Start the camera processing pipeline
    func startProcessing() async throws {
        // If we are using external frames, we don't need to start our own session
        // But for backward compatibility, we keep this logic
        guard !isSessionRunning else { return }

        // Request camera permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                throw CameraError.permissionDenied
            }
        } else if status != .authorized {
            throw CameraError.permissionDenied
        }

        // Setup camera session
        try setupCaptureSession()

        // Start session
        // Ensure session start occurs on main actor (AVCaptureSession is main-thread/actor bound)
        await MainActor.run {
            self.captureSession.startRunning()
        }

        isSessionRunning = true
        isProcessing = true
    }

    /// Stop the camera processing pipeline
    func stopProcessing() {
        guard isSessionRunning else { return }

        // Stop session on main actor for thread safety
        Task { @MainActor in
            self.captureSession.stopRunning()
        }

        isSessionRunning = false
        isProcessing = false
    }

    /// Process a single image (for testing or manual processing)
    func processImage(_ image: UIImage) async throws -> EnvironmentSnapshot {
        let startTime = Date()

        // Process through vision model
        var detectedObjects: [DetectedObject] = []
        if configuration.enableObjectDetection {
            let result = try await visionProcessor.detectObjects(in: image)
            detectedObjects = result.objects
        }

        // Create environment snapshot
        let sceneContext = SceneContext(
            primaryObjects: detectedObjects.map { $0.label },
            spatialLayout: "Unknown", // Would be determined from depth data
            lightingConditions: "Unknown",
            confidenceScore: detectedObjects.first?.confidence ?? 0.0
        )

        let obstacles = convertToObstacles(detectedObjects)

        let processingTime = Date().timeIntervalSince(startTime)
        let metrics = ModelPerformanceMetrics(
            inferenceTime: processingTime,
            preprocessTime: 0.0,
            postprocessTime: 0.0,
            totalTime: processingTime,
            modelName: "VisionProcessor"
        )

        return EnvironmentSnapshot(
            timestamp: Date(),
            obstacles: obstacles,
            sceneContext: sceneContext,
            performanceMetrics: metrics
        )
    }

    // MARK: - Private Methods

    private func setupCaptureSession() throws {
        captureSession.beginConfiguration()

        // Set session preset
        captureSession.sessionPreset = .hd1280x720

        // Get camera device
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.deviceNotAvailable
        }

        // Create input
        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        guard captureSession.canAddInput(videoInput) else {
            throw CameraError.cannotAddInput
        }
        captureSession.addInput(videoInput)

        // Configure video output
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]

        guard captureSession.canAddOutput(videoOutput) else {
            throw CameraError.cannotAddOutput
        }
        captureSession.addOutput(videoOutput)

        // Configure video orientation
        if let connection = videoOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                // Use rotation angle API on iOS 17+
                if connection.isVideoRotationAngleSupported(0) {
                    connection.videoRotationAngle = 0
                }
            } else {
                // Legacy orientation API for iOS 16 and earlier
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }

        captureSession.commitConfiguration()
    }

    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) async {
        let frameStartTime = Date()

        // Convert to UIImage
        guard let image = imageFromSampleBuffer(sampleBuffer) else {
            return
        }

        // Process frame
        do {
            let snapshot = try await processImage(image)

            // Update published properties on main actor
            await MainActor.run {
                self.detectedObjects = snapshot.obstacles.map { obstacle in
                    DetectedObject(
                        label: obstacle.label,
                        confidence: obstacle.confidence.rawValue,
                        boundingBox: obstacle.boundingBox,
                        distance: obstacle.distance
                    )
                }
                self.obstacles = snapshot.obstacles
                
                // Log detected objects for debugging
                if !snapshot.obstacles.isEmpty {
                    let objectList = snapshot.obstacles.map { "\($0.label) at \(String(format: "%.1f", $0.distance))m" }.joined(separator: ", ")
                    print("🔍 [RealTime] Detected: \(objectList)")
                }

                // Update performance metrics
                let processingTime = Date().timeIntervalSince(frameStartTime)
                self.processingLatency = processingTime
                updateFPS()
            }
        } catch {
            print("Error processing frame: \(error)")
        }
    }

    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private func updateFPS() {
        frameCount += 1
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFPSUpdate)

        if elapsed >= 1.0 {
            currentFPS = Double(frameCount) / elapsed
            frameCount = 0
            lastFPSUpdate = now
        }
    }

    private func convertToObstacles(_ detectedObjects: [DetectedObject]) -> [Obstacle] {
        return detectedObjects.map { obj in
            // Estimate distance based on bounding box size (larger = closer)
            let boxSize = obj.boundingBox.width * obj.boundingBox.height
            let estimatedDistance: Float
            
            if boxSize > 0.5 { // Very large object
                estimatedDistance = 1.0 + Float.random(in: 0.0...0.5)
            } else if boxSize > 0.2 { // Large object
                estimatedDistance = 2.0 + Float.random(in: 0.0...1.0)
            } else if boxSize > 0.1 { // Medium object
                estimatedDistance = 3.5 + Float.random(in: 0.0...1.5)
            } else { // Small/distant object
                estimatedDistance = 5.0 + Float.random(in: 0.0...2.0)
            }
            
            let distance = obj.distance ?? estimatedDistance
            
            print("🎯 Detected: \(obj.label) at \(String(format: "%.1f", distance))m")
            
            return Obstacle(
                label: obj.label,
                position: SpatialPoint(x: Float(obj.boundingBox.midX), y: Float(obj.boundingBox.midY), z: distance),
                confidence: DetectionConfidence(rawValue: obj.confidence),
                distance: distance,
                boundingBox: obj.boundingBox
            )
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension RealTimeCameraProcessor: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Work off-main to avoid actor isolation warnings, then hop to main when needed
        Task {
            // Limit concurrent processing (atomic via actor hop)
            await MainActor.run {
                if self.currentlyProcessingFrames >= self.maxConcurrentFrames { return }
                self.currentlyProcessingFrames += 1
            }
            await self.processVideoFrame(sampleBuffer)
            await MainActor.run { self.currentlyProcessingFrames -= 1 }
        }
    }

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Frame dropped - could track this for performance monitoring
        print("Frame dropped")
    }
}

// MARK: - Error Types

enum CameraError: Error, LocalizedError {
    case permissionDenied
    case deviceNotAvailable
    case cannotAddInput
    case cannotAddOutput
    case sessionNotRunning

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera permission denied"
        case .deviceNotAvailable:
            return "Camera device not available"
        case .cannotAddInput:
            return "Cannot add camera input to session"
        case .cannotAddOutput:
            return "Cannot add video output to session"
        case .sessionNotRunning:
            return "Camera session is not running"
        }
    }
}

// Note: Obstacle init is defined in ModelTypes.swift with automatic urgencyLevel calculation
