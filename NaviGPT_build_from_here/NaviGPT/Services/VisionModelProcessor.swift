//
//  VisionModelProcessor.swift
//  NaviGPT
//
//  Created by NaviGPT Team on 11/17/25.
//  Processes images using Vision and CoreML for object detection
//

import Foundation
import Vision
import CoreML
import UIKit
import os.log

/// Represents a detected object in an image
struct DetectedObject: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect
    let distance: Float? // Optional distance from LiDAR if available
}

/// Result of vision processing
struct VisionProcessingResult {
    let objects: [DetectedObject]
    let processingTime: TimeInterval
    let timestamp: Date
}

/// Processor for vision-based model inference
@MainActor
class VisionModelProcessor: ObservableObject {
    
    // MARK: - Properties
    @Published var isProcessing: Bool = false
    @Published var lastResult: VisionProcessingResult?
    
    private let modelManager = CoreMLModelManager.shared
    private let logger = Logger(subsystem: "com.navigpt.vision", category: "VisionModelProcessor")
    
    // Processing configuration
    private let confidenceThreshold: Float = 0.3 // Lower threshold to catch more objects
    private let maxDetections: Int = 20 // Detect more objects simultaneously
    
    // MARK: - Object Detection
    
    /// Perform object detection on an image
    func detectObjects(in image: UIImage, modelType: ModelType = .objectDetection) async throws -> VisionProcessingResult {
        let startTime = Date()
        isProcessing = true
        defer { isProcessing = false }

        logger.info("Starting object detection")

        // Ensure model is loaded
        if !modelManager.isModelLoaded(modelType) {
            try await modelManager.loadModel(modelType)
        }

        // Convert UIImage to CIImage
        guard let ciImage = CIImage(image: image) else {
            throw ModelError.invalidInput("Failed to convert UIImage to CIImage")
        }

        // Check if using built-in Vision or custom model
        if modelManager.usingBuiltInModels.contains(modelType) {
            logger.info("Using built-in Vision object detection")
            return try await performBuiltInObjectDetection(ciImage: ciImage, startTime: startTime)
        }

        // Use YOLOv8 CoreML model for real object detection
        let visionModel = try modelManager.getVisionModel(modelType)
        logger.info("Using YOLOv8 model for detection")
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            if let error = error {
                self?.logger.error("Detection request failed: \(error.localizedDescription)")
                return
            }
        }

        request.imageCropAndScaleOption = .scaleFill

