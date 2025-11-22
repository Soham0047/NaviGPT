# NaviGPT: AI-Powered Navigation Assistant for the Visually Impaired
## Research Progress Report - Phase 3 Completion
**Date:** November 21, 2025
**Project Status:** Phase 3 (Real-Time Integration & Hybrid AI) Complete

---

## 1. Abstract
NaviGPT is a mobile application designed to assist visually impaired users in navigating complex environments. This research project explores a **hybrid AI architecture**, combining low-latency on-device machine learning (CoreML) for immediate obstacle avoidance with high-latency, high-intelligence cloud models (GPT-4o) for semantic scene understanding and navigation. This report details the technical implementation of Phase 3, focusing on real-time sensory processing, indoor/outdoor context awareness, and the synchronization of visual data with geospatial navigation instructions.

## 2. Problem Statement
Existing navigation solutions for the visually impaired often lack:
1.  **Semantic Understanding:** Knowing *what* an obstacle is, not just that it exists.
2.  **Context Awareness:** Distinguishing between indoor (furniture, doors) and outdoor (traffic, curbs) environments.
3.  **Real-Time Feedback:** Providing immediate warnings for safety-critical obstacles while processing slower, detailed descriptions.

## 3. System Architecture

The system is built on iOS (Swift/SwiftUI) and follows a modular, event-driven architecture.

### 3.1. Hybrid AI Pipeline
The core innovation is the separation of concerns between "Fast System" (Safety) and "Slow System" (Understanding).

| Component | Technology | Latency | Function |
| :--- | :--- | :--- | :--- |
| **Fast System** | **CoreML (YOLOv8)** | < 100ms | Real-time object detection (cars, people, chairs). Triggers immediate haptic/audio warnings. |
| **Slow System** | **OpenAI GPT-4o** | ~2-4s | Detailed scene analysis ("What is in front of me?"). Verifies navigation instructions against visual reality. |

### 3.2. Key Modules
*   **`RealTimeCameraProcessor`**: The central engine that ingests video frames. It manages the CoreML inference loop, ensuring high FPS processing without blocking the main thread.
*   **`EnhancedLiDARProcessor`**: (On Pro models) Uses LiDAR depth maps to calculate precise distance. (On non-Pro models) Falls back to monocular depth estimation.
*   **`ObstacleAudioManager`**: An intelligent audio router that prioritizes alerts. It prevents "audio clutter" by debouncing repetitive warnings and prioritizing critical threats (e.g., "Car approaching" overrides "Bench nearby").
*   **`LLmManager`**: Manages the interface with GPT-4o, handling image compression (Base64), prompt engineering for context (Indoor vs. Outdoor), and error handling.

## 4. Technical Implementation Details

### 4.1. Real-Time Obstacle Detection
*   **Model:** YOLOv8 (You Only Look Once) quantized for mobile.
*   **Implementation:** `Vision` framework drives the CoreML model.
*   **Logic:** Frames are captured via `AVCaptureVideoDataOutput`. The `RealTimeCameraProcessor` runs inference. Detected objects are mapped to `Obstacle` structs with properties for `label`, `confidence`, and `distance`.
*   **Feedback:** If an obstacle is within 3 meters and high confidence, `ObstacleAudioManager` triggers a spoken warning immediately.

### 4.2. Context-Aware Navigation (Indoor/Outdoor)
We implemented a dynamic prompting system in `LLmManager` that adjusts based on the user's query and location data.
*   **Indoor Mode:** Triggered when GPS accuracy is low or manually detected. The prompt instructs the LLM to look for doors, hallways, and furniture.
*   **Outdoor Mode:** Triggered by GPS movement. The prompt focuses on traffic lights, crosswalks, and vehicles.
*   **Visual-Map Sync:** When navigating, the system sends both the **Map Instruction** (e.g., "Turn right") and the **Current Image** to the LLM. The LLM verifies if the turn is visible and safe, acting as a "visual co-pilot."

### 4.3. Hardware Abstraction & Compatibility
To ensure accessibility across different devices (e.g., iPhone 13 vs. iPhone 15 Pro):
*   **LiDAR Fallback:** `LiDARCameraViewController` checks for `.builtInLiDARDepthCamera`. If unavailable, it seamlessly switches to `.builtInWideAngleCamera` and disables depth-specific features while maintaining object detection.
*   **Permissions:** Robust handling of Camera, Microphone, and Location permissions with user-friendly speech prompts if denied.

## 5. Functional Capabilities (Current State)

### ✅ 1. "What is in front of me?"
*   **User Action:** Voice command or button press.
*   **System Response:** Captures photo -> Sends to GPT-4o -> Speaks detailed description (e.g., "You are in a living room. There is a sofa to your left and a doorway straight ahead.").

### ✅ 2. Safety Guard (Real-Time)
*   **User Action:** Walking with the app open.
*   **System Response:** Continuous scanning. If a user walks towards a wall or obstacle, the app speaks "Caution: Wall ahead" instantly, independent of internet connection.

### ✅ 3. Navigation Assistance
*   **User Action:** "Navigate to [Destination]".
*   **System Response:** Calculates route using MapKit. As the user moves, it provides turn-by-turn directions. The user can ask for visual confirmation ("Is this the right way?"), and the AI analyzes the street view to confirm.

## 6. Research Challenges & Solutions

*   **Challenge:** API Latency causing silence after photo capture.
    *   **Solution:** Implemented asynchronous dispatch groups and added intermediate audio feedback ("Image captured, analyzing..."). Switched to `gpt-4o` for faster inference.
*   **Challenge:** Audio Overlap (Navigation voice vs. Obstacle warning).
    *   **Solution:** `ObstacleAudioManager` implements a priority queue. Safety warnings interrupt navigation instructions; descriptive details wait for silence.
*   **Challenge:** Hardware fragmentation (No LiDAR on iPhone 13).
    *   **Solution:** Modularized the depth processing logic. The app now runs successfully on non-Pro models by gracefully degrading depth precision while keeping object recognition active.

## 7. Future Work (Phase 4 Roadmap)
*   **Spatial Audio:** Using 3D audio (HRTF) to place sound sources virtually in 3D space (e.g., a sound "beeping" from the actual direction of the obstacle).
*   **Custom Object Training:** Allowing users to "teach" the app specific objects (e.g., "This is my cane," "This is my keys").
*   **Offline LLM:** Investigating small language models (SLMs) to run semantic analysis entirely on-device for privacy and zero latency.

---
*Report generated by GitHub Copilot for NaviGPT Research Team.*
