//
//  PerformanceHUDView.swift
//  NaviGPT
//
//  Phase 3: UI Integration
//  Heads-up display for performance metrics (FPS, latency, processing status)
//

import SwiftUI

/// Performance HUD showing FPS, latency, and processing status
struct PerformanceHUDView: View {
    let fps: Double
    let latency: TimeInterval
    let isProcessing: Bool
    var showDetailed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // FPS indicator
            HStack(spacing: 6) {
                Image(systemName: "gauge")
                    .foregroundColor(fpsColor)
                Text("FPS:")
                    .foregroundColor(.white.opacity(0.7))
                Text(String(format: "%.1f", fps))
                    .foregroundColor(fpsColor)
                    .fontWeight(.bold)
            }
            .font(.system(size: 12, design: .monospaced))

            // Latency indicator
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .foregroundColor(latencyColor)
                Text("Latency:")
                    .foregroundColor(.white.opacity(0.7))
                Text(String(format: "%.0f", latency * 1000))
                    .foregroundColor(latencyColor)
                    .fontWeight(.bold)
                Text("ms")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 10))
            }
            .font(.system(size: 12, design: .monospaced))

            // Processing status
            if isProcessing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.green)
                    Text("Processing")
                        .foregroundColor(.green)
                        .font(.system(size: 11, weight: .medium))
                }
            }

            // Performance level indicator
            if showDetailed {
                Divider()
                    .background(Color.white.opacity(0.3))

                HStack(spacing: 6) {
                    Circle()
                        .fill(performanceColor)
                        .frame(width: 8, height: 8)
                    Text(performanceLevel)
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 11))
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    // MARK: - Computed Properties

    private var fpsColor: Color {
        if fps >= 25 {
            return .green
        } else if fps >= 15 {
            return .yellow
        } else {
            return .red
        }
    }

    private var latencyColor: Color {
        let latencyMs = latency * 1000
        if latencyMs < 50 {
            return .green
        } else if latencyMs < 100 {
            return .yellow
        } else {
            return .red
        }
    }

    private var performanceLevel: String {
        let latencyMs = latency * 1000
        if fps >= 30 && latencyMs < 33 {
            return "Excellent"
        } else if fps >= 20 && latencyMs < 50 {
            return "Good"
        } else if fps >= 15 && latencyMs < 100 {
            return "Acceptable"
        } else {
            return "Poor"
        }
    }

    private var performanceColor: Color {
        let latencyMs = latency * 1000
        if fps >= 30 && latencyMs < 33 {
            return .green
        } else if fps >= 20 && latencyMs < 50 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Compact Variant

/// Compact version of performance HUD (single line)
struct CompactPerformanceHUDView: View {
    let fps: Double
    let latency: TimeInterval

    var body: some View {
        HStack(spacing: 8) {
            // FPS
            HStack(spacing: 3) {
                Image(systemName: "gauge")
                    .font(.system(size: 10))
                Text(String(format: "%.0f", fps))
                    .fontWeight(.bold)
            }
            .foregroundColor(fpsColor)

            Divider()
                .frame(height: 12)
                .background(Color.white.opacity(0.3))

            // Latency
            HStack(spacing: 3) {
                Image(systemName: "timer")
                    .font(.system(size: 10))
                Text(String(format: "%.0f", latency * 1000))
                    .fontWeight(.bold)
            }
            .foregroundColor(latencyColor)
        }
        .font(.system(size: 11, design: .monospaced))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
        )
    }

    private var fpsColor: Color {
        fps >= 25 ? .green : (fps >= 15 ? .yellow : .red)
    }

    private var latencyColor: Color {
        let latencyMs = latency * 1000
        return latencyMs < 50 ? .green : (latencyMs < 100 ? .yellow : .red)
    }
}

// MARK: - Preview

#Preview("Standard HUD") {
    VStack {
        Spacer()
        HStack {
            PerformanceHUDView(
                fps: 30.5,
                latency: 0.028,
                isProcessing: true,
                showDetailed: true
            )
            Spacer()
        }
        .padding()
    }
    .background(Color.gray)
}

#Preview("Multiple States") {
    VStack(spacing: 20) {
        // Excellent performance
        PerformanceHUDView(
            fps: 30.5,
            latency: 0.028,
            isProcessing: true,
            showDetailed: true
        )

        // Good performance
        PerformanceHUDView(
            fps: 22.0,
            latency: 0.045,
            isProcessing: false,
            showDetailed: true
        )

        // Poor performance
        PerformanceHUDView(
            fps: 12.5,
            latency: 0.120,
            isProcessing: true,
            showDetailed: true
        )

        // Compact variant
        CompactPerformanceHUDView(
            fps: 29.8,
            latency: 0.033
        )
    }
    .padding()
    .background(Color.gray)
}
