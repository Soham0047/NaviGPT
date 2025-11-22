# YOLOv8 Integration Guide - Step by Step

**Estimated Time**: 30 minutes
**Difficulty**: Easy
**Impact**: High (Animals → 80+ object classes)

---

## 📋 Prerequisites

Before starting, ensure you have:
- ✅ Python 3.8+ installed
- ✅ pip package manager
- ✅ Xcode 14+ installed
- ✅ NaviGPT project on your Mac
- ✅ ~500MB free disk space

---

## 🚀 Step 1: Install Required Python Packages

Open Terminal and run:

```bash
# Install ultralytics package (includes YOLOv8)
pip3 install ultralytics

# Verify installation
python3 -c "from ultralytics import YOLO; print('✅ Ultralytics installed successfully')"
```

**Expected Output**:
```
✅ Ultralytics installed successfully
```

**Troubleshooting**:
- If `pip3` not found: `brew install python3`
- If permission denied: `pip3 install --user ultralytics`

---

## 📥 Step 2: Download and Convert YOLOv8n Model

Create a temporary directory and download the model:

```bash
# Navigate to your project
cd ~/Documents/Documents-MacBookAir/GitHub/NaviGPT

# Create models directory
mkdir -p CoreML_Models

# Navigate to models directory
cd CoreML_Models

# Run Python script to download and convert
python3 << 'EOF'
from ultralytics import YOLO
import os

print("📥 Downloading YOLOv8n model...")
model = YOLO('yolov8n.pt')  # Downloads ~6MB model

print("🔄 Converting to CoreML format...")
model.export(
    format='coreml',
    imgsz=640,  # Input size 640x640
    nms=True,   # Include Non-Maximum Suppression
    half=False  # Use FP32 for compatibility
)

print("✅ Conversion complete!")
print(f"📁 Model saved to: {os.getcwd()}")
print("Look for: yolov8n.mlpackage or yolov8n.mlmodel")
EOF
```

**Expected Output**:
```
📥 Downloading YOLOv8n model...
Downloading https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n.pt...
100%|████████████████████| 6.23M/6.23M [00:02<00:00, 2.51MB/s]
🔄 Converting to CoreML format...
CoreML: export success, saved as yolov8n.mlpackage
✅ Conversion complete!
```

**What This Does**:
- Downloads pre-trained YOLOv8n (nano) model
- Converts from PyTorch (.pt) to CoreML (.mlpackage)
- Optimizes for iOS Neural Engine
- Includes NMS (removes duplicate detections)

---

## 📦 Step 3: Verify Model Files

Check that the model was created:

```bash
# List files in CoreML_Models directory
ls -lh CoreML_Models/

# Expected output:
# yolov8n.pt          (~6MB - PyTorch model, can delete)
# yolov8n.mlpackage   (~6-7MB - CoreML model, keep this!)
```

**File Structure**:
```
CoreML_Models/
├── yolov8n.pt           # Original PyTorch model (optional, can delete)
└── yolov8n.mlpackage/   # CoreML model (REQUIRED)
    ├── Data/
    ├── Manifest.json
    └── Metadata/
```

---

## 🎯 Step 4: Rename Model to Match NaviGPT Expectations

The app expects the model to be named `YOLOv8.mlmodel`. Let's rename:

```bash
cd ~/Documents/Documents-MacBookAir/GitHub/NaviGPT/CoreML_Models

# If you have .mlpackage (newer format)
mv yolov8n.mlpackage YOLOv8.mlpackage

# Verify
ls -lh YOLOv8.mlpackage
```

**Note**: CoreML supports both `.mlmodel` and `.mlpackage` formats. The `.mlpackage` is newer and preferred.

---

## 🔧 Step 5: Add Model to Xcode Project

### Option A: Using Xcode GUI (Recommended)

1. **Open Xcode Project**:
   ```bash
   open NaviGPT_build_from_here/NaviGPT.xcodeproj
   ```

2. **Navigate in Xcode**:
   - In the Project Navigator (left sidebar), find the `NaviGPT` folder
   - Right-click on `NaviGPT` → **New Group** → Name it `MLModels`

3. **Add Model File**:
   - Right-click on `MLModels` folder → **Add Files to "NaviGPT"...**
   - Navigate to `~/Documents/Documents-MacBookAir/GitHub/NaviGPT/CoreML_Models/`
   - Select `YOLOv8.mlpackage`
   - **IMPORTANT**: Check these options:
     - ✅ **Copy items if needed**
     - ✅ **Create groups** (not folder references)
     - ✅ **Add to targets**: NaviGPT (main app target)
   - Click **Add**

