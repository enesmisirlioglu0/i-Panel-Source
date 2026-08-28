//
//  PanelState.swift
//  i-Panel
//
//  Local-only state for the first menu-bar prototype.
//

import Combine
import Foundation

@MainActor
final class PanelState: ObservableObject {
    @Published var isFocusModeEnabled = false {
        didSet { refresh() }
    }

    @Published var isLowPowerModeEnabled = false {
        didSet { refresh() }
    }

    @Published var panelLevel = 0.65 {
        didSet { refresh() }
    }

    @Published private(set) var lastUpdated = Date()

    var statusTitle: String {
        switch (isFocusModeEnabled, isLowPowerModeEnabled) {
        case (true, true):
            return "Odak ve tasarruf açık"
        case (true, false):
            return "Odak modu açık"
        case (false, true):
            return "Tasarruf modu açık"
        case (false, false):
            return "Hazır"
        }
    }

    var statusSymbol: String {
        switch (isFocusModeEnabled, isLowPowerModeEnabled) {
        case (true, true):
            return "slider.horizontal.3"
        case (true, false):
            return "moon.circle.fill"
        case (false, true):
            return "battery.50"
        case (false, false):
            return "rectangle.3.group.fill"
        }
    }

    func refresh() {
        lastUpdated = Date()
    }
}
