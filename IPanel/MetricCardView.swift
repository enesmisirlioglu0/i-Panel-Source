//
//  MetricCardView.swift
//  i-Panel
//

import SwiftUI

struct MetricCardView: View {
    let metric: MetricCard
    let isBeingDragged: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: metric.metric.systemImage)
                    .font(.headline)
                    .foregroundStyle(metric.metric.tint)
                    .frame(width: 36, height: 36)
                    .background(metric.metric.tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading) {
                    Text(metric.metric.title)
                        .font(.headline)

                    Text(metric.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(metric.value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)

                    Text(metric.status)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(metric.metric.tint)
                }

                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            ProgressView(value: metric.progress)
                .tint(metric.metric.tint)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 84, maxHeight: 84)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isBeingDragged ? metric.metric.tint : .white.opacity(0.60),
                    lineWidth: isBeingDragged ? 2 : 1
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metric.metric.title), \(metric.value), \(metric.status)")
    }
}
