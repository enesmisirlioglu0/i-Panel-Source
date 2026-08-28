//
//  IPanelApp.swift
//  i-Panel
//

import AppKit
import SwiftUI

enum PanelLayout {
    static let width: CGFloat = 336
    static let height: CGFloat = 532
}

@main
@MainActor
final class IPanelAppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = PanelPreferences()
    private lazy var panelState = PanelState(
        remembersMetricOrder: preferences.remembersMetricOrder,
        refreshInterval: preferences.refreshInterval.rawValue
    )
    private let popover = NSPopover()

    private var statusItem: NSStatusItem?
    private var settingsWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        preferences.applyDockIconVisibility()
        configurePopover()
        configureStatusItem()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: PanelLayout.width, height: PanelLayout.height)
        popover.contentViewController = NSHostingController(
            rootView: ContentView(onOpenSettings: { [weak self] in
                self?.showSettings()
            })
            .environmentObject(panelState)
        )
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = PanelStatusImage.make()
        item.button?.imagePosition = .imageOnly
        item.button?.toolTip = "i-Panel"
        item.button?.target = self
        item.button?.action = #selector(togglePanel(_:))
        statusItem = item
    }

    @objc
    private func togglePanel(_ sender: Any?) {
        guard let button = statusItem?.button else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showSettings() {
        popover.performClose(nil)

        if let settingsWindow = settingsWindowController?.window {
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
            settingsWindowController = controller
            controller.showWindow(self)
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
