# CoreML Model Sources for NaviGPT

## 1. Object Detection (YOLOv8)

### Option A: Ultralytics YOLOv8
- Repository: https://github.com/ultralytics/ultralytics
- Documentation: https://docs.ultralytics.com/modes/export/#arguments
- Export to CoreML:
  ```python
  from ultralytics import YOLO
  model = YOLO('yolov8n.pt')  # nano model for mobile
  model.export(format='coreml')
  ```

### Option B: Pre-converted Models
- Check Apple's Machine Learning page
- Or use existing YOLOv5 CoreML models as placeholder

## 2. Depth Estimation

### Option A: Apple's Depth Estimation
- Available at: developer.apple.com/machine-learning/models/
- Search for "depth" models

### Option B: MiDAS CoreML
- Convert from: https://github.com/isl-org/MiDAS
- Use CoreML Tools: https://coremltools.apple.com/

## 3. Scene Classification

### MobileNetV2 (Places365)
- Pre-trained on: http://places2.csail.mit.edu/
- Apple CoreML version available
- Classifies 365 scene categories

## Installation Steps

1. Download .mlmodel or .mlpackage files
2. Add to Xcode project:
   - Drag files into Project Navigator
   - Add to NaviGPT target
   - Verify in "Copy Bundle Resources" build phase

3. Models should appear in project structure:
   ```
   NaviGPT/
   ├── Models/
   │   ├── CoreML/
   │   │   ├── YOLOv8.mlmodel
   │   │   ├── DepthEstimation.mlmodel
   │   │   └── SceneClassifier.mlmodel
   ```

## For Development/Testing

If models are unavailable, the code gracefully handles:
- `.modelNotFound` errors
- Returns empty detection results
- Logs warnings instead of crashing

