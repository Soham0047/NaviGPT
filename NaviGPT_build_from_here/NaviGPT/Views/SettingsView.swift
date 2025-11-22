import SwiftUI

/// Settings and preferences for NaviGPT
/// Provides accessibility controls, audio settings, haptic configuration
struct SettingsView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @StateObject private var audioManager = ObstacleAudioManager()
    @StateObject private var hapticManager = HapticFeedbackManager.shared
    
    // Audio Settings
    @AppStorage("audio_enabled") private var audioEnabled = true
    @AppStorage("audio_verbosity") private var audioVerbosity = AudioVerbosity.standard.rawValue
    @AppStorage("speech_rate") private var speechRate: Double = 0.6
    @AppStorage("speak_distance") private var speakDistance = true
    @AppStorage("speak_direction") private var speakDirection = true
    @AppStorage("announcement_interval") private var announcementInterval: Double = 1.5
    
    // Haptic Settings
    @AppStorage("haptic_enabled") private var hapticEnabled = true
    @AppStorage("haptic_intensity") private var hapticIntensity: Double = 1.0
    
    // Detection Settings
    @AppStorage("detection_sensitivity") private var detectionSensitivity: Double = 0.3
    @AppStorage("max_detection_distance") private var maxDetectionDistance: Double = 10.0
    @AppStorage("show_visual_overlay") private var showVisualOverlay = true
    
    // Privacy Settings
    @AppStorage("save_route_history") private var saveRouteHistory = true
    @AppStorage("analytics_enabled") private var analyticsEnabled = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                // Audio Section
                Section {
                    Toggle("Enable Audio Feedback", isOn: $audioEnabled)
                        .onChange(of: audioEnabled) { oldValue, newValue in
                            audioManager.isEnabled = newValue
                        }
                    
                    if audioEnabled {
                        Picker("Verbosity", selection: $audioVerbosity) {
                            Text("Concise").tag(AudioVerbosity.concise.rawValue)
                            Text("Standard").tag(AudioVerbosity.standard.rawValue)
                            Text("Verbose").tag(AudioVerbosity.verbose.rawValue)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Speech Rate: \(speechRate, specifier: "%.1f")x")
                                .font(.subheadline)
                            Slider(value: $speechRate, in: 0.3...1.0, step: 0.1)
                                .onChange(of: speechRate) { oldValue, newValue in
                                    audioManager.configuration.speechRate = Float(newValue)
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Announcement Interval: \(announcementInterval, specifier: "%.1f")s")
                                .font(.subheadline)
                            Slider(value: $announcementInterval, in: 0.5...5.0, step: 0.5)
                                .onChange(of: announcementInterval) { oldValue, newValue in
                                    audioManager.configuration.minimumAnnouncementInterval = newValue
                                }
                        }
                        
                        Toggle("Speak Distance", isOn: $speakDistance)
                            .onChange(of: speakDistance) { oldValue, newValue in
                                audioManager.configuration.speakDistance = newValue
                            }
                        
                        Toggle("Speak Direction", isOn: $speakDirection)
                            .onChange(of: speakDirection) { oldValue, newValue in
                                audioManager.configuration.speakDirection = newValue
                            }
                    }
                } header: {
                    Label("Audio Feedback", systemImage: "speaker.wave.2")
                } footer: {
                    Text("Configure how NaviGPT announces detected obstacles and navigation guidance.")
                }
                
                // Haptic Section
                Section {
                    Toggle("Enable Haptic Feedback", isOn: $hapticEnabled)
                        .onChange(of: hapticEnabled) { oldValue, newValue in
                            hapticManager.isEnabled = newValue
                        }
                    
                    if hapticEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Haptic Intensity: \(Int(hapticIntensity * 100))%")
                                .font(.subheadline)
                            Slider(value: $hapticIntensity, in: 0.2...1.0, step: 0.1)
                                .onChange(of: hapticIntensity) { oldValue, newValue in
                                    hapticManager.intensity = newValue
                                }
                        }
                        
                        Button("Test Haptic Feedback") {
                            hapticManager.playHaptic(.obstacleDetected(distance: 2.0, severity: .warning))
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    Label("Haptic Feedback", systemImage: "waveform")
                } footer: {
                    Text("Vibration patterns help you sense obstacles. Intensity increases as you get closer.")
                }
                
                // Detection Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detection Sensitivity: \(Int((1.0 - detectionSensitivity) * 100))%")
                            .font(.subheadline)
                        Slider(value: $detectionSensitivity, in: 0.1...0.7, step: 0.1)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Max Detection Distance: \(Int(maxDetectionDistance))m")
                            .font(.subheadline)
                        Slider(value: $maxDetectionDistance, in: 5...20, step: 1)
                    }
                    
                    Toggle("Show Visual Overlay", isOn: $showVisualOverlay)
                } header: {
                    Label("Detection Settings", systemImage: "eye")
                } footer: {
                    Text("Higher sensitivity detects more objects but may include false positives. Visual overlay shows detected objects on screen.")
                }
                
                // Privacy Section
                Section {
                    Toggle("Save Route History", isOn: $saveRouteHistory)
                    Toggle("Anonymous Analytics", isOn: $analyticsEnabled)
                } header: {
                    Label("Privacy", systemImage: "lock.shield")
                } footer: {
                    Text("Route history is stored locally only. Analytics help improve NaviGPT without collecting personal data.")
                }
                
                // Accessibility Section
                Section {
                    NavigationLink {
                        AccessibilityInfoView()
                    } label: {
                        Label("Accessibility Features", systemImage: "accessibility")
                    }
                    
                    NavigationLink {
                        KeyboardShortcutsView()
                    } label: {
                        Label("Keyboard Shortcuts", systemImage: "keyboard")
                    }
                } header: {
                    Label("Accessibility", systemImage: "hand.raised")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Phase 4)")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink {
                        LicenseView()
                    } label: {
                        Label("License & Attribution", systemImage: "doc.text")
                    }
                    
                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    .foregroundColor(.red)
                } header: {
                    Label("About", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func resetToDefaults() {
        audioEnabled = true
        audioVerbosity = AudioVerbosity.standard.rawValue
        speechRate = 0.6
        speakDistance = true
        speakDirection = true
        announcementInterval = 1.5
        
        hapticEnabled = true
        hapticIntensity = 1.0
        
        detectionSensitivity = 0.3
        maxDetectionDistance = 10.0
        showVisualOverlay = true
        
        saveRouteHistory = true
        analyticsEnabled = false
        
        // Update managers
        audioManager.isEnabled = true
        audioManager.configuration = .init()
        hapticManager.isEnabled = true
        hapticManager.intensity = 1.0
    }
}

// MARK: - Supporting Types

enum AudioVerbosity: String, CaseIterable {
    case concise = "concise"
    case standard = "standard"
    case verbose = "verbose"
}

// MARK: - Supporting Views

struct AccessibilityInfoView: View {
    var body: some View {
        List {
            Section {
                InfoRow(title: "VoiceOver Support", description: "Full VoiceOver support for all UI elements")
                InfoRow(title: "Large Text", description: "Dynamic Type support for adjustable text sizes")
                InfoRow(title: "High Contrast", description: "Respects system high contrast settings")
                InfoRow(title: "Reduce Motion", description: "Minimal animations when Reduce Motion is enabled")
            } header: {
                Text("Built-in Features")
            }
            
            Section {
                InfoRow(title: "Spatial Audio", description: "3D audio cues guide you toward clear paths")
                InfoRow(title: "Haptic Navigation", description: "Vibration patterns indicate obstacles and directions")
                InfoRow(title: "Continuous Scanning", description: "Real-time object detection with 15+ FPS processing")
                InfoRow(title: "Offline Mode", description: "Core navigation works without internet connection")
            } header: {
                Text("NaviGPT Features")
            }
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct KeyboardShortcutsView: View {
    var body: some View {
        List {
            Section {
                ShortcutRow(key: "Space", action: "Start/Stop Navigation")
                ShortcutRow(key: "R", action: "Repeat Last Announcement")
                ShortcutRow(key: "S", action: "Stop Speaking")
                ShortcutRow(key: "M", action: "Toggle Audio Mute")
            } header: {
                Text("Navigation")
            }
            
            Section {
                ShortcutRow(key: "⌘ ,", action: "Open Settings")
                ShortcutRow(key: "⌘ H", action: "Show Help")
                ShortcutRow(key: "⌘ Q", action: "Quit App")
            } header: {
                Text("General")
            }
        }
        .navigationTitle("Keyboard Shortcuts")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct LicenseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("NaviGPT")
                    .font(.title)
                    .bold()
                
                Text("Real-Time AI-Driven Mobile Navigation System for People with Visual Impairments")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("License")
                        .font(.headline)
                    
                    Text("CC BY-NC 4.0 (Creative Commons Attribution-NonCommercial)")
                        .font(.subheadline)
                    
                    Text("""
                    This work is licensed under a Creative Commons Attribution-NonCommercial 4.0 International License.
                    
                    You are free to:
                    • Share — copy and redistribute the material
                    • Adapt — remix, transform, and build upon the material
                    
                    Under the following terms:
                    • Attribution — You must give appropriate credit
                    • NonCommercial — You may not use the material for commercial purposes
                    """)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Authors")
                        .font(.headline)
                    
                    Text("He Zhang, Nicholas J. Falletta, Jingyi Xie, Rui Yu, Sooyeon Lee, Syed Masum Billah, John M. Carroll")
                        .font(.subheadline)
                    
                    Text("Penn State University")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Publication")
                        .font(.headline)
                    
                    Text("GROUP '25: ACM Conference on Supporting Group Work")
                        .font(.subheadline)
                    
                    Link("View Paper (ACM Digital Library)", destination: URL(string: "https://doi.org/10.1145/3688828.3699636")!)
                        .font(.caption)
                }
                
                Divider()
                
                Text("© 2024-2025 PSU-IST-CIL NaviGPT Team")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("License")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct InfoRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ShortcutRow: View {
    let key: String
    let action: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            
            Spacer()
            
            Text(action)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}
