import Foundation
import CoreLocation

/// Manages local data persistence, caching, and offline mode
@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // MARK: - Published Properties
    @Published var recentDestinations: [SavedLocation] = []
    @Published var routeHistory: [SavedRoute] = []
    @Published var userPreferences: UserPreferences = UserPreferences()
    @Published var isOfflineModeEnabled: Bool = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private var cacheDirectory: URL?
    
    // Keys for UserDefaults
    private enum Keys {
        static let recentDestinations = "recent_destinations"
        static let routeHistory = "route_history"
        static let userPreferences = "user_preferences"
        static let offlineMode = "offline_mode_enabled"
    }
    
    // MARK: - Initialization
    private init() {
        setupCacheDirectory()
        loadAllData()
    }
    
    // MARK: - Setup
    
    private func setupCacheDirectory() {
        do {
            let cachesDir = try fileManager.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            cacheDirectory = cachesDir.appendingPathComponent("NaviGPT", isDirectory: true)
            
            if let cacheDir = cacheDirectory, !fileManager.fileExists(atPath: cacheDir.path) {
                try fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            }
            
            print("✅ Cache directory set up: \(cacheDirectory?.path ?? "unknown")")
        } catch {
            print("❌ Failed to setup cache directory: \(error)")
        }
    }
    
    // MARK: - Data Loading
    
    private func loadAllData() {
        loadRecentDestinations()
        loadRouteHistory()
        loadUserPreferences()
        loadOfflineMode()
    }
    
    private func loadRecentDestinations() {
        if let data = userDefaults.data(forKey: Keys.recentDestinations) {
            do {
                recentDestinations = try JSONDecoder().decode([SavedLocation].self, from: data)
                print("✅ Loaded \(recentDestinations.count) recent destinations")
            } catch {
                print("❌ Failed to load recent destinations: \(error)")
            }
        }
    }
    
    private func loadRouteHistory() {
        if let data = userDefaults.data(forKey: Keys.routeHistory) {
            do {
                routeHistory = try JSONDecoder().decode([SavedRoute].self, from: data)
                // Keep only last 50 routes
                if routeHistory.count > 50 {
                    routeHistory = Array(routeHistory.prefix(50))
                }
                print("✅ Loaded \(routeHistory.count) routes from history")
            } catch {
                print("❌ Failed to load route history: \(error)")
            }
        }
    }
    
    private func loadUserPreferences() {
        if let data = userDefaults.data(forKey: Keys.userPreferences) {
            do {
                userPreferences = try JSONDecoder().decode(UserPreferences.self, from: data)
                print("✅ Loaded user preferences")
            } catch {
                print("❌ Failed to load preferences: \(error)")
            }
        }
    }
    
    private func loadOfflineMode() {
        isOfflineModeEnabled = userDefaults.bool(forKey: Keys.offlineMode)
    }
    
    // MARK: - Destination Management
    
    func saveDestination(_ location: SavedLocation) {
        // Remove duplicates
        recentDestinations.removeAll { $0.name == location.name }
        
        // Add to front
        recentDestinations.insert(location, at: 0)
        
        // Keep only last 20
        if recentDestinations.count > 20 {
            recentDestinations = Array(recentDestinations.prefix(20))
        }
        
        saveRecentDestinations()
    }
    
    func removeDestination(_ location: SavedLocation) {
        recentDestinations.removeAll { $0.id == location.id }
        saveRecentDestinations()
    }
    
    func clearRecentDestinations() {
        recentDestinations = []
        saveRecentDestinations()
    }
    
    private func saveRecentDestinations() {
        do {
            let data = try JSONEncoder().encode(recentDestinations)
            userDefaults.set(data, forKey: Keys.recentDestinations)
            print("✅ Saved \(recentDestinations.count) recent destinations")
        } catch {
            print("❌ Failed to save recent destinations: \(error)")
        }
    }
    
    // MARK: - Route History Management
    
    func saveRoute(_ route: SavedRoute) {
        routeHistory.insert(route, at: 0)
        
        // Keep only last 50
        if routeHistory.count > 50 {
            routeHistory = Array(routeHistory.prefix(50))
        }
        
        saveRouteHistory()
    }
    
    func clearRouteHistory() {
        routeHistory = []
        saveRouteHistory()
    }
    
    private func saveRouteHistory() {
        do {
            let data = try JSONEncoder().encode(routeHistory)
            userDefaults.set(data, forKey: Keys.routeHistory)
            print("✅ Saved \(routeHistory.count) routes to history")
        } catch {
            print("❌ Failed to save route history: \(error)")
        }
    }
    
    // MARK: - Preferences Management
    
    func updatePreferences(_ preferences: UserPreferences) {
        userPreferences = preferences
        saveUserPreferences()
    }
    
    private func saveUserPreferences() {
        do {
            let data = try JSONEncoder().encode(userPreferences)
            userDefaults.set(data, forKey: Keys.userPreferences)
            print("✅ Saved user preferences")
        } catch {
            print("❌ Failed to save preferences: \(error)")
        }
    }
    
    // MARK: - Offline Mode
    
    func setOfflineMode(_ enabled: Bool) {
        isOfflineModeEnabled = enabled
        userDefaults.set(enabled, forKey: Keys.offlineMode)
        print("✅ Offline mode: \(enabled ? "ENABLED" : "DISABLED")")
    }
    
    // MARK: - Cache Management
    
    func cacheData(_ data: Data, filename: String) throws {
        guard let cacheDir = cacheDirectory else {
            throw DataError.cacheDirectoryNotAvailable
        }
        
        let fileURL = cacheDir.appendingPathComponent(filename)
        try data.write(to: fileURL)
        print("✅ Cached data: \(filename)")
    }
    
    func loadCachedData(filename: String) throws -> Data {
        guard let cacheDir = cacheDirectory else {
            throw DataError.cacheDirectoryNotAvailable
        }
        
        let fileURL = cacheDir.appendingPathComponent(filename)
        let data = try Data(contentsOf: fileURL)
        print("✅ Loaded cached data: \(filename)")
        return data
    }
    
    func clearCache() throws {
        guard let cacheDir = cacheDirectory else { return }
        
        let contents = try fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
        for file in contents {
            try fileManager.removeItem(at: file)
        }
        print("✅ Cleared cache")
    }
    
    func getCacheSize() -> Int64 {
        guard let cacheDir = cacheDirectory else { return 0 }
        
        var totalSize: Int64 = 0
        
        if let contents = try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) {
            for fileURL in contents {
                if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }
        
        return totalSize
    }
    
    // MARK: - Data Export/Import
    
    func exportAllData() throws -> Data {
        let exportData = ExportData(
            destinations: recentDestinations,
            routes: routeHistory,
            preferences: userPreferences,
            exportDate: Date()
        )
        
        return try JSONEncoder().encode(exportData)
    }
    
    func importData(from data: Data) throws {
        let importData = try JSONDecoder().decode(ExportData.self, from: data)
        
        recentDestinations = importData.destinations
        routeHistory = importData.routes
        userPreferences = importData.preferences
        
        saveAllData()
        print("✅ Imported data from \(importData.exportDate)")
    }
    
    private func saveAllData() {
        saveRecentDestinations()
        saveRouteHistory()
        saveUserPreferences()
    }
}

