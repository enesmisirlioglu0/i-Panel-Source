//
//  PanelPreferences.swift
//  i-Panel
//

import AppKit
import Combine
import Foundation
import ServiceManagement

enum LaunchAtLoginState: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case unavailable
}

enum PanelRefreshInterval: Double, CaseIterable, Identifiable {
    case oneSecond = 1
    case threeSeconds = 3
    case fiveSeconds = 5

    var id: Double { rawValue }

    var title: String {
        switch self {
        case .oneSecond:
            "1 sn"
        case .threeSeconds:
            "3 sn"
        case .fiveSeconds:
            "5 sn"
        }
    }
}

@MainActor
final class PanelPreferences: ObservableObject {
    private enum Key {
        static let showsDockIcon = "showsDockIcon"
        static let remembersMetricOrder = "remembersMetricOrder"
        static let refreshInterval = "refreshInterval"
    }

    @Published var showsDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(showsDockIcon, forKey: Key.showsDockIcon)
            applyDockIconVisibility()
        }
    }

    @Published var remembersMetricOrder: Bool {
        didSet {
            UserDefaults.standard.set(remembersMetricOrder, forKey: Key.remembersMetricOrder)
        }
    }

    @Published var refreshInterval: PanelRefreshInterval {
        didSet {
            UserDefaults.standard.set(refreshInterval.rawValue, forKey: Key.refreshInterval)
        }
    }

    @Published private(set) var launchAtLoginState: LaunchAtLoginState
    @Published private(set) var launchAtLoginError: String?
    @Published private(set) var dockIconError: String?

    private let launchService = SMAppService.mainApp

    init() {
        showsDockIcon = UserDefaults.standard.object(forKey: Key.showsDockIcon) as? Bool ?? false
        remembersMetricOrder = UserDefaults.standard.object(forKey: Key.remembersMetricOrder) as? Bool ?? true
        refreshInterval = PanelRefreshInterval(
            rawValue: UserDefaults.standard.double(forKey: Key.refreshInterval)
        ) ?? .threeSeconds
        launchAtLoginState = Self.state(for: SMAppService.mainApp.status)
        launchAtLoginError = nil
        dockIconError = nil
    }

    var isLaunchAtLoginEnabled: Bool {
        launchAtLoginState == .enabled
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLoginState = Self.state(for: launchService.status)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                switch launchService.status {
                case .enabled:
                    break
                case .requiresApproval:
                    openLoginItemsSettings()
                case .notRegistered, .notFound:
                    try launchService.register()
                @unknown default:
                    try launchService.register()
                }
            } else {
                switch launchService.status {
                case .enabled, .requiresApproval:
                    try launchService.unregister()
                case .notRegistered, .notFound:
                    break
                @unknown default:
                    try launchService.unregister()
                }
            }

            launchAtLoginError = nil
        } catch {
            launchAtLoginError = "macOS girişte çalışma isteğini uygulayamadı. Uygulamanın geçerli bir imzaya sahip olduğundan ve Giriş Öğeleri'nde engellenmediğinden emin olun."
        }

        refreshLaunchAtLoginStatus()
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    func applyDockIconVisibility() {
        let didApply = Self.applyStoredDockIconVisibility()

        dockIconError = didApply ? nil : "Dock simgesi tercihi şu anda uygulanamadı."
    }

    @discardableResult
    static func applyStoredDockIconVisibility() -> Bool {
        let showsDockIcon = UserDefaults.standard.object(forKey: Key.showsDockIcon) as? Bool ?? false
        let policy: NSApplication.ActivationPolicy = showsDockIcon ? .regular : .accessory
        return NSApplication.shared.setActivationPolicy(policy)
    }

    private static func state(for status: SMAppService.Status) -> LaunchAtLoginState {
        switch status {
        case .enabled:
            .enabled
        case .notRegistered:
            .disabled
        case .requiresApproval:
            .requiresApproval
        case .notFound:
            .unavailable
        @unknown default:
            .unavailable
        }
    }
}
