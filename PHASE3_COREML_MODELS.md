# Phase 3: CoreML Model Integration Guide

## Overview

This guide explains how to add CoreML models to NaviGPT for full Phase 2/3 functionality.

## Current Status

✅ **Infrastructure Ready**
- CoreMLModelManager implemented
- VisionModelProcessor ready for object detection
- DepthEstimationProcessor ready for depth estimation
- Error handling for missing models in place

⚠️ **Models Not Included**
- Actual .mlmodel files not included in repository
- Code gracefully handles missing models
- Tests can run without models (will skip model-dependent tests)

## Required Models

### 1. Object Detection (YOLOv8)

**Purpose**: Real-time detection of obstacles and objects

**Recommended Model**: YOLOv8n (Nano) for mobile performance
- **Source**: https://github.com/ultralytics/ultralytics
- **Format**: .mlmodel or .mlpackage
- **Expected Name**: `YOLOv8.mlmodel`
- **Size**: ~6MB (nano version)

**How to Obtain**:

```bash
# Install Ultralytics
pip install ultralytics

# Export to CoreML
python << EOF
from ultralytics import YOLO
model = YOLO('yolov8n.pt')
model.export(format='coreml', nms=True, imgsz=640)
EOF
```

**Alternative**: Use YOLOv5 CoreML model as placeholder
- Available at: https://github.com/ultralytics/yolov5/releases

### 2. Depth Estimation

**Purpose**: Estimate depth for non-LiDAR devices

**Option A: MiDAS** (Recommended)
- **Source**: https://github.com/isl-org/MiDAS
- **Format**: .mlmodel
- **Expected Name**: `DepthEstimation.mlmodel`

**Option B: Apple's Depth Estimation**
- Check Apple's ML Model Gallery
- Look for depth prediction models

**Conversion Steps** (for MiDAS):

```bash
# Install coremltools
pip install coremltools torch torchvision

# Convert MiDAS to CoreML
python << EOF
import torch
import coremltools as ct

# Load MiDAS model
model = torch.hub.load("intel-isl/MiDAS", "MiDAS_small")
model.eval()

# Create example input
example_input = torch.rand(1, 3, 256, 256)

# Trace the model
traced_model = torch.jit.trace(model, example_input)

# Convert to CoreML
mlmodel = ct.convert(
    traced_model,
    inputs=[ct.ImageType(name="input", shape=(1, 3, 256, 256))]
)

# Save
mlmodel.save("DepthEstimation.mlmodel")
EOF
```

### 3. Scene Classifier

**Purpose**: Classify indoor/outdoor environments

**Recommended**: MobileNetV2 trained on Places365
- **Format**: .mlmodel
- **Expected Name**: `SceneClassifier.mlmodel`
- **Source**: Apple's Core ML Models or convert from PyTorch

**Pre-converted Option**:
- Search Apple's developer resources
- Or use MobileNetV2 from their model gallery

### 4. Text Recognition (OCR)

**Status**: ✅ Built-in to Vision framework
- No additional model needed
- Uses `VNRecognizeTextRequest`

## Installation Instructions

### Step 1: Prepare Models

1. Download or convert the required models
2. Verify file format (.mlmodel or .mlpackage)
3. Test models work correctly

### Step 2: Add to Project Structure

```bash
# Create directory if it doesn't exist
mkdir -p NaviGPT_build_from_here/NaviGPT/Models/CoreML

# Copy models
cp YOLOv8.mlmodel NaviGPT_build_from_here/NaviGPT/Models/CoreML/
cp DepthEstimation.mlmodel NaviGPT_build_from_here/NaviGPT/Models/CoreML/
cp SceneClassifier.mlmodel NaviGPT_build_from_here/NaviGPT/Models/CoreML/
```

### Step 3: Add to Xcode Project

**Option A: Using Xcode GUI** (Recommended)

1. Open the project in Xcode:
   ```bash
   open NaviGPT_build_from_here/NaviGPT.xcodeproj
   ```

