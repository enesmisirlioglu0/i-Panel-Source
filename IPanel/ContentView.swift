//
//  ContentView.swift
//  IPanel
//
//  Created by ENES MISIRLIOĞLU on 28.08.2026.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var panelState: PanelState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Divider()

            controls

            Divider()

            footer
        }
        .padding(16)
        .frame(width: 320)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: panelState.statusSymbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("i-Panel")
                    .font(.headline)

                Text(panelState.statusTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: panelState.refresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Panel durumunu yenile")
            .help("Panel durumunu yenile")
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hızlı kontroller")
                .font(.subheadline.weight(.semibold))

            Toggle(isOn: $panelState.isFocusModeEnabled) {
                Label("Odak modu", systemImage: "moon.fill")
            }

            Toggle(isOn: $panelState.isLowPowerModeEnabled) {
                Label("Tasarruf modu", systemImage: "battery.50")
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Panel seviyesi", systemImage: "sun.max.fill")
                    Spacer()
                    Text("\(Int(panelState.panelLevel * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(value: $panelState.panelLevel, in: 0 ... 1)
                    .accessibilityLabel("Panel seviyesi")
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("İlk iskelet: bu kontroller şu an yalnızca i-Panel içindeki önizleme durumunu değiştirir.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button("i-Panel’i Kapat") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.link)

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text("Son yenileme")
                    Text(panelState.lastUpdated.formatted(date: .omitted, time: .shortened))
                        .monospacedDigit()
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PanelState())
}
