//
//  DepthEstimationProcessor.swift
//  NaviGPT
//
//  Created by NaviGPT Team on 11/17/25.
//  Processes depth information from camera and CoreML models
//

import Foundation
import CoreML
import Vision
import UIKit
import ARKit
import os.log

/// Represents depth information at a specific point
struct DepthPoint {
    let x: Float
    let y: Float
    let depth: Float // in meters
    let confidence: Float
}

/// Result of depth estimation
struct DepthEstimationResult {
    let depthMap: CVPixelBuffer?
    let averageDepth: Float
    let minDepth: Float
    let maxDepth: Float
    let depthPoints: [DepthPoint]
    let processingTime: TimeInterval
    let timestamp: Date
}

/// Configuration for depth processing
struct DepthProcessingConfig {
    var useARKitDepth: Bool = true // Use LiDAR if available
    var useCoreMLDepth: Bool = true // Use ML model for depth estimation
    var samplingRate: Int = 10 // Sample every Nth pixel for performance
    var maxDepthRange: Float = 10.0 // Maximum depth in meters
}

/// Processor for depth estimation and analysis
@MainActor
class DepthEstimationProcessor: ObservableObject {
    
    // MARK: - Properties
    @Published var isProcessing: Bool = false
    @Published var lastResult: DepthEstimationResult?
    @Published var hasLiDAR: Bool = false
    
    private let modelManager = CoreMLModelManager.shared
    private let logger = Logger(subsystem: "com.navigpt.depth", category: "DepthEstimationProcessor")
    
    private var config = DepthProcessingConfig()
    
    // MARK: - Initialization
    
    init() {
        checkLiDARAvailability()
    }
    
