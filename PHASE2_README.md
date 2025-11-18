# Phase 2: CoreML Model Integration Layer

## Overview
Phase 2 implements the infrastructure for loading and managing CoreML models for vision, depth estimation, and scene understanding. This layer provides the foundation for real-time AI-powered navigation assistance.

## Architecture

### Core Components

#### 1. CoreMLModelManager (`Services/CoreMLModelManager.swift`)
**Purpose**: Centralized manager for all CoreML model operations

**Key Features**:
- Singleton pattern for app-wide model access
- Asynchronous model loading with error handling
- Model caching to optimize memory usage
- Support for multiple model types:
  - Object Detection (YOLOv8)
  - Depth Estimation
  - Scene Understanding
  - Text Recognition (OCR)
- Automatic Vision framework integration
- Model lifecycle management (load/unload)

**Usage Example**:
```swift
let manager = CoreMLModelManager.shared
try await manager.loadModel(.objectDetection)
let model = try manager.getModel(.objectDetection)
```

#### 2. VisionModelProcessor (`Services/VisionModelProcessor.swift`)
**Purpose**: Processes images using Vision and CoreML for object detection

**Key Features**:
- Real-time object detection from images or pixel buffers
- Scene classification
- OCR text recognition
- Confidence-based filtering
- Bounding box coordinate conversion
- Human-readable object descriptions

**Data Structures**:
- `DetectedObject`: Represents a detected object with label, confidence, bounding box, and optional distance
- `VisionProcessingResult`: Contains detected objects, processing time, and timestamp

**Usage Example**:
```swift
let processor = VisionModelProcessor()
let result = try await processor.detectObjects(in: image)
print(processor.describeObjects(result.objects))
```

#### 3. DepthEstimationProcessor (`Services/DepthEstimationProcessor.swift`)
**Purpose**: Processes depth information from camera and CoreML models

**Key Features**:
- Hybrid depth estimation (LiDAR + ML models)
- ARKit integration for LiDAR devices
- CoreML-based depth estimation for non-LiDAR devices
- Obstacle detection based on depth thresholds
- Depth map analysis and sampling
- Spatial audio guidance generation

**Data Structures**:
- `DepthPoint`: Represents a point in 3D space with depth and confidence
- `DepthEstimationResult`: Contains depth map, statistics, and detected obstacles
- `DepthProcessingConfig`: Configuration for sampling rate, depth range, etc.

**Usage Example**:
```swift
let processor = DepthEstimationProcessor()
let result = try await processor.estimateDepth(from: image)
let obstacles = processor.detectObstacles(from: result)
print(processor.describeDepthScenario(result))
```

#### 4. ModelTypes (`Models/ModelTypes.swift`)
**Purpose**: Common data types and protocols for ML models

**Key Structures**:
- `SpatialPoint`: 3D point with screen and world coordinates
- `DetectionConfidence`: Enum for confidence levels (low, medium, high, veryHigh)
- `Obstacle`: Combines vision and depth data for navigation
- `SceneContext`: Environment understanding (indoor/outdoor, lighting, weather)
- `EnvironmentSnapshot`: Aggregated understanding of the environment
- `ModelPerformanceMetrics`: Tracks inference performance and FPS
- `ModelStatistics`: Aggregated statistics for model performance

**Key Features**:
- Obstacle urgency levels (0-3) based on distance
- Bearing calculation for spatial audio
- Navigation guidance generation
- Performance monitoring and optimization

## Implementation Status

### ✅ Completed
1. **CoreML Model Manager**
   - Model loading infrastructure
   - Caching and lifecycle management
   - Vision framework integration
   - Error handling and logging

2. **Vision Processing**
   - Object detection pipeline
   - Scene classification
   - Text recognition (OCR)
   - Bounding box utilities

3. **Depth Estimation**
   - Hybrid LiDAR + ML approach
   - ARKit integration
   - Obstacle detection
   - Depth map analysis

4. **Type System**
   - Comprehensive data structures
   - Performance metrics
   - Navigation guidance

5. **Comprehensive Test Suite**
   - Unit tests for all components
   - Performance benchmarks
   - Integration tests

### ⚠️ Pending Xcode Integration
The Phase 2 files have been created but need to be added to the Xcode project build phases manually:

**Files to Add to NaviGPT Target**:
- `Services/CoreMLModelManager.swift`
- `Services/VisionModelProcessor.swift`
- `Services/DepthEstimationProcessor.swift`
- `Models/ModelTypes.swift`

**Test Files** (Add to NaviGPTTests Target):
- `Intern1Tests/Phase2Tests.swift`

**Manual Steps Required**:
1. Open `NaviGPT.xcodeproj` in Xcode
2. Drag the new files from Finder into the Project Navigator
3. Ensure "Copy items if needed" is UNchecked (files are already in place)
4. Select NaviGPT target for main files, NaviGPTTests for test files
5. Build and verify all tests pass

### 🔜 Next Steps (Phase 3)
1. Implement LiDAR sensor processing module
2. Enhanced ARKit integration
3. Real-time obstacle detection
4. Distance measurement and tracking

## Dependencies

### System Frameworks
- CoreML: Model loading and inference
- Vision: Image processing and object detection
- ARKit: LiDAR and AR functionality
- AVFoundation: Image capture and processing
- os.log: Logging and debugging

