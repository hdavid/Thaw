//
//  ControlItem+ContextMenuTrace.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import AppKit
import MenuBarModel

/// Logs how long the Thaw icon's menu stays open, to diagnose a menu that
/// closes as soon as it appears.
extension ControlItem {
    private static let contextMenuLog = DiagLog(category: "ControlItem.ContextMenu")

    /// Shows the menu from the status item's own right-mouse-up path.
    static func showMenuTraced(_ menu: NSMenu, statusItem: NSStatusItem) {
        let trigger = String(describing: NSApp.currentEvent?.type)
        contextMenuLog.info("ContextMenuTrace: status-item menu via \(trigger) active=\(NSApp.isActive)")
        statusItem.showMenu(menu)
    }

    /// Pops the menu up at a screen point; popUp returns when the menu closes,
    /// so a near-zero lifetime means something dismissed it.
    static func popUpTraced(_ menu: NSMenu, at point: CGPoint) {
        let openedAt = Date()
        contextMenuLog.info("ContextMenuTrace: popUp at \(point) active=\(NSApp.isActive)")
        menu.popUp(positioning: nil, at: point, in: nil)
        let lifetime = Date().timeIntervalSince(openedAt)
        let closer = String(describing: NSApp.currentEvent?.type)
        contextMenuLog.info("ContextMenuTrace: closed after \(lifetime)s, last event \(closer)")
    }
}
