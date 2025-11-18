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

/// Enum representing different types of ML models used in NaviGPT
enum ModelType: String {
    case objectDetection = "YOLOv8"
    case depthEstimation = "DepthEstimator"
    case sceneUnderstanding = "SceneClassifier"
    case textRecognition = "OCRModel"
    
    var fileName: String {
        return self.rawValue
    }
}

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
    
    private var modelCache: [ModelType: MLModel] = [:]
    private var visionModels: [ModelType: VNCoreMLModel] = [:]
    private let logger = Logger(subsystem: "com.navigpt.models", category: "CoreMLModelManager")
    
    // Configuration
    private let modelConfiguration: MLModelConfiguration = {
        let config = MLModelConfiguration()
        config.computeUnits = .all // Use Neural Engine, GPU, and CPU
        return config
    }()
    
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
        
        do {
            // Try to load from bundle
            guard let modelURL = Bundle.main.url(forResource: type.fileName, withExtension: "mlmodelc") else {
                throw ModelError.modelNotFound(type)
            }
            
            let model = try MLModel(contentsOf: modelURL, configuration: modelConfiguration)
            modelCache[type] = model
            loadedModels.insert(type)
            
            // Create Vision model wrapper if applicable
            if isVisionModel(type) {
                let visionModel = try VNCoreMLModel(for: model)
                visionModels[type] = visionModel
            }
            
            logger.info("Successfully loaded model: \(type.rawValue)")
        } catch {
            logger.error("Failed to load model \(type.rawValue): \(error.localizedDescription)")
            throw ModelError.loadingFailed(type, error.localizedDescription)
        }
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
