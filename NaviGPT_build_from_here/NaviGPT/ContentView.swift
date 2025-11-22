import SwiftUI
import UIKit
import AVFoundation
import CoreLocation
import MapKit
import Photos

struct ContentView: View {
    @State private var isCameraActive = true
    @State private var userLocation: String?
    @State private var searchQuery = ""  // User input for destination address
    @StateObject private var mapsManager = MapsManager()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var capturedImage: UIImage?
    @State private var shouldCapturePhoto = false

    // Phase 3: Real-time processing
    @StateObject private var cameraProcessor = RealTimeCameraProcessor()
    @StateObject private var lidarProcessor = EnhancedLiDARProcessor()
    @StateObject private var obstacleAudioManager = ObstacleAudioManager()

    // Phase 3: UI toggles
    @State private var showPerformanceHUD = false // Hide HUD by default
    @State private var showDetectionOverlay = true
    @State private var enableAudioFeedback = true // Real-time audio feedback ENABLED
    @State private var showSettings = false

    let speechVoice = AVSpeechSynthesizer()
    let llmManager = LLmManager()

    var body: some View {
        VStack {
            // Add TextField for address input
            HStack {
                TextField("Enter destination address", text: $searchQuery, onCommit: {
                    // Trigger navigation when the user presses return
                    mapsManager.getDirections(to: searchQuery)
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading)

                Button(action: {
                    mapsManager.getDirections(to: searchQuery)
                }) {
                    Image(systemName: "magnifyingglass")
                        .padding(.trailing, 8)
                }
                
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .padding(.trailing)
                }
            }

            MapsView(userLocation: $userLocation, searchQuery: $searchQuery, mapsManager: mapsManager)
                .frame(height: UIScreen.main.bounds.height / 5)

            // Phase 3: Wrap camera view with overlays
            ZStack(alignment: .topLeading) {
                LiDARCameraView(
                    isCameraActive: $isCameraActive,
                    capturedImage: $capturedImage,
                    shouldCapturePhoto: $shouldCapturePhoto,
                    llmManager: llmManager,
                    userLocation: $userLocation,
                    mapsManager: mapsManager,
                    cameraProcessor: cameraProcessor,
                    lidarProcessor: lidarProcessor,
                    showPerformanceHUD: $showPerformanceHUD,
                    showDetectionOverlay: $showDetectionOverlay
                )

                // Phase 3: Detection overlay
                if showDetectionOverlay {
                    DetectionOverlayView(
                        obstacles: cameraProcessor.obstacles,
                        frameSize: CGSize(
                            width: UIScreen.main.bounds.width,
                            height: UIScreen.main.bounds.height / 2
                        )
                    )
                    .allowsHitTesting(false) // Allow touches to pass through
                }

                // Phase 3: Performance HUD
                if showPerformanceHUD {
                    VStack {
                        PerformanceHUDView(
                            fps: cameraProcessor.currentFPS,
                            latency: cameraProcessor.processingLatency,
                            isProcessing: cameraProcessor.isProcessing
                        )
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .frame(height: UIScreen.main.bounds.height / 2)

            HStack {
                Button(action: {
                    shouldCapturePhoto = true
                }) {
                    Image(systemName: "camera")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .font(.largeTitle)
                }

                Button(action: {
                    speechRecognizer.startTranscribing()
                }) {
                    Image(systemName: "mic")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(speechRecognizer.isRecording ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .font(.largeTitle)
                }
            }
            .frame(height: UIScreen.main.bounds.height / 10)
        }
        .onAppear {
            mapsManager.requestLocation()
            DispatchQueue.main.async {
                speechRecognizer.mapsManager = mapsManager
                speechRecognizer.onDescriptionRequested = {
                    self.shouldCapturePhoto = true
                }
            }
        }
        // Phase 3: Audio feedback for obstacles
        .onChange(of: cameraProcessor.obstacles) { oldValue, newValue in
            if enableAudioFeedback {
                let converted = convertObstacles(newValue)
                obstacleAudioManager.announceObstacles(converted)
            }
        }
        .onChange(of: lidarProcessor.spatialAudioGuidance) { oldValue, newValue in
            if enableAudioFeedback {
                obstacleAudioManager.announceSpatialGuidance(newValue)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - Helper Conversion
extension ContentView {
    private func convertObstacles(_ obstacles: [Obstacle]) -> [ObstacleInfo] {
        obstacles.map { obstacle in
            // Map label to ObstacleType if possible
            let type = mapLabelToType(obstacle.label)
            let position = mapBoundingBoxToPosition(obstacle.boundingBox)
            return ObstacleInfo(
                type: type,
                distance: Double(obstacle.distance),
                position: position,
                confidence: obstacle.confidence.rawValue,
                location: CGPoint(x: obstacle.boundingBox.midX, y: obstacle.boundingBox.midY)
            )
        }
    }

    private func mapLabelToType(_ label: String) -> ObstacleType {
        let l = label.lowercased()
        switch l {
        case "person": return .person
        case "car", "vehicle", "truck", "bus": return .vehicle
        case "bicycle", "bike": return .bicycle
        case "dog", "cat", "animal": return .animal
        case "chair", "table", "sofa", "furniture": return .furniture
        case "wall": return .wall
        case "door": return .door
        case "stairs", "stair": return .stairs
        case "curb": return .curb
        case "pole": return .pole
        case "tree": return .tree
        case "construction": return .construction
        default: return .unknown
        }
    }

    private func mapBoundingBoxToPosition(_ box: CGRect) -> ObstaclePosition {
        let x = box.midX
        switch x {
        case ..<0.2: return .farLeft
        case 0.2..<0.4: return .left
        case 0.4..<0.6: return .center
        case 0.6..<0.8: return .right
        default: return .farRight
        }
    }
}
