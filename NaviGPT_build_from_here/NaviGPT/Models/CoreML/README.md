# CoreML Models Directory

This directory is for CoreML model files (.mlmodel or .mlpackage) used by NaviGPT.

## Required Models

Place the following models in this directory:

1. **YOLOv8.mlmodel** - Object detection
2. **DepthEstimation.mlmodel** - Depth estimation
3. **SceneClassifier.mlmodel** - Scene classification

## Getting Models

See the main [PHASE3_COREML_MODELS.md](../../../../PHASE3_COREML_MODELS.md) guide for:
- Where to download models
- How to convert models
- How to add models to Xcode project

## Current Status

⚠️ **Models not included in repository**

The models are not included due to:
- Large file sizes (would bloat repository)
- Licensing considerations
- Users may want different model variants

## Without Models

The app will still:
- ✅ Build successfully
- ✅ Run without crashes
- ⚠️ Have limited ML functionality
- ⚠️ Skip model-dependent tests

## With Models

Once models are added:
- ✅ Full object detection
- ✅ ML-based depth estimation
- ✅ Scene understanding
- ✅ Complete test coverage
- ✅ Production-ready navigation features

## Next Steps

1. Follow [PHASE3_COREML_MODELS.md](../../../../PHASE3_COREML_MODELS.md)
2. Download or convert required models
3. Add models to this directory
4. Add models to Xcode project (drag & drop)
5. Build and test

---

**Note**: Make sure to add models to `.gitignore` if they're large or proprietary.
