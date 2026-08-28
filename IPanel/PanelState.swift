//
//  PanelState.swift
//  i-Panel
//
//  Shows public, local macOS system statistics without sending them anywhere.
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
    let progress: Double?

    var id: PanelMetric { metric }
}

@MainActor
final class PanelState: ObservableObject {
    private enum StorageKey {
        static let metricOrder = "metricOrder"
    }

    @Published private(set) var metricOrder = PanelMetric.allCases
    @Published private(set) var draggedMetric: PanelMetric?
    @Published private(set) var dragDestinationMetric: PanelMetric?

    @Published private var snapshot = SystemMetricsSnapshot(
        cpuUsage: nil,
        memory: nil,
        disk: nil,
        battery: .unavailable,
        network: nil
    )
    private var metricsProvider = SystemMetricsProvider()
    private var refreshTimer: AnyCancellable?
    private var remembersMetricOrder: Bool
    private var refreshInterval: TimeInterval
    private var dragOriginIndex: Int?

    init(
        remembersMetricOrder: Bool = true,
        refreshInterval: TimeInterval = PanelRefreshInterval.threeSeconds.rawValue
    ) {
        self.remembersMetricOrder = remembersMetricOrder
        self.refreshInterval = refreshInterval
        metricOrder = remembersMetricOrder ? Self.restoredMetricOrder() : PanelMetric.allCases

        refreshMetrics()
        configureRefreshTimer()
    }

    func setRemembersMetricOrder(_ enabled: Bool) {
        guard remembersMetricOrder != enabled else {
            return
        }

        remembersMetricOrder = enabled

        if enabled {
            persistMetricOrder()
        } else {
            UserDefaults.standard.removeObject(forKey: StorageKey.metricOrder)
            resetMetricOrder()
        }
    }

    func setRefreshInterval(_ interval: TimeInterval) {
        guard refreshInterval != interval else {
            return
        }

        refreshInterval = interval
        configureRefreshTimer()
    }