4. **Verify Model is Added**:
   - Click on `YOLOv8.mlpackage` in Xcode
   - You should see the model details panel
   - Look for:
     - Model class: `YOLOv8`
     - Input: `image` (640x640 RGB)
     - Outputs: Various detection tensors

### Option B: Using Command Line (Alternative)

If you prefer command line, I can create a script to add the model programmatically.

---

## ✅ Step 6: Build and Verify

1. **Clean Build Folder**:
   - In Xcode: **Product** → **Clean Build Folder** (Shift+Cmd+K)

2. **Build Project**:
   - **Product** → **Build** (Cmd+B)

3. **Check Console for Success**:
   Look for these messages in the Xcode console:
   ```
   CompileMLModel NaviGPT/MLModels/YOLOv8.mlpackage
   ✅ CoreML model compiled successfully
   ```

4. **Verify Model Loads at Runtime**:
   - Run the app in Simulator or on device
   - Check logs for:
   ```
   ✅ Successfully loaded custom model: YOLOv8
   ```

   If you see this, SUCCESS! 🎉

---

## 🧪 Step 7: Test Object Detection

Create a simple test to verify detection works:

### Test Script:

```bash
# Create test script
cat > ~/Documents/Documents-MacBookAir/GitHub/NaviGPT/test_yolov8.swift << 'EOF'
import Foundation
import CoreML
import Vision

// Quick test that model loads and works
Task {
    do {
        let modelURL = Bundle.main.url(forResource: "YOLOv8", withExtension: "mlmodelc")!
        let model = try MLModel(contentsOf: modelURL)
        print("✅ Model loaded successfully!")

        let visionModel = try VNCoreMLModel(for: model)
        print("✅ Vision model wrapper created!")

        print("\nModel Metadata:")
        print("- Input: \(model.modelDescription.inputDescriptionsByName.keys)")
        print("- Output: \(model.modelDescription.outputDescriptionsByName.keys)")

    } catch {
        print("❌ Error: \(error)")
    }
}
EOF
```

### Run in Xcode:
1. Add a temporary test in your app's `onAppear`:
   ```swift
   .onAppear {
       Task {
           do {
               let manager = CoreMLModelManager.shared
               try await manager.loadModel(.objectDetection)

               if manager.usingBuiltInModels.contains(.objectDetection) {
                   print("⚠️ Using built-in Vision (model not found)")
               } else {
                   print("✅ Custom YOLOv8 model loaded!")
               }
           } catch {
               print("❌ Error loading model: \(error)")
           }
       }
   }
   ```

2. Run the app and check console logs

---

## 📊 Expected Detection Classes

With YOLOv8n, you can now detect **80 object classes**:

### Categories:
**People & Animals** (16 classes):
- person, cat, dog, horse, sheep, cow, elephant, bear, zebra, giraffe, bird, etc.

**Vehicles** (8 classes):
- bicycle, car, motorcycle, airplane, bus, train, truck, boat

**Street Objects** (12 classes):
- traffic light, fire hydrant, stop sign, parking meter, bench, etc.

**Indoor Objects** (24 classes):
- chair, couch, bed, dining table, toilet, tv, laptop, mouse, keyboard, etc.

**Outdoor Objects** (20 classes):
- backpack, umbrella, handbag, tie, suitcase, frisbee, skis, etc.