        // Perform the request
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])

                let detectedObjects = self.parseDetectionResults(request.results)
                let processingTime = Date().timeIntervalSince(startTime)

                let result = VisionProcessingResult(
                    objects: detectedObjects,
                    processingTime: processingTime,
                    timestamp: Date()
                )

                self.lastResult = result
                self.logger.info("Detection complete: \(detectedObjects.count) objects found in \(processingTime)s")

                continuation.resume(returning: result)
            } catch {
                self.logger.error("Detection failed: \(error.localizedDescription)")
                continuation.resume(throwing: ModelError.processingFailed(error.localizedDescription))
            }
        }
    }

    /// Perform detection using built-in Vision capabilities
    private func performBuiltInDetection(ciImage: CIImage, startTime: Date) async throws -> VisionProcessingResult {
        // Use VNRecognizeAnimalsRequest as a fallback (detects dogs, cats)
        let request = VNRecognizeAnimalsRequest()

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])

                guard let observations = request.results else {
                    let result = VisionProcessingResult(
                        objects: [],
                        processingTime: Date().timeIntervalSince(startTime),
                        timestamp: Date()
                    )
                    continuation.resume(returning: result)
                    return
                }

                let detectedObjects = observations
                    .filter { $0.confidence >= confidenceThreshold }
                    .prefix(maxDetections)
                    .map { observation in
                        DetectedObject(
                            label: observation.labels.first?.identifier.capitalized ?? "Animal",
                            confidence: observation.confidence,
                            boundingBox: observation.boundingBox,
                            distance: nil
                        )
                    }

                let processingTime = Date().timeIntervalSince(startTime)
                let result = VisionProcessingResult(
                    objects: Array(detectedObjects),
                    processingTime: processingTime,
                    timestamp: Date()
                )

                self.lastResult = result
                self.logger.info("Built-in detection complete: \(detectedObjects.count) objects found")

                continuation.resume(returning: result)
            } catch {
                self.logger.error("Built-in detection failed: \(error.localizedDescription)")
                continuation.resume(throwing: ModelError.processingFailed(error.localizedDescription))
            }
        }
    }
    
    /// Perform general object detection using built-in Vision (people, faces, text)
    private func performBuiltInObjectDetection(ciImage: CIImage, startTime: Date) async throws -> VisionProcessingResult {
        var allDetectedObjects: [DetectedObject] = []
        
        // Detect humans
        let humanRequest = VNDetectHumanRectanglesRequest()
        
        // Detect faces
        let faceRequest = VNDetectFaceRectanglesRequest()
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([humanRequest, faceRequest])
                
                // Process human detections
                if let humanObservations = humanRequest.results {
                    let humans = humanObservations
                        .filter { $0.confidence >= confidenceThreshold }
                        .prefix(5)
                        .map { observation in
                            DetectedObject(
                                label: "person",
                                confidence: observation.confidence,
                                boundingBox: observation.boundingBox,
                                distance: nil
                            )
                        }
                    allDetectedObjects.append(contentsOf: humans)
                }
                
                // Process face detections (backup for people detection)
                if let faceObservations = faceRequest.results, allDetectedObjects.isEmpty {
                    let faces = faceObservations
                        .filter { $0.confidence >= confidenceThreshold }
                        .prefix(5)
                        .map { observation in
                            DetectedObject(
                                label: "person",
                                confidence: observation.confidence,
                                boundingBox: observation.boundingBox,
                                distance: nil
                            )
                        }
                    allDetectedObjects.append(contentsOf: faces)
                }
                
                let processingTime = Date().timeIntervalSince(startTime)
                let result = VisionProcessingResult(
                    objects: Array(allDetectedObjects.prefix(maxDetections)),
                    processingTime: processingTime,
                    timestamp: Date()
                )
                
                self.lastResult = result
                self.logger.info("Built-in object detection: \(allDetectedObjects.count) objects found")
                
                continuation.resume(returning: result)
            } catch {
                self.logger.error("Built-in object detection failed: \(error.localizedDescription)")
                continuation.resume(throwing: ModelError.processingFailed(error.localizedDescription))
            }
        }
    }
    
    /// Perform object detection on a CVPixelBuffer (for real-time camera processing)
    func detectObjects(in pixelBuffer: CVPixelBuffer, modelType: ModelType = .objectDetection) async throws -> VisionProcessingResult {
        let startTime = Date()
        isProcessing = true
        defer { isProcessing = false }
        
        // Ensure model is loaded
        if !modelManager.isModelLoaded(modelType) {
            try await modelManager.loadModel(modelType)
        }
        
        let visionModel = try modelManager.getVisionModel(modelType)
        
        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .scaleFill
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                
                let detectedObjects = self.parseDetectionResults(request.results)
                let processingTime = Date().timeIntervalSince(startTime)
                
                let result = VisionProcessingResult(
                    objects: detectedObjects,
                    processingTime: processingTime,
                    timestamp: Date()
                )
                
                self.lastResult = result
                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: ModelError.processingFailed(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Scene Understanding
    
    /// Classify scene/environment type
    func classifyScene(in image: UIImage) async throws -> (label: String, confidence: Float) {
        logger.info("Starting scene classification")
        
        if !modelManager.isModelLoaded(.sceneUnderstanding) {
            try await modelManager.loadModel(.sceneUnderstanding)
        }
        
        let visionModel = try modelManager.getVisionModel(.sceneUnderstanding)
        let request = VNCoreMLRequest(model: visionModel)
        
        guard let ciImage = CIImage(image: image) else {
            throw ModelError.invalidInput("Failed to convert image")
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try handler.perform([request])
        
        guard let results = request.results as? [VNClassificationObservation],
              let topResult = results.first else {
            throw ModelError.processingFailed("No classification results")
        }
        
        logger.info("Scene classified as: \(topResult.identifier) (\(topResult.confidence))")
        return (topResult.identifier, topResult.confidence)
    }
    
    // MARK: - Text Recognition (OCR)
    
    /// Recognize text in an image
    func recognizeText(in image: UIImage) async throws -> [String] {
        logger.info("Starting text recognition")
        
        guard let ciImage = CIImage(image: image) else {
            throw ModelError.invalidInput("Failed to convert image")
        }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                
                guard let observations = request.results else {
                    continuation.resume(returning: [])
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                self.logger.info("Recognized \(recognizedStrings.count) text items")
                continuation.resume(returning: recognizedStrings)
            } catch {
                continuation.resume(throwing: ModelError.processingFailed(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseDetectionResults(_ results: [Any]?) -> [DetectedObject] {
        guard let results = results as? [VNRecognizedObjectObservation] else {
            return []
        }
        
        return results
            .filter { $0.confidence >= confidenceThreshold }
            .prefix(maxDetections)
            .map { observation in
                DetectedObject(
                    label: observation.labels.first?.identifier ?? "Unknown",
                    confidence: observation.confidence,
                    boundingBox: observation.boundingBox,
                    distance: nil // Will be populated by LiDAR integration
                )
            }
    }
    
    /// Convert normalized bounding box to image coordinates
    func convertBoundingBox(_ box: CGRect, imageSize: CGSize) -> CGRect {
        let w = box.width * imageSize.width
        let h = box.height * imageSize.height
        let x = box.minX * imageSize.width
        let y = (1 - box.maxY) * imageSize.height // Vision uses bottom-left origin
        
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    /// Get human-readable description of detected objects
    func describeObjects(_ objects: [DetectedObject]) -> String {
        guard !objects.isEmpty else {
            return "No objects detected"
        }
        
        let descriptions = objects.map { object in
            var desc = "\(object.label)"
            if let distance = object.distance {
                desc += " at \(String(format: "%.1f", distance)) meters"
            } else {
                desc += " detected"
            }
            return desc
        }
        
        logger.info("Detected: \(descriptions.joined(separator: ", "))")
        return descriptions.joined(separator: ", ")
    }
}
