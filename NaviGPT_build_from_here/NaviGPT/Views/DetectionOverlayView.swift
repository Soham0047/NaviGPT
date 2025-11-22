//
//  DetectionOverlayView.swift
//  NaviGPT
//
//  Phase 3: UI Integration
//  Visual overlay for detected objects with bounding boxes and labels
//

import SwiftUI

/// Visual overlay that displays detected obstacles with bounding boxes and labels
struct DetectionOverlayView: View {
    let obstacles: [Obstacle]
    let frameSize: CGSize
    @AppStorage("show_visual_overlay") private var showOverlay = true
    @AppStorage("show_confidence_badges") private var showConfidence = true
    @AppStorage("show_distance_labels") private var showDistance = true

    var body: some View {
        ZStack {
            if showOverlay {
                ForEach(obstacles) { obstacle in
                    BoundingBoxView(
                        obstacle: obstacle,
                        frameSize: frameSize,
                        showConfidence: showConfidence,
                        showDistance: showDistance
                    )
                }
            }
        }
    }
}

/// Individual bounding box view for a single obstacle
struct BoundingBoxView: View {
    let obstacle: Obstacle
    let frameSize: CGSize
    var showConfidence: Bool = true
    var showDistance: Bool = true

    var body: some View {
        let box = obstacle.boundingBox

        // Convert normalized coordinates to screen space
        let x = box.origin.x * frameSize.width
        let y = box.origin.y * frameSize.height
        let width = box.width * frameSize.width
        let height = box.height * frameSize.height

        ZStack(alignment: .topLeading) {
            // Bounding box rectangle
            Rectangle()
                .stroke(colorForUrgency(obstacle.urgencyLevel), lineWidth: 3)
                .frame(width: width, height: height)
                .shadow(color: colorForUrgency(obstacle.urgencyLevel).opacity(0.5), radius: 4)

            // Label background
            VStack(alignment: .leading, spacing: 2) {
                Text(obstacle.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                if showDistance {
                    Text(String(format: "%.1fm", obstacle.distance))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                }

                if showConfidence {
                    ConfidenceBadge(confidence: obstacle.confidence)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(colorForUrgency(obstacle.urgencyLevel).opacity(0.85))
                    .shadow(color: .black.opacity(0.3), radius: 2)
            )
            .offset(x: 4, y: -4)
        }
        .position(x: x + width/2, y: y + height/2)
    }

    private func colorForUrgency(_ urgency: Int) -> Color {
        switch urgency {
        case 3: return .red
        case 2: return .orange
        case 1: return .yellow
        default: return .green
        }
    }
}

/// Small badge showing detection confidence
struct ConfidenceBadge: View {
    let confidence: DetectionConfidence

    var body: some View {
        Text(shortDescription)
            .font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(3)
    }

    private var shortDescription: String {
        switch confidence {
        case .low: return "L"
        case .medium: return "M"
        case .high: return "H"
        case .veryHigh: return "VH"
        }
    }

    private var backgroundColor: Color {
        switch confidence {
        case .low: return Color.gray.opacity(0.6)
        case .medium: return Color.blue.opacity(0.6)
        case .high: return Color.green.opacity(0.6)
        case .veryHigh: return Color.purple.opacity(0.6)
        }
    }
}

// MARK: - Obstacle Identifiable Conformance

extension Obstacle: Identifiable {
    // id property already exists in Obstacle struct
}

// MARK: - Preview

#Preview {
    let sampleObstacles = [
        Obstacle(
            label: "Person",
            position: SpatialPoint(x: 1.0, y: 0.5, z: 2.0),
            confidence: .high,
            distance: 2.0,
            boundingBox: CGRect(x: 0.3, y: 0.2, width: 0.2, height: 0.4),
            bearing: 0.0
        ),
        Obstacle(
            label: "Car",
            position: SpatialPoint(x: -1.5, y: 0.5, z: 5.0),
            confidence: .veryHigh,
            distance: 5.2,
            boundingBox: CGRect(x: 0.1, y: 0.4, width: 0.3, height: 0.3),
            bearing: -30.0
        ),
        Obstacle(
            label: "Bicycle",
            position: SpatialPoint(x: 0.5, y: 0.5, z: 1.5),
            confidence: .medium,
            distance: 1.6,
            boundingBox: CGRect(x: 0.5, y: 0.3, width: 0.15, height: 0.3),
            bearing: 15.0
        )
    ]

    return ZStack {
        Color.black
        DetectionOverlayView(
            obstacles: sampleObstacles,
            frameSize: CGSize(width: 400, height: 600)
        )
    }
}