2. In Project Navigator, right-click on `NaviGPT` folder
3. Select "Add Files to 'NaviGPT'..."
4. Navigate to `NaviGPT/Models/CoreML/`
5. Select all .mlmodel files
6. **Important**: Check these options:
   - ✅ "Copy items if needed"
   - ✅ "Create groups"
   - ✅ Add to targets: "NaviGPT"
7. Click "Add"

**Option B: Using Script**

```bash
# Use the provided script
python3 add_coreml_models_to_xcode.py
```

### Step 4: Verify Integration

1. Build the project (⌘+B)
2. Check for model compilation
3. Look for .mlmodelc files in build output
4. Run tests to verify model loading

## Model Configuration

The [CoreMLModelManager](NaviGPT_build_from_here/NaviGPT/Services/CoreMLModelManager.swift) expects models at these paths:

```swift
enum ModelType: String, CaseIterable {
    case objectDetection = "YOLOv8"
    case depthEstimation = "DepthEstimation"
    case sceneUnderstanding = "SceneClassifier"
    case textRecognition = "built-in"  // Uses Vision framework
}
```

## Testing Without Models

The code includes comprehensive error handling:

```swift
do {
    try await modelManager.loadModel(.objectDetection)
} catch ModelError.modelNotFound(let type) {
    print("Model not found: \(type), skipping...")
    // Tests will pass but skip model-dependent operations
}
```

**This means**:
- ✅ Project builds successfully without models
- ✅ Tests run (but skip model-dependent tests)
- ✅ App runs (with reduced functionality)
- ⚠️ Full Phase 2 features require actual models

## Performance Considerations

### Model Sizes (Approximate)

| Model | Size | Inference Time (iPhone 12+) |
|-------|------|----------------------------|
| YOLOv8n | ~6MB | ~30-50ms |
| MiDAS Small | ~20MB | ~100-150ms |
| MobileNetV2 | ~15MB | ~20-30ms |

### Optimization Tips

1. **Use Neural Engine**
   - Models automatically use Neural Engine when available
   - Configured in CoreMLModelManager

2. **Quantization**
   - Convert models to FP16 for smaller size
   - 2x smaller with minimal accuracy loss

3. **Input Size**
   - Use 320x320 or 640x640 for YOLOv8
   - Smaller = faster, larger = more accurate

## Troubleshooting

### Model Not Found Error

```
Error: ModelError.modelNotFound(.objectDetection)
```

**Solution**:
1. Verify model file exists in project
2. Check it's added to NaviGPT target
3. Verify file name matches ModelType enum
4. Clean build folder (Shift+⌘+K) and rebuild

### Model Compilation Failed

```
Error: Failed to compile model
```

**Solution**:
1. Verify .mlmodel format is correct
2. Check iOS deployment target compatibility
3. Try re-exporting model with latest coremltools
4. Check Xcode version supports model version

### Performance Issues

**Symptoms**: Slow inference, app freezing

**Solutions**:
1. Ensure async model loading
2. Process on background thread
3. Use smaller model variant
4. Reduce input image size
5. Implement frame skipping

## Next Steps After Adding Models

1. **Run Full Test Suite**
   ```bash
   cd NaviGPT_build_from_here
   xcodebuild test -scheme Intern1 -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
   ```

2. **Verify Model Performance**
   - Check Phase2Tests results
   - Review inference times
   - Test on actual device

3. **Integration Testing**
   - Test with live camera feed
   - Verify LiDAR + ML fusion
   - Test navigation guidance

## Resources

- [Apple CoreML Documentation](https://developer.apple.com/documentation/coreml)
- [Core ML Tools](https://coremltools.apple.com/)
- [Ultralytics YOLOv8](https://docs.ultralytics.com/)
- [MiDAS Depth Estimation](https://github.com/isl-org/MiDAS)
- [Apple ML Models](https://developer.apple.com/machine-learning/models/)

## Support

For questions or issues:
1. Check existing Phase 2 tests for examples
2. Review CoreMLModelManager implementation
3. Consult Apple's CoreML documentation
4. Check model provider's documentation

---

**Last Updated**: November 2024
**Related Documents**: [PHASE2_README.md](PHASE2_README.md)
