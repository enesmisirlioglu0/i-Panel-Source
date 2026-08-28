//
//  MetricCardView.swift
//  i-Panel
//

import SwiftUI

struct MetricCardView: View {
    let metric: MetricCard
    let isBeingDragged: Bool
    let isDropTarget: Bool

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 8) {
                Image(systemName: metric.metric.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(metric.metric.tint)
                    .frame(width: 32, height: 32)
                    .background(metric.metric.tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(metric.metric.title)
                        .font(.subheadline.weight(.bold))

                    Text(metric.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }

                Spacer(minLength: 4)

                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 8) {
                Spacer(minLength: 0)

                Text(metric.value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(metric.status)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(metric.metric.tint)
                    .lineLimit(1)
            }

            if let progress = metric.progress {
                ProgressView(value: progress)
                    .tint(metric.metric.tint)
            } else {
                Color.clear
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isBeingDragged
                        ? metric.metric.tint
                        : isDropTarget
                            ? .cyan.opacity(0.95)
                            : .white.opacity(0.60),
                    lineWidth: isBeingDragged || isDropTarget ? 2 : 1
                )
        }
        .shadow(
            color: isDropTarget ? .cyan.opacity(0.24) : .clear,
            radius: isDropTarget ? 8 : 0
        )
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metric.metric.title), \(metric.value), \(metric.status)")
        .accessibilityHint("Yerini değiştirmek için kartı tutup yukarı veya aşağı sürükleyin.")
        .animation(.easeInOut(duration: 0.16), value: isBeingDragged)
        .animation(.easeInOut(duration: 0.16), value: isDropTarget)
    }
}
