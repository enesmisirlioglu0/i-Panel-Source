//
//  ContentView.swift
//  i-Panel
//

import SwiftUI

private enum MetricCardLayout {
    static let height: CGFloat = 74
    static let spacing: CGFloat = 6
    static let slotHeight: CGFloat = height + spacing
}

struct ContentView: View {
    let onOpenSettings: () -> Void

    @EnvironmentObject private var panelState: PanelState
    @State private var dragOffset = CGSize.zero

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            VStack(spacing: MetricCardLayout.spacing) {
                ForEach(panelState.orderedMetrics) { metric in
                    metricCard(metric)
                }
            }
            .padding(.vertical, 2)
            .frame(height: 398)

            footer
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(panelGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
        .padding(8)
        .frame(width: PanelLayout.width, height: PanelLayout.height)
        .onDisappear {
            dragOffset = .zero
            panelState.finishDragging()
        }
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
        HStack(alignment: .center, spacing: 10) {
            PanelMark(width: 22)
                .frame(width: 36, height: 36)
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
        .padding(.bottom, 7)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.62))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func metricCard(_ metric: MetricCard) -> some View {
        let isBeingDragged = panelState.draggedMetric == metric.metric
        let isDropTarget = panelState.dragDestinationMetric == metric.metric && !isBeingDragged

        MetricCardView(
            metric: metric,
            isBeingDragged: isBeingDragged,
            isDropTarget: isDropTarget
        )
        .offset(y: isBeingDragged ? dragOffset.height : 0)
        .scaleEffect(isBeingDragged ? 1.015 : 1)
        .zIndex(isBeingDragged ? 1 : 0)
        .highPriorityGesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    if panelState.draggedMetric != metric.metric {
                        dragOffset = .zero
                    }

                    dragOffset = value.translation
                    panelState.updateMetricDrag(
                        metric.metric,
                        verticalTranslation: value.translation.height,
                        slotHeight: MetricCardLayout.slotHeight
                    )
                }
                .onEnded { value in
                    panelState.endMetricDrag(
                        metric.metric,
                        verticalTranslation: value.translation.height,
                        slotHeight: MetricCardLayout.slotHeight
                    )

                    withAnimation(.easeOut(duration: 0.16)) {
                        dragOffset = .zero
                    }
                }
        )
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Spacer()

            footerActionButton("Ayar", systemImage: "gearshape", action: onOpenSettings)
            footerActionButton("Sıfırla", systemImage: "arrow.counterclockwise") {
                panelState.resetMetricOrder()
            }
        }
    }

    private func footerActionButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(markPetrol)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.white.opacity(0.78), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.95), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView(onOpenSettings: {})
        .environmentObject(PanelState())
}
