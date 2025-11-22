import Foundation
import CoreML
import AVFoundation
import UIKit

/// Manages performance optimization for NaviGPT
/// Includes model quantization, multi-threading, GPU acceleration, battery monitoring
@MainActor
class PerformanceOptimizer: ObservableObject {
    static let shared = PerformanceOptimizer()
    
    // MARK: - Published Properties
    @Published var currentBatteryLevel: Float = 1.0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var targetFPS: Int = 15
    @Published var currentFPS: Double = 0
    @Published var isLowPowerModeEnabled: Bool = false
    
    // MARK: - Configuration
    struct PerformanceConfig {
        var enableGPUAcceleration: Bool = true
        var enableNeuralEngine: Bool = true
        var adaptiveQuality: Bool = true
        var maxFPS: Int = 25
        var minFPS: Int = 10
        var batteryThreshold: Float = 0.2 // 20%
        var thermalThrottlingEnabled: Bool = true
    }
    
    var config = PerformanceConfig()
    
    // MARK: - Private Properties
    private var batteryMonitoringTimer: Timer?
    private var performanceMonitoringTimer: Timer?
    private let processingQueue = DispatchQueue(label: "com.navigpt.performance", qos: .userInitiated)
    
    // MARK: - Initialization
    private init() {
        setupMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupMonitoring() {
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Initial readings
        updateBatteryState()
        updateThermalState()
        
        // Start periodic monitoring
        startMonitoring()
        
        // Observe system notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryStateChanged),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelChanged),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateChanged),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(powerModeChanged),
            name: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )
    }
    
    private func startMonitoring() {
        // Battery monitoring every 30 seconds
        batteryMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateBatteryState()
            }
        }
        
        // Performance monitoring every 1 second
        performanceMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.adjustPerformance()
            }
        }
    }
    
    // MARK: - Monitoring
    
    @objc private func batteryStateChanged() {
        Task { @MainActor in
            updateBatteryState()
        }
    }
    
    @objc private func batteryLevelChanged() {
        Task { @MainActor in
            updateBatteryState()
        }
    }
    
    @objc private func thermalStateChanged() {
        Task { @MainActor in
            updateThermalState()
        }
    }
    
    @objc private func powerModeChanged() {
        Task { @MainActor in
            isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
            adjustPerformance()
        }
    }
    
    private func updateBatteryState() {
        currentBatteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
        
        // Log battery warnings
        if currentBatteryLevel < config.batteryThreshold && batteryState != .charging {
            print("⚠️ Low battery: \(Int(currentBatteryLevel * 100))% - reducing performance")
        }
    }
    
    private func updateThermalState() {
        thermalState = ProcessInfo.processInfo.thermalState
        
        // Log thermal warnings
        switch thermalState {
        case .serious:
            print("⚠️ Thermal state: SERIOUS - throttling performance")
        case .critical:
            print("🔥 Thermal state: CRITICAL - aggressive throttling")
        default:
            break
        }
    }
    
    // MARK: - Performance Adjustment
    
    func adjustPerformance() {
        guard config.adaptiveQuality else { return }
        
        // Calculate target FPS based on conditions
        let baseFPS = config.maxFPS
        var adjustedFPS = baseFPS
        
        // Battery-based adjustment
        if batteryState != .charging {
            if currentBatteryLevel < config.batteryThreshold {
                adjustedFPS = min(adjustedFPS, config.minFPS)
            } else if currentBatteryLevel < 0.5 {
                adjustedFPS = min(adjustedFPS, (config.maxFPS + config.minFPS) / 2)
            }
        }
        
        // Thermal-based adjustment
        if config.thermalThrottlingEnabled {
            switch thermalState {
            case .serious:
                adjustedFPS = min(adjustedFPS, config.minFPS + 2)
            case .critical:
                adjustedFPS = config.minFPS
            default:
                break
            }
        }
        
        // Low power mode
        if isLowPowerModeEnabled {
            adjustedFPS = config.minFPS
        }
        
        targetFPS = max(adjustedFPS, config.minFPS)
    }
    
    // MARK: - CoreML Configuration
    
    /// Get optimized MLModelConfiguration based on current conditions
    func getOptimizedMLConfig() -> MLModelConfiguration {
        let config = MLModelConfiguration()
        
        // Compute units based on performance state
        if isLowPowerModeEnabled || thermalState == .critical {
            // CPU only for maximum power efficiency
            config.computeUnits = .cpuOnly
        } else if self.config.enableNeuralEngine && self.config.enableGPUAcceleration {
            // Use all available compute (Neural Engine + GPU + CPU)
            config.computeUnits = .all
        } else if self.config.enableNeuralEngine {
            // Neural Engine + CPU
            config.computeUnits = .cpuAndNeuralEngine
        } else if self.config.enableGPUAcceleration {
            // GPU + CPU
            config.computeUnits = .cpuAndGPU
        } else {
            // CPU only
            config.computeUnits = .cpuOnly
        }
        
        // Allow low precision accumulation for better performance
        config.allowLowPrecisionAccumulationOnGPU = true
        
        return config
    }
    
    /// Calculate frame processing interval based on target FPS
    func getFrameProcessingInterval() -> TimeInterval {
        return 1.0 / Double(targetFPS)
    }
    
    // MARK: - Performance Metrics
    
    func updateFPS(_ fps: Double) {
        currentFPS = fps
    }
    
    func getPerformanceReport() -> PerformanceReport {
        PerformanceReport(
            fps: currentFPS,
            targetFPS: targetFPS,
            batteryLevel: currentBatteryLevel,
            batteryState: batteryState,
            thermalState: thermalState,
            isLowPowerMode: isLowPowerModeEnabled,
            computeUnits: getOptimizedMLConfig().computeUnits
        )
    }
    
    // MARK: - Cleanup
    
    deinit {
        batteryMonitoringTimer?.invalidate()
        performanceMonitoringTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

struct PerformanceReport {
    let fps: Double
    let targetFPS: Int
    let batteryLevel: Float
    let batteryState: UIDevice.BatteryState
    let thermalState: ProcessInfo.ThermalState
    let isLowPowerMode: Bool
    let computeUnits: MLComputeUnits
    
    var batteryPercentage: Int {
        Int(batteryLevel * 100)
    }
    
    var batteryStatusText: String {
        switch batteryState {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "Unplugged"
        default: return "Unknown"
        }
    }
    
    var thermalStatusText: String {
        switch thermalState {
        case .nominal: return "Normal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
    
    var computeUnitsText: String {
        switch computeUnits {
        case .all: return "Neural Engine + GPU + CPU"
        case .cpuAndNeuralEngine: return "Neural Engine + CPU"
        case .cpuAndGPU: return "GPU + CPU"
        case .cpuOnly: return "CPU Only"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Extensions

extension ProcessInfo.ThermalState {
    var emoji: String {
        switch self {
        case .nominal: return "❄️"
        case .fair: return "🌡️"
        case .serious: return "🔥"
        case .critical: return "🚨"
        @unknown default: return "❓"
        }
    }
}

extension UIDevice.BatteryState {
    var emoji: String {
        switch self {
        case .charging: return "🔌"
        case .full: return "🔋"
        case .unplugged: return "📱"
        default: return "❓"
        }
    }
}