### Model Requirements
Phase 2 is designed to work with:
- **YOLOv8**: Object detection model (not included, will be added in Phase 3)
- **Depth Estimation Model**: Custom or MiDAS-based (to be added)
- **Scene Classifier**: For environment understanding (to be added)
- **OCR Model**: Text recognition (using Vision's built-in VNRecognizeTextRequest)

## Performance Considerations

### Optimization Features
1. **Lazy Loading**: Models loaded only when needed
2. **Caching**: Loaded models cached for reuse
3. **Async Operations**: All heavy operations are async/await
4. **Configurable Sampling**: Depth map sampling rate configurable for performance
5. **Neural Engine Support**: Models configured to use Neural Engine when available
6. **Memory Management**: Explicit unload methods for memory pressure situations

### Performance Metrics
The system tracks:
- Inference time per model
- FPS for real-time processing
- Preprocessing and postprocessing time
- Success/failure rates
- Average, min, max inference times

## Error Handling

### Error Types
```swift
enum ModelError: Error {
    case modelNotFound(ModelType)
    case loadingFailed(ModelType, String)
    case processingFailed(String)
    case invalidInput(String)
    case modelNotLoaded(ModelType)
}
```

### Best Practices
1. Always check if model is loaded before processing
2. Use try/await for async model operations
3. Handle ModelError cases appropriately
4. Check processing results for nil values
5. Monitor performance metrics for degradation

## Testing

### Unit Tests (Phase2Tests.swift)
- **Model Manager**: Initialization, singleton, loading, unloading
- **Vision Processor**: Object detection, scene classification, OCR
- **Depth Processor**: Depth estimation, obstacle detection, guidance
- **Type System**: Confidence levels, obstacles, metrics, statistics
- **Performance**: Creation time benchmarks
- **Integration**: Component interaction tests

### Test Coverage
- 27 test methods
- Covers all major functionality
- Performance benchmarks included
- Integration tests for component interaction

## Integration Guide

### Using Object Detection
```swift
let visionProcessor = VisionModelProcessor()

// From UIImage
let result = try await visionProcessor.detectObjects(in: image)

// From CVPixelBuffer (real-time)
let result = try await visionProcessor.detectObjects(in: pixelBuffer)

// Get human-readable description
let description = visionProcessor.describeObjects(result.objects)
speechManager.speak(description)
```

### Using Depth Estimation
```swift
let depthProcessor = DepthEstimationProcessor()

// From image (ML-based)
let result = try await depthProcessor.estimateDepth(from: image)

// From ARFrame (LiDAR-based)
let result = try await depthProcessor.processARDepth(from: arFrame)

// Detect obstacles
let obstacles = depthProcessor.detectObstacles(from: result)

// Generate guidance
let guidance = depthProcessor.describeDepthScenario(result)
speechManager.speak(guidance)
```

### Combining Vision + Depth
```swift
// Detect objects
let visionResult = try await visionProcessor.detectObjects(in: image)

// Get depth information
let depthResult = try await depthProcessor.estimateDepth(from: image)

// Create enhanced obstacle list with depth
var obstacles: [Obstacle] = []
for detectedObject in visionResult.objects {
    if let depth = depthProcessor.getDepthAt(
        normalizedPoint: detectedObject.boundingBox.center,
        from: depthResult.depthMap!
    ) {
        let obstacle = Obstacle(
            label: detectedObject.label,
            position: SpatialPoint(...),
            boundingBox: detectedObject.boundingBox,
            confidence: DetectionConfidence(rawValue: detectedObject.confidence),
            distance: depth,
            bearing: calculateBearing(...)
        )
        obstacles.append(obstacle)
    }
}

// Create environment snapshot
let snapshot = EnvironmentSnapshot(
    timestamp: Date(),
    obstacles: obstacles,
    sceneContext: nil,
    depthEstimate: depthResult,
    recognizedText: []
)

// Generate navigation guidance
let guidance = snapshot.generateNavigationGuidance()
speechManager.speak(guidance)
```

## Known Issues

1. **Xcode Project Integration**: New files not automatically added to Xcode project
   - **Impact**: Files won't compile until manually added to Xcode
   - **Workaround**: Manually add files to Xcode project (see "Pending Xcode Integration" above)
   - **Status**: Awaiting manual Xcode project update

2. **Model Files Not Included**: CoreML model files not yet added to project
   - **Impact**: Model loading will fail with `.modelNotFound` error
   - **Workaround**: Test infrastructure works, actual models to be added in Phase 3
   - **Status**: Expected, models will be added in next phase

## Documentation

### API Documentation
All public APIs include comprehensive documentation comments:
- Purpose and usage
- Parameter descriptions
- Return value descriptions
- Error cases
- Usage examples

### Logging
Comprehensive logging using `os.log`:
- Subsystem: `com.navigpt.models`, `com.navigpt.vision`, `com.navigpt.depth`
- Categories: Component-specific
- Levels: Info, Error

## Future Enhancements

### Phase 3 Additions
1. Add actual CoreML models
2. Real-time camera integration
3. LiDAR data processing
4. Advanced obstacle tracking
5. Predictive path analysis

### Potential Optimizations
1. Model quantization for faster inference
2. Multi-threading for parallel processing
3. GPU acceleration for depth estimation
4. Adaptive quality based on device capabilities
5. Background model preloading

## Contributing

When adding new functionality to Phase 2:
1. Follow existing patterns for async/await
2. Add comprehensive error handling
3. Include unit tests for new features
4. Update this README with new capabilities
5. Document public APIs with doc comments
6. Add logging for debugging
7. Consider performance implications

## References

- [Apple CoreML Documentation](https://developer.apple.com/documentation/coreml)
- [Apple Vision Framework](https://developer.apple.com/documentation/vision)
- [Apple ARKit](https://developer.apple.com/documentation/arkit)
- [Postman Collection Format](https://schema.postman.com/)
