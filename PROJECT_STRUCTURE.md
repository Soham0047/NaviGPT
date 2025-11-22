# NaviGPT Project Structure

## 📁 Directory Organization

```
NaviGPT/
├── 📄 Documentation
│   ├── README.md                      # Project overview
│   ├── DEVELOPMENT_PHASES.md          # Complete development phases
│   ├── PROJECT_STRUCTURE.md           # This file
│   ├── PHASE1_TESTING_SETUP.md        # Phase 1 setup guide
│   ├── PHASE2_README.md               # Phase 2 technical details
│   ├── PHASE3_COREML_MODELS.md        # Model integration guide
│   ├── CONFIGURATION_SETUP.md         # API configuration
│   └── LICENSE                        # CC BY-NC 4.0 license
│
├── 🛠️ Configuration
│   ├── .env.example                   # Template for API keys
│   ├── .gitignore                     # Git ignore rules
│   └── setup-config.sh                # Configuration setup script
│
├── 🔧 Build Scripts
│   ├── add_to_xcode.py               # Add files to Xcode
│   ├── add_phase_files_to_xcode.py   # Phase files integration
│   ├── add_file_xcode.scpt           # AppleScript helper
│   ├── add_files_to_xcode.scpt       # Batch file addition
│   ├── run_tests.sh                  # Test runner
│   ├── fix_path.py                   # Path fixer utility
│   └── remove_refs.py                # Reference cleanup
│
└── 📱 NaviGPT_build_from_here/
    ├── NaviGPT.xcodeproj             # Xcode project
    │
    ├── 🎯 NaviGPT/ (Main Target)
    │   │
    │   ├── 🏗️ Core App (Phase 0)
    │   │   ├── Intern1App.swift      # App entry point
    │   │   ├── ContentView.swift     # Main UI
    │   │   └── NaviGPTCore.swift     # Core logic (Phase 1)
    │   │
    │   ├── 📸 Camera & LiDAR (Phase 0)
    │   │   ├── LiDARCameraView.swift           # LiDAR UI
    │   │   ├── LiDARCameraViewController.swift # LiDAR controller
    │   │   ├── CameraPreviewView.swift         # Camera preview
    │   │   └── cameraManager.swift             # Camera operations
    │   │
    │   ├── 🗺️ Maps & Navigation (Phase 0)
    │   │   ├── MapsView.swift          # Map UI
    │   │   └── mapsManager.swift       # Map functionality
    │   │
    │   ├── 🎤 Speech & Audio (Phase 0)
    │   │   ├── SpeechManager.swift     # Text-to-speech
    │   │   └── speechRecognizer.swift  # Speech-to-text
    │   │
    │   ├── 🤖 LLM Integration (Phase 0)
    │   │   └── llmManager.swift        # OpenAI GPT-4 integration
    │   │
    │   ├── ⚙️ Configuration (Phase 1)
    │   │   ├── ConfigManager.swift     # Multi-source config
    │   │   └── Config.plist.example    # Config template
    │   │
    │   ├── 📊 Models/ (Phase 1 & 2)
    │   │   ├── ObstacleInfo.swift      # Obstacle detection (Phase 1)
    │   │   ├── NavigationContext.swift # Navigation state (Phase 1)
    │   │   ├── VisionModels.swift      # Vision models (Phase 1)
    │   │   ├── ModelTypes.swift        # ML type system (Phase 2)
    │   │   │
    │   │   └── CoreML/                 # CoreML models (Phase 3)
    │   │       ├── README.md           # Models guide
    │   │       ├── YOLOv8.mlmodel      # Object detection (to be added)
    │   │       ├── DepthEstimation.mlmodel  # Depth ML (to be added)
    │   │       └── SceneClassifier.mlmodel  # Scene classification (to be added)
    │   │
    │   ├── 🔬 Services/ (Phase 2)
    │   │   ├── CoreMLModelManager.swift        # Model lifecycle
    │   │   ├── VisionModelProcessor.swift      # Object detection
    │   │   └── DepthEstimationProcessor.swift  # Depth processing
    │   │
    │   ├── 🧪 Tests/
    │   │   ├── ConfigManagerTests.swift  # Config tests (Phase 1)
    │   │   └── ObstacleInfoTests.swift   # Obstacle tests (Phase 1)
    │   │
    │   ├── 🎨 Assets
    │   │   ├── Assets.xcassets         # App assets
    │   │   └── Preview Content/        # Preview assets
    │   │
    │   └── 📋 Resources
    │       └── Base.lproj/
    │           └── Info.plist          # App info
    │
    ├── 🧪 Intern1Tests/ (Test Target)
    │   ├── Intern1Tests.swift         # Base tests (Phase 0)
    │   └── Phase2Tests.swift          # ML tests (Phase 2)
    │
    ├── 🧪 Intern1UITests/ (UI Test Target)
    │   ├── Intern1UITests.swift
    │   └── Intern1UITestsLaunchTests.swift
    │
    └── 📦 NaviGPTTests/ (Additional Tests)
        └── (Test files)
```

