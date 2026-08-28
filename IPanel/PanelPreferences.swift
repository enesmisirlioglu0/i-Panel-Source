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

@MainActor
final class PanelPreferences: ObservableObject {
    private enum Key {
        static let showsDockIcon = "showsDockIcon"
    }

    @Published var showsDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(showsDockIcon, forKey: Key.showsDockIcon)
            applyDockIconVisibility()
        }
    }

    @Published private(set) var launchAtLoginState: LaunchAtLoginState
    @Published private(set) var launchAtLoginError: String?
    @Published private(set) var dockIconError: String?

    private let launchService = SMAppService.mainApp

    init() {
        showsDockIcon = UserDefaults.standard.object(forKey: Key.showsDockIcon) as? Bool ?? false
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
        let policy: NSApplication.ActivationPolicy = showsDockIcon ? .regular : .accessory
        let didApply = NSApplication.shared.setActivationPolicy(policy)

        dockIconError = didApply ? nil : "Dock simgesi tercihi şu anda uygulanamadı."
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