// MARK: - Supporting Types

struct SavedLocation: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: CoordinateCodable
    let savedDate: Date
    
    init(id: UUID = UUID(), name: String, address: String, coordinate: CLLocationCoordinate2D, savedDate: Date = Date()) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = CoordinateCodable(coordinate: coordinate)
        self.savedDate = savedDate
    }
}

struct SavedRoute: Identifiable, Codable {
    let id: UUID
    let origin: String
    let destination: String
    let distance: Double // km
    let duration: Int // minutes
    let completedDate: Date
    
    init(id: UUID = UUID(), origin: String, destination: String, distance: Double, duration: Int, completedDate: Date = Date()) {
        self.id = id
        self.origin = origin
        self.destination = destination
        self.distance = distance
        self.duration = duration
        self.completedDate = completedDate
    }
}

struct UserPreferences: Codable {
    var avoidStairs: Bool = true
    var preferWellLit: Bool = true
    var defaultTransportMode: String = "walking"
    var announceStreetNames: Bool = true
    var announceIntersections: Bool = true
    var voiceGuidance: Bool = true
}

struct CoordinateCodable: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    
    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct ExportData: Codable {
    let destinations: [SavedLocation]
    let routes: [SavedRoute]
    let preferences: UserPreferences
    let exportDate: Date
}

enum DataError: Error, LocalizedError {
    case cacheDirectoryNotAvailable
    case fileNotFound
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .cacheDirectoryNotAvailable:
            return "Cache directory is not available"
        case .fileNotFound:
            return "File not found"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
}
