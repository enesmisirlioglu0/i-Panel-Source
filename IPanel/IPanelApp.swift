//
//  IPanelApp.swift
//  IPanel
//
//  Created by ENES MISIRLIOĞLU on 28.08.2026.
//

import SwiftUI

@main
struct IPanelApp: App {
    @StateObject private var panelState = PanelState()

    var body: some Scene {
        MenuBarExtra("i-Panel", systemImage: panelState.statusSymbol) {
            ContentView()
                .environmentObject(panelState)
        }
        .menuBarExtraStyle(.window)
    }
}
