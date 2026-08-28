//
//  IPanelApp.swift
//  i-Panel
//

import AppKit
import Combine
import SwiftUI

enum PanelLayout {
    static let width: CGFloat = 336
    static let height: CGFloat = 532
}

@main
struct IPanelApp: App {
    @NSApplicationDelegateAdaptor(IPanelApplicationDelegate.self) private var applicationDelegate
    @State private var isMenuBarExtraInserted = true
    @StateObject private var preferences: PanelPreferences
    @StateObject private var panelState: PanelState
    @StateObject private var settingsWindowController = PanelSettingsWindowController()

    init() {
        let preferences = PanelPreferences()

        _preferences = StateObject(wrappedValue: preferences)
        _panelState = StateObject(
            wrappedValue: PanelState(
                remembersMetricOrder: preferences.remembersMetricOrder,
                refreshInterval: preferences.refreshInterval.rawValue
            )
        )
    }

    var body: some Scene {
        MenuBarExtra(
            "i-Panel",
            systemImage: "rectangle.3.group.fill",
            isInserted: $isMenuBarExtraInserted
        ) {
            ContentView {
                settingsWindowController.show(
                    preferences: preferences,
                    panelState: panelState
                )
            }
            .environmentObject(panelState)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
private final class IPanelApplicationDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        PanelPreferences.applyStoredDockIconVisibility()
    }
}

@MainActor
private final class PanelSettingsWindowController: ObservableObject {
    private var windowController: NSWindowController?

    func show(preferences: PanelPreferences, panelState: PanelState) {
        if let settingsWindow = windowController?.window {
            settingsWindow.makeKeyAndOrderFront(nil)
        } else {
            let hostingController = NSHostingController(
                rootView: PanelSettingsView(
                    preferences: preferences,
                    panelState: panelState
                )
            )
            let settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow.title = "i-Panel Ayarları"
            settingsWindow.styleMask = [.titled, .closable]
            settingsWindow.isReleasedWhenClosed = false
            settingsWindow.center()

            let controller = NSWindowController(window: settingsWindow)
            windowController = controller
            controller.showWindow(self)
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
