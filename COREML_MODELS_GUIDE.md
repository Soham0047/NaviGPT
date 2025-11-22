# CoreML Models Integration Guide for NaviGPT

## 📋 Overview

NaviGPT uses CoreML models for real-time object detection and scene understanding. This guide explains how to add and configure ML models for the app.

---

## 🎯 Quick Start Options

### Option 1: Use Apple's Built-in Vision Models (Recommended for Testing)

The app now includes fallback support for Apple's built-in Vision framework models. These work out-of-the-box without downloading anything:

- **Object Detection**: VNRecognizeAnimalsRequest (detects dogs, cats)
- **Scene Classification**: Built-in scene classifier
- **Text Recognition**: Built-in OCR (already implemented)

**Pros:**
- ✅ No setup required
- ✅ Works immediately
- ✅ Lightweight

**Cons:**
- ⚠️ Limited object classes (mainly animals)
- ⚠️ Less accurate than custom models

**Usage:** The app will automatically use these if custom models aren't found.

---

### Option 2: Download Pre-Converted CoreML Models (Recommended for Production)

For full object detection capabilities (people, vehicles, signs, etc.), add custom CoreML models.

#### **Step 1: Download Models**

**YOLOv8 (Object Detection) - RECOMMENDED**

Download from Apple's CoreML model zoo or GitHub:

1. Visit: https://github.com/ultralytics/ultralytics
2. Download YOLOv8n CoreML export (smallest, fastest)
3. Or use coremltools to convert (see Option 3)

**Alternative Sources:**
- **Apple CoreML Models**: https://developer.apple.com/machine-learning/models/
- **Core ML Community**: https://coreml.store/
- **Hugging Face**: https://huggingface.co/models?library=coreml

**Recommended Models:**
```
YOLOv8n.mlmodel      - Object detection (~6MB, 30+ FPS)
MobileNetV2-SSD.mlmodel - Alternative detector (~15MB, 25+ FPS)
```

#### **Step 2: Add Models to Xcode**

1. **Drag and drop** the `.mlmodel` file into your Xcode project:
   - Navigate to `NaviGPT_build_from_here/NaviGPT` folder in Xcode
   - Create a new group called "MLModels" (optional, for organization)
   - Drag the `.mlmodel` file from Finder into the project

2. **Ensure correct settings:**
   - ✅ "Copy items if needed" should be checked
   - ✅ "Add to targets: NaviGPT" should be checked
   - ✅ The file should appear in the project navigator

3. **Xcode will automatically compile** the `.mlmodel` to `.mlmodelc` during build

#### **Step 3: Rename Models (If Needed)**

The app expects these filenames:
- `YOLOv8.mlmodel` - For object detection
- `DepthEstimator.mlmodel` - For depth estimation (optional, we use LiDAR)
- `SceneClassifier.mlmodel` - For scene classification (optional)

**To rename:**
- Right-click the model in Xcode → "Rename"
- Or rename the file before adding to Xcode

#### **Step 4: Verify Model is Loaded**

1. Build and run the app
2. Check the debug console for: `"Successfully loaded model: YOLOv8"`
3. If you see `"Model not found: YOLOv8"`, the file wasn't added correctly

---

### Option 3: Convert Your Own Models to CoreML

If you have a PyTorch or TensorFlow model, convert it to CoreML:

#### **Prerequisites:**
```bash
pip install coremltools ultralytics
```

#### **Convert YOLOv8 (Python):**
```python
from ultralytics import YOLO

# Load YOLOv8 model
model = YOLO('yolov8n.pt')  # Download from ultralytics

# Export to CoreML
model.export(format='coreml', imgsz=640)
```

This creates `yolov8n.mlpackage` → Rename to `YOLOv8.mlmodel`

#### **Convert Other Models:**
```python
import coremltools as ct

# Load PyTorch model
pytorch_model = ...

# Trace the model
traced_model = torch.jit.trace(pytorch_model, example_input)

# Convert to CoreML
mlmodel = ct.convert(
    traced_model,
    inputs=[ct.ImageType(name="image", shape=(1, 3, 640, 640))],
    outputs=[ct.TensorType(name="output")]
)

# Save
mlmodel.save("YOLOv8.mlmodel")
```