    private func configureRefreshTimer() {
        refreshTimer?.cancel()

        refreshTimer = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshMetrics()
                }
            }
    }

    var orderedMetrics: [MetricCard] {
        metricOrder.map(metricCard(for:))
    }

    func refreshMetrics() {
        snapshot = metricsProvider.sample()
    }

    func resetMetricOrder() {
        let defaultOrder = PanelMetric.allCases

        guard metricOrder != defaultOrder else {
            finishDragging()
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            metricOrder = defaultOrder
        }
        persistMetricOrder()
        finishDragging()
    }

    func beginDragging(_ metric: PanelMetric) {
        draggedMetric = metric
        dragOriginIndex = metricOrder.firstIndex(of: metric)
        dragDestinationMetric = metric
    }

    func updateMetricDrag(
        _ metric: PanelMetric,
        verticalTranslation: CGFloat,
        slotHeight: CGFloat
    ) {
        if draggedMetric != metric {
            beginDragging(metric)
        }

        guard let dragOriginIndex,
              slotHeight > 0 else {
            return
        }

        let slotDelta = Int((verticalTranslation / slotHeight).rounded())
        let destinationIndex = min(
            max(dragOriginIndex + slotDelta, 0),
            metricOrder.count - 1
        )
        dragDestinationMetric = metricOrder[destinationIndex]
    }

    func endMetricDrag(
        _ metric: PanelMetric,
        verticalTranslation: CGFloat,
        slotHeight: CGFloat
    ) {
        updateMetricDrag(
            metric,
            verticalTranslation: verticalTranslation,
            slotHeight: slotHeight
        )

        guard draggedMetric == metric,
              let destinationMetric = dragDestinationMetric,
              let destinationIndex = metricOrder.firstIndex(of: destinationMetric) else {
            finishDragging()
            return
        }

        moveDraggedMetric(toIndex: destinationIndex)
        finishDragging()
    }

    func finishDragging() {
        draggedMetric = nil
        dragDestinationMetric = nil
        dragOriginIndex = nil
    }

    private func moveDraggedMetric(toIndex destinationIndex: Int) {
        guard let draggedMetric,
              let sourceIndex = metricOrder.firstIndex(of: draggedMetric) else {
            return
        }

        let insertionIndex = min(
            max(destinationIndex, 0),
            metricOrder.count - 1
        )

        guard sourceIndex != insertionIndex else {
            return
        }

        var reorderedMetrics = metricOrder
        reorderedMetrics.remove(at: sourceIndex)

        reorderedMetrics.insert(draggedMetric, at: insertionIndex)

        withAnimation(.easeInOut(duration: 0.2)) {
            metricOrder = reorderedMetrics
        }
        persistMetricOrder()
    }

    private func persistMetricOrder() {
        guard remembersMetricOrder else {
            return
        }

        UserDefaults.standard.set(metricOrder.map { $0.rawValue }, forKey: StorageKey.metricOrder)
    }

    private static func restoredMetricOrder() -> [PanelMetric] {
        guard let storedOrder = UserDefaults.standard.stringArray(forKey: StorageKey.metricOrder) else {
            return PanelMetric.allCases
        }

        let restoredOrder = storedOrder.compactMap(PanelMetric.init(rawValue:))
        guard restoredOrder.count == PanelMetric.allCases.count,
              Set(restoredOrder).count == PanelMetric.allCases.count else {
            return PanelMetric.allCases
        }

        return restoredOrder
    }

    private func metricCard(for metric: PanelMetric) -> MetricCard {
        switch metric {
        case .cpu:
            guard let usage = snapshot.cpuUsage else {
                return MetricCard(
                    metric: .cpu,
                    detail: "Anlık toplam işlemci kullanımı",
                    value: "Ölçülüyor…",
                    status: "İlk ölçüm",
                    progress: nil
                )
            }

            return MetricCard(
                metric: .cpu,
                detail: "Anlık toplam işlemci kullanımı",
                value: "%\(percentage(usage))",
                status: usage >= 0.70 ? "Yoğun" : "Normal",
                progress: usage
            )
        case .memory:
            guard let memory = snapshot.memory else {
                return unavailableMetricCard(
                    metric: .memory,
                    detail: "Kullanılan RAM kapasitesi"
                )
            }

            return MetricCard(
                metric: .memory,
                detail: "Kullanılan RAM kapasitesi",
                value: "\(formattedCapacity(memory.usedBytes)) / \(formattedCapacity(memory.totalBytes))",
                status: "%\(percentage(memory.usageFraction))",
                progress: memory.usageFraction
            )
        case .disk:
            guard let disk = snapshot.disk else {
                return unavailableMetricCard(
                    metric: .disk,
                    detail: "Başlangıç diski kullanımı"
                )
            }

            return MetricCard(
                metric: .disk,
                detail: "Başlangıç diski kullanımı",
                value: "\(formattedCapacity(disk.usedBytes)) / \(formattedCapacity(disk.totalBytes))",
                status: "%\(percentage(disk.usageFraction))",
                progress: disk.usageFraction
            )
        case .battery:
            return batteryMetricCard
        case .network:
            guard let network = snapshot.network else {
                return MetricCard(
                    metric: .network,
                    detail: "Mac toplam indirme ve yükleme hızı",
                    value: "Ölçülüyor…",
                    status: "İlk ölçüm",
                    progress: nil
                )
            }

            return MetricCard(
                metric: .network,
                detail: "Mac toplam indirme ve yükleme hızı",
                value: "↓ \(formattedRate(network.downloadBytesPerSecond))",
                status: "↑ \(formattedRate(network.uploadBytesPerSecond))",
                progress: min(network.downloadBytesPerSecond / 10_000_000, 1)
            )
        }
    }

    private var batteryMetricCard: MetricCard {
        switch snapshot.battery {
        case .available(let battery):
            return MetricCard(
                metric: .battery,
                detail: "Doluluk ve güç durumu",
                value: "%\(percentage(battery.level))",
                status: battery.status,
                progress: battery.level
            )
        case .notPresent:
            return MetricCard(
                metric: .battery,
                detail: "Doluluk ve güç durumu",
                value: "—",
                status: "Batarya yok",
                progress: nil
            )
        case .unavailable:
            return unavailableMetricCard(
                metric: .battery,
                detail: "Doluluk ve güç durumu"
            )
        }
    }

    private func unavailableMetricCard(metric: PanelMetric, detail: String) -> MetricCard {
        MetricCard(
            metric: metric,
            detail: detail,
            value: "—",
            status: "Veri alınamadı",
            progress: nil
        )
    }

    private func percentage(_ fraction: Double) -> Int {
        Int((min(max(fraction, 0), 1) * 100).rounded())
    }

    private func formattedCapacity(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true

        return formatter.string(fromByteCount: max(bytes, 0))
    }

    private func formattedRate(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true

        return "\(formatter.string(fromByteCount: Int64(max(bytesPerSecond, 0))))/sn"
    }
}
