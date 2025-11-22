//
//  CoreMLModelManager.swift
//  NaviGPT
//
//  Created by NaviGPT Team on 11/17/25.
//  Manages CoreML model loading, caching, and lifecycle
//

import Foundation
import CoreML
import Vision
import os.log

/// Errors that can occur during model operations
enum ModelError: Error, LocalizedError {
    case modelNotFound(ModelType)
    case loadingFailed(ModelType, String)
    case processingFailed(String)
    case invalidInput(String)
    case modelNotLoaded(ModelType)
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let type):
            return "Model not found: \(type.rawValue)"
        case .loadingFailed(let type, let reason):
            return "Failed to load \(type.rawValue): \(reason)"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        case .invalidInput(let reason):
            return "Invalid input: \(reason)"
        case .modelNotLoaded(let type):
            return "Model not loaded: \(type.rawValue)"
        }
    }
}

/// Main manager class for CoreML models
@MainActor
class CoreMLModelManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CoreMLModelManager()
    
    // MARK: - Properties
    @Published var isLoading: Bool = false
    @Published var loadedModels: Set<ModelType> = []
    @Published var usingBuiltInModels: Set<ModelType> = [] // Track which models are using built-in Vision

    private var modelCache: [ModelType: MLModel] = [:]
    private var visionModels: [ModelType: VNCoreMLModel] = [:]
    private let logger = Logger(subsystem: "com.navigpt.models", category: "CoreMLModelManager")
    private let performanceOptimizer = PerformanceOptimizer.shared
    
    // Configuration - now using PerformanceOptimizer
    private var modelConfiguration: MLModelConfiguration {
        return performanceOptimizer.getOptimizedMLConfig()
    }
    
    // MARK: - Initialization
    private init() {
        logger.info("CoreMLModelManager initialized")
    }
    
    // MARK: - Model Loading
    
    /// Load a specific model type
    func loadModel(_ type: ModelType) async throws {
        guard !loadedModels.contains(type) else {
            logger.info("Model \(type.rawValue) already loaded")
            return
        }

        isLoading = true
        defer { isLoading = false }

        logger.info("Loading model: \(type.rawValue)")

        // First try .mlmodelc (compiled)
        if let modelURL = Bundle.main.url(forResource: type.fileName, withExtension: "mlmodelc") {
            do {
                let model = try MLModel(contentsOf: modelURL, configuration: modelConfiguration)
                modelCache[type] = model
                loadedModels.insert(type)

                if isVisionModel(type) {
                    let visionModel = try VNCoreMLModel(for: model)
                    visionModels[type] = visionModel
                }

                logger.info("✅ Successfully loaded compiled model: \(type.rawValue)")
                return
            } catch {
                logger.warning("Failed to load compiled model: \(error.localizedDescription)")
            }
        }
        
        // Try .mlpackage directory
        if let packageURL = Bundle.main.url(forResource: type.fileName, withExtension: "mlpackage") {
            do {
                // Try to compile the model first
                logger.info("Compiling model at: \(packageURL.path)")
                let compiledURL = try await MLModel.compileModel(at: packageURL)
                logger.info("Model compiled to: \(compiledURL.path)")
                
                let model = try MLModel(contentsOf: compiledURL, configuration: modelConfiguration)
                modelCache[type] = model
                loadedModels.insert(type)

                if isVisionModel(type) {
                    let visionModel = try VNCoreMLModel(for: model)
                    visionModels[type] = visionModel
                }

                logger.info("✅ Successfully loaded and compiled model: \(type.rawValue)")
                return
            } catch {
                logger.error("Failed to compile/load mlpackage: \(error.localizedDescription)")
            }
        }

        // Fallback to built-in Vision object detection
        logger.warning("⚠️ Using built-in Vision object detection as fallback")
        loadedModels.insert(type)
        usingBuiltInModels.insert(type)
        return
    }
    
    /// Load multiple models concurrently
    func loadModels(_ types: [ModelType]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for type in types {
                group.addTask {
                    try await self.loadModel(type)
                }
            }
            try await group.waitForAll()
        }
    }
    
    /// Preload commonly used models
    func preloadEssentialModels() async {
        logger.info("Preloading essential models")
        let essentialModels: [ModelType] = [.objectDetection, .depthEstimation]
        
        do {
            try await loadModels(essentialModels)
            logger.info("Essential models preloaded successfully")
        } catch {
            logger.error("Failed to preload essential models: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Model Access
    
    /// Get a loaded model
    func getModel(_ type: ModelType) throws -> MLModel {
        guard let model = modelCache[type] else {
            throw ModelError.modelNotLoaded(type)
        }
        return model
    }
    
    /// Get a Vision model wrapper
    func getVisionModel(_ type: ModelType) throws -> VNCoreMLModel {
        guard let visionModel = visionModels[type] else {
            throw ModelError.modelNotLoaded(type)
        }
        return visionModel
    }
    
    // MARK: - Model Management
    
    /// Unload a specific model to free memory
    func unloadModel(_ type: ModelType) {
        modelCache.removeValue(forKey: type)
        visionModels.removeValue(forKey: type)
        loadedModels.remove(type)
        logger.info("Unloaded model: \(type.rawValue)")
    }
    
    /// Unload all models
    func unloadAllModels() {
        modelCache.removeAll()
        visionModels.removeAll()
        loadedModels.removeAll()
        logger.info("All models unloaded")
    }
    
    /// Check if a model is loaded
    func isModelLoaded(_ type: ModelType) -> Bool {
        return loadedModels.contains(type)
    }
    
    // MARK: - Helper Methods
    
    private func isVisionModel(_ type: ModelType) -> Bool {
        switch type {
        case .objectDetection, .sceneUnderstanding, .textRecognition:
            return true
        case .depthEstimation:
            return true
        }
    }
    
    /// Get model metadata and information
    func getModelInfo(_ type: ModelType) throws -> String {
        let model = try getModel(type)
        let description = model.modelDescription
        
        var info = "Model: \(type.rawValue)\n"
        info += "Input: \(description.inputDescriptionsByName.keys.joined(separator: ", "))\n"
        info += "Output: \(description.outputDescriptionsByName.keys.joined(separator: ", "))\n"
        
        if let metadata = description.metadata[.author] as? String {
            info += "Author: \(metadata)\n"
        }
        
        return info
    }
}