---

## 🔧 Configuration

### Model Files Expected by NaviGPT

| Model Type | Filename | Purpose | Required? |
|------------|----------|---------|-----------|
| Object Detection | `YOLOv8.mlmodel` | Detect objects (people, cars, etc.) | ✅ Yes |
| Depth Estimation | `DepthEstimator.mlmodel` | Estimate depth (optional, we use LiDAR) | ⚠️ Optional |
| Scene Classification | `SceneClassifier.mlmodel` | Classify environment | ⚠️ Optional |
| Text Recognition | Built-in | OCR for signs | ✅ Built-in |

### Performance Targets

- **Target FPS**: 30+ frames per second
- **Latency**: < 33ms per frame
- **Model Size**: < 50MB for mobile deployment
- **Compute**: Uses Neural Engine + GPU when available

### Model Requirements

CoreML models should:
- **Input**: RGB image (640x640 recommended for YOLO)
- **Output**: Bounding boxes + class labels + confidence scores
- **Format**: `.mlmodel` or `.mlpackage`

---

## 📱 Testing Models

### 1. Build and Run

```bash
cd NaviGPT_build_from_here
xcodebuild -project NaviGPT.xcodeproj -scheme NaviGPT build
```

### 2. Check Console Output

Look for:
```
✅ "Successfully loaded model: YOLOv8"
✅ "Detection complete: 5 objects found in 0.025s"
```

### 3. Monitor Performance

The app displays:
- **FPS** in the performance HUD (top-left)
- **Processing latency** in milliseconds
- **Detected objects** with bounding boxes

---

## 🐛 Troubleshooting

### "Model not found: YOLOv8"

**Solutions:**
1. Check model is in Xcode project navigator
2. Verify "Target Membership" includes NaviGPT
3. Clean build folder: Product → Clean Build Folder
4. Rebuild project

### "Failed to load YOLOv8: The model does not have a valid description"

**Solutions:**
1. Model might be corrupted - re-download
2. Ensure model is CoreML format (not PyTorch .pt)
3. Use `coremltools` to validate: `ct.models.MLModel("YOLOv8.mlmodel")`

### Low FPS (< 15 FPS)

**Solutions:**
1. Use smaller model (YOLOv8n instead of YOLOv8x)
2. Reduce input resolution in RealTimeCameraProcessor config
3. Check Model Configuration uses Neural Engine: `computeUnits = .all`

### Objects Not Detected

**Solutions:**
1. Check confidence threshold (default 0.5) in VisionModelProcessor
2. Ensure model supports the object classes you want to detect
3. Verify camera permissions are granted
4. Test with well-lit environment

---

## 📊 Recommended Models for NaviGPT

### For Accessibility (Navigation Aid)

**Object Detection:**
- **YOLOv8n-COCO** - Detects 80 classes including:
  - People, wheelchairs, canes
  - Vehicles (cars, buses, bikes)
  - Traffic signs, crosswalks
  - Doors, stairs, obstacles
  - ~6MB, 35+ FPS on iPhone 12+

### For Indoor Navigation

**Scene Classification:**
- **MobileNetV2-Places365** - Classifies 365 indoor/outdoor scenes
  - Hallway, staircase, elevator, bathroom, etc.
  - ~15MB, 50+ FPS

---

## 🚀 Next Steps

1. ✅ **Add YOLOv8.mlmodel** for object detection
2. ⚠️ **Test on device** with LiDAR (iPhone 12 Pro or newer)
3. ⚠️ **Tune confidence threshold** based on real-world testing
4. ⚠️ **Add custom object classes** if needed (e.g., curb detection)
5. ⚠️ **Optimize for battery** using adaptive FPS

---

## 📚 Additional Resources

- **Apple CoreML Documentation**: https://developer.apple.com/documentation/coreml
- **YOLOv8 by Ultralytics**: https://github.com/ultralytics/ultralytics
- **CoreML Tools**: https://github.com/apple/coremltools
- **Model Conversion Guide**: https://coremltools.readme.io/docs

---

**Last Updated:** November 21, 2024
**NaviGPT Phase 3** - Real-Time Processing & ML Integration
