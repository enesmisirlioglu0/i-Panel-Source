//
//  ContentView.swift
//  i-Panel
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    let onOpenSettings: () -> Void

    @EnvironmentObject private var panelState: PanelState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(panelState.orderedMetrics) { metric in
                        metricCard(metric)
                    }
                }
                .padding(.vertical, 2)
            }

            footer
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(panelGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
        .padding(10)
        .frame(width: 450, height: 660)
    }

    private var panelGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.76, green: 0.96, blue: 0.93).opacity(0.86),
                Color(red: 0.34, green: 0.79, blue: 0.74).opacity(0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var markPetrol: Color {
        Color(red: 0.07, green: 0.22, blue: 0.30)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            PanelMark(width: 25)
                .frame(width: 40, height: 40)
                .background(markPetrol, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.36), lineWidth: 1)
                }

            Text("i-Panel")
                .font(.title3.weight(.bold))

            Spacer()

            Button(action: panelState.refreshSimulation) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Simülasyon verilerini yenile")
            .help("Simülasyon verilerini yenile")

        }
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.62))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func metricCard(_ metric: MetricCard) -> some View {
        let card = MetricCardView(
            metric: metric,
            isBeingDragged: panelState.draggedMetric == metric.metric
        )

        card
            .onDrag {
                panelState.beginDragging(metric.metric)
                return NSItemProvider(object: metric.metric.rawValue as NSString)
            }
            .onDrop(
                of: [UTType.plainText],
                delegate: MetricDropDelegate(destination: metric.metric, panelState: panelState)
            )
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Spacer()

            Button("Ayar", action: onOpenSettings)
            .buttonStyle(.link)

            Button("Sıfırla") {
                panelState.resetMetricOrder()
            }
            .buttonStyle(.link)
        }
        .font(.caption)
    }
}

private struct MetricDropDelegate: DropDelegate {
    let destination: PanelMetric
    let panelState: PanelState

    func dropEntered(info: DropInfo) {
        panelState.moveDraggedMetric(to: destination)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        panelState.finishDragging()
        return true
    }
}

#Preview {
    ContentView(onOpenSettings: {})
        .environmentObject(PanelState())
}
