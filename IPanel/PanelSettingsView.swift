//
//  PanelSettingsView.swift
//  i-Panel
//

import AppKit
import Combine
import SwiftUI

struct PanelSettingsView: View {
    @ObservedObject var preferences: PanelPreferences
    @ObservedObject var panelState: PanelState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("i-Panel Ayarları")
                .font(.title2.weight(.bold))

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Girişte i-Panel’i aç", isOn: launchAtLoginBinding)

                    launchAtLoginDetail
                }
                .padding(.top, 2)
            } label: {
                Label("Başlangıç", systemImage: "power")
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Dock simgesini göster", isOn: $preferences.showsDockIcon)

                    Text("Açık olduğunda i-Panel, Dock'ta ve Uygulama Değiştirici'de görünür.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let dockIconError = preferences.dockIconError {
                        Label(dockIconError, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.top, 2)
            } label: {
                Label("Görünüm", systemImage: "dock.rectangle")
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Kart sırasını hatırla", isOn: remembersMetricOrderBinding)

                    Picker("Yenileme sıklığı", selection: refreshIntervalBinding) {
                        ForEach(PanelRefreshInterval.allCases) { interval in
                            Text(interval.title).tag(interval)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.top, 2)
            } label: {
                Label("Panel", systemImage: "slider.horizontal.3")
            }
        }
        .padding(20)
        .frame(width: 390)
        .onAppear {
            preferences.refreshLaunchAtLoginStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            preferences.refreshLaunchAtLoginStatus()
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { preferences.isLaunchAtLoginEnabled },
            set: { preferences.setLaunchAtLogin($0) }
        )
    }

    private var remembersMetricOrderBinding: Binding<Bool> {
        Binding(
            get: { preferences.remembersMetricOrder },
            set: { enabled in
                preferences.remembersMetricOrder = enabled
                panelState.setRemembersMetricOrder(enabled)
            }
        )
    }

    private var refreshIntervalBinding: Binding<PanelRefreshInterval> {
        Binding(
            get: { preferences.refreshInterval },
            set: { interval in
                preferences.refreshInterval = interval
                panelState.setRefreshInterval(interval.rawValue)
            }
        )
    }

    @ViewBuilder
    private var launchAtLoginDetail: some View {
        switch preferences.launchAtLoginState {
        case .enabled:
            Text("i-Panel, bir sonraki Mac girişinde otomatik açılacak.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .disabled:
            Text("Kapalı. Açtığınızda macOS, girişte çalışma kaydını oluşturur.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .requiresApproval:
            VStack(alignment: .leading, spacing: 6) {
                Label("macOS bu ayar için Sistem Ayarları'nda onay bekliyor.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)

                Button("Giriş Öğelerini Aç") {
                    preferences.openLoginItemsSettings()
                }
                .buttonStyle(.link)
            }
        case .unavailable:
            Label("Bu uygulama paketi girişte çalışma kaydı için uygun görünmüyor.", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)
        }

        if let launchAtLoginError = preferences.launchAtLoginError {
            Label(launchAtLoginError, systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    PanelSettingsView(preferences: PanelPreferences(), panelState: PanelState())
}