**Complete List**: See [COCO dataset classes](https://github.com/ultralytics/ultralytics/blob/main/ultralytics/cfg/datasets/coco.yaml)

---

## 🎯 Performance Expectations

### On iPhone 12 Pro+ (with Neural Engine):
- **FPS**: 25-30 frames per second
- **Latency**: 30-50ms per frame
- **Accuracy**:
  - People: ~90% (excellent)
  - Vehicles: ~85% (very good)
  - Small objects: ~70% (good)
- **Battery**: 3-4 hours continuous use

### On Older Devices (GPU fallback):
- **FPS**: 15-20 frames per second
- **Latency**: 50-80ms per frame
- **Accuracy**: Same as above
- **Battery**: 2-3 hours

---

## 🐛 Troubleshooting

### Issue 1: "Model not found: YOLOv8"

**Symptoms**:
```
⚠️ Custom model not found for YOLOv8, using built-in Vision capabilities
```

**Solutions**:
1. Check model file exists in Xcode project navigator
2. Verify Target Membership:
   - Click on `YOLOv8.mlpackage` in Xcode
   - Right panel → **Target Membership** → Check `NaviGPT`
3. Clean and rebuild:
   ```bash
   # In Xcode
   Product → Clean Build Folder (Shift+Cmd+K)
   Product → Build (Cmd+B)
   ```

### Issue 2: "Failed to load model: The model does not have a valid description"

**Symptoms**:
```
❌ Failed to load custom model, will try built-in: The model does not have a valid description
```

**Solutions**:
1. Re-export model with correct settings:
   ```python
   model.export(format='coreml', imgsz=640, half=False)
   ```
2. Ensure Xcode compiles the model (look for `.mlmodelc` in DerivedData)

### Issue 3: Low FPS or High Latency

**Symptoms**:
- FPS < 15
- Latency > 100ms

**Solutions**:
1. Reduce input size (640 → 320):
   ```python
   model.export(format='coreml', imgsz=320)
   ```
2. Use quantized model (FP16):
   ```python
   model.export(format='coreml', imgsz=640, half=True)
   ```
3. Lower frame processing rate in RealTimeCameraProcessor config

### Issue 4: Memory Issues

**Symptoms**:
- App crashes with memory warnings
- Memory usage > 500MB

**Solutions**:
1. Ensure model is loaded only once (singleton pattern already implemented ✅)
2. Use YOLOv8n (nano) instead of larger variants
3. Implement frame skipping (process every 2nd or 3rd frame)

---

## 📈 Validation Checklist

After integration, verify these work:

### Basic Functionality:
- [ ] App builds without errors
- [ ] Model loads on app launch (check console)
- [ ] Camera view displays
- [ ] Detection overlay shows bounding boxes
- [ ] Performance HUD shows FPS > 20

### Detection Quality:
- [ ] Detects people accurately (>85%)
- [ ] Detects vehicles (cars, bicycles)
- [ ] Detects furniture indoors
- [ ] Bounding boxes align with objects
- [ ] Confidence scores reasonable (>0.5 for clear objects)

### Performance:
- [ ] FPS stable (doesn't drop over time)
- [ ] Latency < 50ms average
- [ ] Memory usage < 300MB
- [ ] No thermal throttling after 5 minutes
- [ ] Battery drain acceptable (<30%/hour)

### Audio Feedback:
- [ ] Announces detected obstacles
- [ ] Direction descriptions accurate
- [ ] Distance estimates reasonable
- [ ] Audio not overwhelming (debouncing works)

---

## 🎓 Next Steps After Integration

Once YOLOv8 is working:

1. **Fine-Tune Confidence Threshold**:
   - Current: 0.5 (50%)
   - Adjust in [VisionModelProcessor.swift:43](NaviGPT_build_from_here/NaviGPT/Services/VisionModelProcessor.swift#L43)
   - Test with real-world scenarios
   - Balance: Too low = false positives, Too high = missed detections

2. **Optimize for Accessibility**:
   - Prioritize person/vehicle detection
   - Add custom post-processing for curbs, crosswalks
   - Filter irrelevant objects (e.g., ignore "tv" outdoors)

3. **Collect Performance Metrics**:
   - Average FPS over 5-minute sessions
   - Detection accuracy per class
   - Battery drain rate
   - User feedback

4. **Prepare for Device Testing** (Option B):
   - Document model performance on Simulator
   - Create test cases for real-world scenarios
   - Identify edge cases to test

---

## 📊 Success Metrics

**Integration is successful when**:
- ✅ App logs: "Successfully loaded custom model: YOLOv8"
- ✅ Detection overlay shows multiple object types (not just animals)
- ✅ FPS stable at 20-30
- ✅ Memory < 300MB
- ✅ No crashes after 5 minutes of use

---

## 🆘 Need Help?

If you encounter issues:

1. **Check Console Logs**:
   - Xcode → View → Debug Area → Show Debug Area
   - Filter for "YOLOv8" or "CoreML"

2. **Verify Model Compilation**:
   ```bash
   # Find compiled model in DerivedData
   find ~/Library/Developer/Xcode/DerivedData -name "YOLOv8.mlmodelc"
   ```

3. **Test Model Directly**:
   ```swift
   // In Xcode playground or test
   let url = Bundle.main.url(forResource: "YOLOv8", withExtension: "mlmodelc")
   print("Model URL: \(url)")
   ```

4. **Check Build Phases**:
   - Xcode → Project Navigator → Select NaviGPT project
   - Target: NaviGPT → Build Phases
   - Look for "Compile Sources" → Should include YOLOv8

---

## 🎉 Completion

When you see this in your console logs:

```
✅ Successfully loaded custom model: YOLOv8
ℹ️ Model loaded with Neural Engine support
✅ Detection complete: 5 objects found in 0.035s
```

**Congratulations!** YOLOv8 is integrated and working! 🚀

You're ready to move on to **Option B: Device Testing**.

---

**Estimated Total Time**: 30-45 minutes (including downloads)
**Next Guide**: [DEVICE_TESTING_PLAN.md](DEVICE_TESTING_PLAN.md)
**Questions**: Check [COREML_MODELS_GUIDE.md](COREML_MODELS_GUIDE.md) for more details
