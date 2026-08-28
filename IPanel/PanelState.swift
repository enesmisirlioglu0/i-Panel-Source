//
//  PanelState.swift
//  i-Panel
//
//  First phase: every metric is generated locally as simulation data.
//  No Mac hardware sensor, system setting, network connection, or cloud
//  account is accessed.
//

import Combine
import Foundation
import SwiftUI

enum PanelMetric: String, CaseIterable, Identifiable {
    case cpu
    case memory
    case disk
    case battery
    case network

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cpu:
            "CPU"
        case .memory:
            "Bellek"
        case .disk:
            "Disk"
        case .battery:
            "Batarya"
        case .network:
            "İnternet"
        }
    }

    var systemImage: String {
        switch self {
        case .cpu:
            "cpu"
        case .memory:
            "memorychip"
        case .disk:
            "internaldrive"
        case .battery:
            "battery.75percent"
        case .network:
            "arrow.up.arrow.down.circle"
        }
    }

    var tint: Color {
        switch self {
        case .cpu:
            .orange
        case .memory:
            .purple
        case .disk:
            .blue
        case .battery:
            .green
        case .network:
            .cyan
        }
    }
}

struct MetricCard: Identifiable {
    let metric: PanelMetric
    let detail: String
    let value: String
    let status: String
    let progress: Double

    var id: PanelMetric { metric }
}

private struct SimulatedSnapshot {
    var cpuUsage = 42
    var memoryUsage = 56
    var memoryUsedGB = 9
    var diskUsage = 61
    var diskUsedGB = 312
    var batteryLevel = 76
    var batteryTemperature = 32
    var batteryStatus = "Normal"
    var downloadRate = 14.2
    var uploadRate = 2.4
}

@MainActor
final class PanelState: ObservableObject {
    @Published private(set) var metricOrder = PanelMetric.allCases
    @Published private(set) var draggedMetric: PanelMetric?

    private var snapshot = SimulatedSnapshot()
    private var simulationTick = 0
    private var simulationTimer: AnyCancellable?

    init() {
        refreshSimulation()

        simulationTimer = Timer.publish(every: 1.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshSimulation()
                }
            }
    }

    var orderedMetrics: [MetricCard] {
        metricOrder.map(metricCard(for:))
    }

    func refreshSimulation() {
        simulationTick += 1

        let phase = Double(simulationTick)
        let cpuUsage = 34 + Int((sin(phase * 0.62) + 1) * 19)
        let memoryUsage = 50 + Int((sin(phase * 0.27 + 0.9) + 1) * 12)
        let diskUsage = 61 + Int((sin(phase * 0.08) + 1) * 2)
        let batteryLevel = max(18, 77 - (simulationTick % 18))
        let batteryTemperature = 30 + Int((sin(phase * 0.42) + 1) * 3)
        let downloadRate = 5.8 + abs(sin(phase * 0.74)) * 22.4
        let uploadRate = 0.7 + abs(cos(phase * 0.51)) * 4.3

        snapshot = SimulatedSnapshot(
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            memoryUsedGB: max(1, Int((Double(memoryUsage) / 100) * 16)),
            diskUsage: diskUsage,
            diskUsedGB: Int((Double(diskUsage) / 100) * 512),
            batteryLevel: batteryLevel,
            batteryTemperature: batteryTemperature,
            batteryStatus: batteryStatus(for: batteryLevel),
            downloadRate: downloadRate,
            uploadRate: uploadRate
        )
    }

    func resetMetricOrder() {
        withAnimation(.easeInOut(duration: 0.2)) {
            metricOrder = PanelMetric.allCases
        }
        finishDragging()
    }

    func beginDragging(_ metric: PanelMetric) {
        draggedMetric = metric
    }

    func moveDraggedMetric(to destination: PanelMetric) {
        guard let draggedMetric,
              draggedMetric != destination,
              let sourceIndex = metricOrder.firstIndex(of: draggedMetric) else {
            return
        }

        var reorderedMetrics = metricOrder
        reorderedMetrics.remove(at: sourceIndex)

        guard let destinationIndex = reorderedMetrics.firstIndex(of: destination) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            reorderedMetrics.insert(draggedMetric, at: destinationIndex)
            metricOrder = reorderedMetrics
        }
    }

    func finishDragging() {
        draggedMetric = nil
    }

    private func metricCard(for metric: PanelMetric) -> MetricCard {
        switch metric {
        case .cpu:
            MetricCard(
                metric: .cpu,
                detail: "İşlemci yükü ve çalışma durumu",
                value: "\(snapshot.cpuUsage)%",
                status: snapshot.cpuUsage >= 70 ? "Yoğun" : "Normal",
                progress: Double(snapshot.cpuUsage) / 100
            )
        case .memory:
            MetricCard(
                metric: .memory,
                detail: "Kullanılan RAM kapasitesi",
                value: "\(snapshot.memoryUsedGB) / 16 GB",
                status: "%\(snapshot.memoryUsage)",
                progress: Double(snapshot.memoryUsage) / 100
            )
        case .disk:
            MetricCard(
                metric: .disk,
                detail: "Dahili depolama kullanımı",
                value: "\(snapshot.diskUsedGB) / 512 GB",
                status: "%\(snapshot.diskUsage)",
                progress: Double(snapshot.diskUsage) / 100
            )
        case .battery:
            MetricCard(
                metric: .battery,
                detail: "Doluluk, sıcaklık ve güç durumu",
                value: "%\(snapshot.batteryLevel) · \(snapshot.batteryTemperature)°C",
                status: snapshot.batteryStatus,
                progress: Double(snapshot.batteryLevel) / 100
            )
        case .network:
            MetricCard(
                metric: .network,
                detail: "Anlık indirme ve yükleme hızı",
                value: "↓ \(formattedRate(snapshot.downloadRate)) MB/sn",
                status: "↑ \(formattedRate(snapshot.uploadRate)) MB/sn",
                progress: min(snapshot.downloadRate / 30, 1)
            )
        }
    }

    private func batteryStatus(for level: Int) -> String {
        switch level {
        case 65...:
            "Normal"
        case 35...:
            "Düşüyor"
        default:
            "Düşük güç"
        }
    }

    private func formattedRate(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