## 📊 File Count by Phase

### Phase 0: Initial Setup (10 files)
- Core app structure: 3 files
- Camera & LiDAR: 4 files
- Maps: 2 files
- Speech: 2 files
- LLM: 1 file

### Phase 1: Configuration & Testing (6 files)
- Configuration: 2 files
- Models: 3 files
- Tests: 2 files
- Documentation: 2 files

### Phase 2: CoreML Integration (7 files)
- Services: 3 files
- Models: 1 file
- Tests: 1 file
- Documentation: 2 files

### Phase 3: Planned (3+ model files)
- CoreML models: TBD
- Camera pipeline: TBD
- LiDAR enhancement: TBD

## 🎯 Key Entry Points

### Main Application
- **Entry Point**: `Intern1App.swift`
- **Main View**: `ContentView.swift`
- **Core Logic**: `NaviGPTCore.swift`

### Configuration
- **Config Manager**: `ConfigManager.swift`
- **Environment**: `.env` (create from `.env.example`)

### ML/AI Components
- **Model Manager**: `Services/CoreMLModelManager.swift`
- **Vision Processing**: `Services/VisionModelProcessor.swift`
- **Depth Processing**: `Services/DepthEstimationProcessor.swift`

### Testing
- **Base Tests**: `Intern1Tests/Intern1Tests.swift`
- **ML Tests**: `Intern1Tests/Phase2Tests.swift`
- **Config Tests**: `NaviGPT/Tests/ConfigManagerTests.swift`

## 🔍 Finding Specific Functionality

### LiDAR & Camera
```
NaviGPT/LiDARCameraView.swift          - UI for LiDAR camera
NaviGPT/LiDARCameraViewController.swift - LiDAR controller
NaviGPT/cameraManager.swift            - Camera operations
```

### Navigation & Maps
```
NaviGPT/MapsView.swift     - Map UI
NaviGPT/mapsManager.swift  - Map functionality
```

### Speech & Audio
```
NaviGPT/SpeechManager.swift    - Text-to-speech
NaviGPT/speechRecognizer.swift - Speech recognition
```

### AI & ML
```
NaviGPT/llmManager.swift                          - LLM (GPT-4)
Services/CoreMLModelManager.swift                 - CoreML models
Services/VisionModelProcessor.swift               - Object detection
Services/DepthEstimationProcessor.swift           - Depth estimation
```

### Data Models
```
Models/ObstacleInfo.swift      - Obstacle data
Models/NavigationContext.swift - Navigation state
Models/VisionModels.swift      - Vision data
Models/ModelTypes.swift        - ML type system
```

## 📝 Documentation Map

### Getting Started
1. **README.md** - Project overview and quick start
2. **CONFIGURATION_SETUP.md** - Set up API keys
3. **DEVELOPMENT_PHASES.md** - Understand project phases

### Phase-Specific Guides
1. **PHASE1_TESTING_SETUP.md** - Phase 1 setup
2. **PHASE2_README.md** - Phase 2 technical details
3. **PHASE3_COREML_MODELS.md** - Model integration

### Project Structure
- **PROJECT_STRUCTURE.md** - This file

## 🔗 Quick Navigation

### To build the project:
```bash
cd NaviGPT_build_from_here
open NaviGPT.xcodeproj
# Press Cmd+B to build
```

### To run tests:
```bash
cd NaviGPT_build_from_here
xcodebuild test -scheme Intern1
# Or press Cmd+U in Xcode
```

### To add CoreML models:
```bash
# 1. Place .mlmodel files in NaviGPT/Models/CoreML/
# 2. In Xcode: Right-click NaviGPT → Add Files → Select models
# 3. Ensure "NaviGPT" target is checked
```

## 🏗️ Build Configuration

### Targets
- **NaviGPT** - Main app target
- **NaviGPTTests** - Unit tests
- **NaviGPTUITests** - UI tests

### Schemes
- **Intern1** - Main build scheme

### Requirements
- Xcode 15.4+
- iOS 17.2+
- iPhone 12 Pro or later (for LiDAR)
- Swift 5.0

## 📦 Dependencies

### System Frameworks
- **CoreML** - ML model execution
- **Vision** - Computer vision
- **ARKit** - LiDAR & AR features
- **AVFoundation** - Camera & audio
- **MapKit** - Maps & navigation
- **SwiftUI** - UI framework

### External Dependencies
- **OpenAI API** - GPT-4 integration (requires API key)

## 🎨 Asset Organization

### Assets.xcassets
- App icons
- Colors
- Images

### Preview Content
- Preview assets for SwiftUI previews
- Development-only assets

---

**Last Updated**: November 2024
**For Questions**: See README.md or DEVELOPMENT_PHASES.md