    private func checkLiDARAvailability() {
        if #available(iOS 14.0, *) {
            hasLiDAR = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
            logger.info("LiDAR available: \(self.hasLiDAR)")
        } else {
            hasLiDAR = false
        }
    }
    
    // MARK: - Depth Estimation
    
    /// Estimate depth from an image using CoreML
    func estimateDepth(from image: UIImage) async throws -> DepthEstimationResult {
        let startTime = Date()
        isProcessing = true
        defer { isProcessing = false }
        
        logger.info("Starting depth estimation from image")
        
        // Ensure model is loaded
        if !modelManager.isModelLoaded(.depthEstimation) {
            try await modelManager.loadModel(.depthEstimation)
        }
        
        let visionModel = try modelManager.getVisionModel(.depthEstimation)
        
        guard let ciImage = CIImage(image: image) else {
            throw ModelError.invalidInput("Failed to convert image")
        }
        
        let request = VNCoreMLRequest(model: visionModel)
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                
                guard let results = request.results as? [VNPixelBufferObservation],
                      let depthBuffer = results.first?.pixelBuffer else {
                    throw ModelError.processingFailed("No depth map generated")
                }
                
                let depthInfo = self.analyzeDepthMap(depthBuffer)
                let processingTime = Date().timeIntervalSince(startTime)
                
                let result = DepthEstimationResult(
                    depthMap: depthBuffer,
                    averageDepth: depthInfo.average,
                    minDepth: depthInfo.min,
                    maxDepth: depthInfo.max,
                    depthPoints: depthInfo.points,
                    processingTime: processingTime,
                    timestamp: Date()
                )
                
                self.lastResult = result
                self.logger.info("Depth estimation complete: avg=\(depthInfo.average)m, time=\(processingTime)s")
                
                continuation.resume(returning: result)
            } catch {
                self.logger.error("Depth estimation failed: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Process depth from ARFrame (LiDAR-based)
    func processARDepth(from frame: ARFrame) async throws -> DepthEstimationResult {
        let startTime = Date()
        isProcessing = true
        defer { isProcessing = false }
        
        logger.info("Processing ARKit depth data")
        
        guard let depthData = frame.sceneDepth else {
            throw ModelError.processingFailed("No depth data available in ARFrame")
        }
        
        let depthMap = depthData.depthMap
        let depthInfo = analyzeDepthMap(depthMap)
        let processingTime = Date().timeIntervalSince(startTime)
        
        let result = DepthEstimationResult(
            depthMap: depthMap,
            averageDepth: depthInfo.average,
            minDepth: depthInfo.min,
            maxDepth: depthInfo.max,
            depthPoints: depthInfo.points,
            processingTime: processingTime,
            timestamp: Date()
        )
        
        lastResult = result
        logger.info("ARKit depth processed: avg=\(depthInfo.average)m")
        
        return result
    }
    
    /// Hybrid depth estimation combining LiDAR and ML model
    func estimateDepthHybrid(from frame: ARFrame, image: UIImage) async throws -> DepthEstimationResult {
        logger.info("Starting hybrid depth estimation")
        
        if hasLiDAR && config.useARKitDepth {
            // Prefer LiDAR if available
            return try await processARDepth(from: frame)
        } else if config.useCoreMLDepth {
            // Fall back to ML-based depth estimation
            return try await estimateDepth(from: image)
        } else {
            throw ModelError.processingFailed("No depth estimation method available")
        }
    }
    
    // MARK: - Depth Analysis
    
    private func analyzeDepthMap(_ depthMap: CVPixelBuffer) -> (average: Float, min: Float, max: Float, points: [DepthPoint]) {
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
            return (0, 0, 0, [])
        }
        
        let buffer = baseAddress.assumingMemoryBound(to: Float32.self)
        
        var sum: Float = 0
        var minDepth: Float = Float.greatestFiniteMagnitude
        var maxDepth: Float = 0
        var count: Int = 0
        var depthPoints: [DepthPoint] = []
        
        // Sample depth values
        for y in stride(from: 0, to: height, by: config.samplingRate) {
            for x in stride(from: 0, to: width, by: config.samplingRate) {
                let index = y * (bytesPerRow / MemoryLayout<Float32>.size) + x
                let depth = buffer[index]
                
                // Filter invalid depths
                guard depth > 0 && depth < config.maxDepthRange else { continue }
                
                sum += depth
                minDepth = min(minDepth, depth)
                maxDepth = max(maxDepth, depth)
                count += 1
                
                // Store sampled points
                if depthPoints.count < 100 { // Limit stored points
                    let point = DepthPoint(
                        x: Float(x) / Float(width),
                        y: Float(y) / Float(height),
                        depth: depth,
                        confidence: 1.0
                    )
                    depthPoints.append(point)
                }
            }
        }
        
        let average = count > 0 ? sum / Float(count) : 0
        return (average, minDepth == Float.greatestFiniteMagnitude ? 0 : minDepth, maxDepth, depthPoints)
    }
    
    /// Get depth at a specific normalized screen coordinate (0-1 range)
    func getDepthAt(normalizedPoint: CGPoint, from depthMap: CVPixelBuffer) -> Float? {
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
            return nil
        }
        
        let x = Int(normalizedPoint.x * CGFloat(width))
        let y = Int(normalizedPoint.y * CGFloat(height))
        
        guard x >= 0, x < width, y >= 0, y < height else {
            return nil
        }
        
        let buffer = baseAddress.assumingMemoryBound(to: Float32.self)
        let index = y * (bytesPerRow / MemoryLayout<Float32>.size) + x
        let depth = buffer[index]
        
        return depth > 0 ? depth : nil
    }
    
    // MARK: - Obstacle Detection
    
    /// Detect obstacles based on depth thresholds
    func detectObstacles(from result: DepthEstimationResult, proximityThreshold: Float = 2.0) -> [DepthPoint] {
        return result.depthPoints.filter { $0.depth < proximityThreshold && $0.depth > 0.1 }
    }
    
    /// Get spatial audio description of depth information
    func describeDepthScenario(_ result: DepthEstimationResult) -> String {
        let obstacles = detectObstacles(from: result)
        
        if obstacles.isEmpty {
            if result.averageDepth > 5.0 {
                return "Clear path ahead, average distance \(String(format: "%.1f", result.averageDepth)) meters"
            } else {
                return "Objects detected at \(String(format: "%.1f", result.averageDepth)) meters average"
            }
        } else {
            let closestObstacle = obstacles.min(by: { $0.depth < $1.depth })!
            return "Warning: Obstacle detected at \(String(format: "%.1f", closestObstacle.depth)) meters"
        }
    }
    
    // MARK: - Configuration
    
    func updateConfig(_ newConfig: DepthProcessingConfig) {
        config = newConfig
        logger.info("Depth processing config updated")
    }
}
