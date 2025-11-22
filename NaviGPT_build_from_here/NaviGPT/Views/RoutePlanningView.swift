import SwiftUI
import MapKit

/// Route planning interface for navigation
/// Provides destination input, multi-modal transport options, turn-by-turn guidance
struct RoutePlanningView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var mapsManager: MapsManager
    
    // MARK: - State
    @State private var destinationText: String = ""
    @State private var transportMode: TransportMode = .walking
    @State private var avoidStairs: Bool = true
    @State private var preferWellLit: Bool = true
    @State private var isCalculatingRoute = false
    @State private var showRouteDetails = false
    @State private var selectedRoute: Route?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                // Destination Input
                Section {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        TextField("Where to?", text: $destinationText)
                            .textContentType(.location)
                            .submitLabel(.go)
                            .onSubmit {
                                calculateRoute()
                            }
                    }
                    
                    Button(action: {
                        // TODO: Location picker
                    }) {
                        Label("Choose from Map", systemImage: "map")
                    }
                    
                    Button(action: {
                        // TODO: Recent destinations
                    }) {
                        Label("Recent Destinations", systemImage: "clock")
                    }
                } header: {
                    Text("Destination")
                }
                
                // Transport Mode
                Section {
                    Picker("Mode", selection: $transportMode) {
                        Label("Walking", systemImage: "figure.walk")
                            .tag(TransportMode.walking)
                        Label("Transit", systemImage: "bus")
                            .tag(TransportMode.transit)
                        Label("Driving", systemImage: "car")
                            .tag(TransportMode.driving)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Transport Mode")
                }
                
                // Accessibility Preferences
                Section {
                    Toggle(isOn: $avoidStairs) {
                        Label("Avoid Stairs", systemImage: "figure.stairs")
                    }
                    
                    Toggle(isOn: $preferWellLit) {
                        Label("Prefer Well-Lit Routes", systemImage: "light.max")
                    }
                } header: {
                    Text("Accessibility Preferences")
                } footer: {
                    Text("These preferences help find routes suitable for navigation assistance.")
                }
                
                // Calculate Route Button
                Section {
                    Button(action: {
                        calculateRoute()
                    }) {
                        HStack {
                            if isCalculatingRoute {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isCalculatingRoute ? "Calculating..." : "Get Directions")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(destinationText.isEmpty || isCalculatingRoute)
                }
                
                // Route Preview (if available)
                if let route = selectedRoute {
                    Section {
                        RoutePreviewCard(route: route)
                        
                        Button(action: {
                            showRouteDetails = true
                        }) {
                            Label("View Turn-by-Turn Directions", systemImage: "list.bullet")
                        }
                    } header: {
                        Text("Route Overview")
                    }
                }
            }
            .navigationTitle("Plan Route")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start") {
                        startNavigation()
                    }
                    .disabled(selectedRoute == nil)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showRouteDetails) {
                if let route = selectedRoute {
                    TurnByTurnView(route: route)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func calculateRoute() {
        guard !destinationText.isEmpty else { return }
        
        isCalculatingRoute = true
        
        // Use existing MapsManager
        mapsManager.getDirections(to: destinationText)
        
        // Simulate route calculation
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
            
            // Create mock route (in production, get from MapsManager)
            selectedRoute = Route(
                destination: destinationText,
                distance: 1.2,
                duration: 15,
                steps: [
                    RouteStep(instruction: "Head north on Main St", distance: 0.3, duration: 4),
                    RouteStep(instruction: "Turn right onto Oak Ave", distance: 0.5, duration: 6),
                    RouteStep(instruction: "Continue straight", distance: 0.2, duration: 3),
                    RouteStep(instruction: "Arrive at destination", distance: 0.2, duration: 2)
                ],
                mode: transportMode
            )
            
            isCalculatingRoute = false
        }
    }
    
    private func startNavigation() {
        // TODO: Start turn-by-turn navigation
        dismiss()
    }
}

// MARK: - Supporting Types

enum TransportMode: String, CaseIterable {
    case walking = "Walking"
    case transit = "Transit"
    case driving = "Driving"
}

struct Route: Identifiable {
    let id = UUID()
    let destination: String
    let distance: Double // in km
    let duration: Int // in minutes
    let steps: [RouteStep]
    let mode: TransportMode
}

struct RouteStep: Identifiable {
    let id = UUID()
    let instruction: String
    let distance: Double // in km
    let duration: Int // in minutes
}

// MARK: - Supporting Views

struct RoutePreviewCard: View {
    let route: Route
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: route.mode == .walking ? "figure.walk" : 
                               (route.mode == .transit ? "bus" : "car"))
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("\(Int(route.duration)) min")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("\(route.distance, specifier: "%.1f") km")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(route.steps.count) steps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // First step preview
            if let firstStep = route.steps.first {
                HStack {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.green)
                    Text(firstStep.instruction)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TurnByTurnView: View {
    @Environment(\.dismiss) private var dismiss
    let route: Route
    @State private var currentStepIndex = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Current Step (Large)
                VStack(spacing: 16) {
                    Text("Step \(currentStepIndex + 1) of \(route.steps.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(route.steps[currentStepIndex].instruction)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            HStack {
                                Text("\(Int(route.steps[currentStepIndex].distance * 1000))m")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("\(route.steps[currentStepIndex].duration) min")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.blue.opacity(0.1))
                
                // All Steps
                List {
                    ForEach(Array(route.steps.enumerated()), id: \.element.id) { index, step in
                        HStack {
                            Image(systemName: "\(index + 1).circle.fill")
                                .foregroundColor(index == currentStepIndex ? .blue : .gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.instruction)
                                    .font(.body)
                                    .fontWeight(index == currentStepIndex ? .semibold : .regular)
                                
                                Text("\(Int(step.distance * 1000))m • \(step.duration) min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if index == currentStepIndex {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            currentStepIndex = index
                        }
                    }
                }
                
                // Navigation Controls
                HStack(spacing: 20) {
                    Button(action: {
                        if currentStepIndex > 0 {
                            currentStepIndex -= 1
                        }
                    }) {
                        Label("Previous", systemImage: "chevron.left")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(currentStepIndex == 0)
                    
                    Button(action: {
                        if currentStepIndex < route.steps.count - 1 {
                            currentStepIndex += 1
                        }
                    }) {
                        Label("Next", systemImage: "chevron.right")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(currentStepIndex == route.steps.count - 1)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
            }
            .navigationTitle("Turn-by-Turn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RoutePlanningView(mapsManager: MapsManager())
}
