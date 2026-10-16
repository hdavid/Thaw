//
//  IStatWeatherTitleTests.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import Foundation
@testable import MenuBarModel
import Testing

/// iStat 7.3 weather titles carry the sky condition, which must not churn the saved layout.
@Suite("iStat weather titles")
struct IStatWeatherTitleTests {
    /// iStat Menus 7.3 publishes weather as one sentence with no "Module: " prefix,
    /// so masking digits alone left the sky condition in the identity.
    @Test(
        "iStat weather keeps one identity as the sky changes",
        arguments: [
            "Currently 13° and Clear. High of 21°. Low of 13°. 83% chance of rain",
            "Currently 9° and Cloudy. High of 12°. Low of 6°. 40% chance of rain",
            "Currently -2° and Light rain. High of 4°. Low of -3°. 100% chance of rain",
            "Currently 15°C and Overcast. High of 18°C. Low of 11°C. 5% chance of rain",
        ]
    )
    func iStatWeatherSharesIdentity(_ title: String) {
        let bundle = MenuBarItemTag.iStatMenusStatusBundleID
        let tag = MenuBarItemTag(namespace: .string(bundle), title: title)
        let expected = title.contains("°C") ? "\(bundle):Currently #°C" : "\(bundle):Currently #°"
        #expect(tag.tagIdentifier == expected)
        #expect(MenuBarItemTag.canonicalPersistentIdentifier("\(bundle):\(title)") == expected)
    }

    @Test("Saved iStat weather aliases from earlier builds collapse to one entry")
    func savedIStatWeatherAliasesCollapse() {
        let bundle = MenuBarItemTag.iStatMenusStatusBundleID
        let saved = ["Clear", "Cloudy", "Light rain", "Overcast", "Rain"].map {
            "\(bundle):Currently #° and \($0). High of #°. Low of #°. #% chance of rain"
        }
        #expect(MenuBarItemTag.canonicalPersistentIdentifiers(saved) == ["\(bundle):Currently #°"])
    }

    @Test(
        "Temperature sensors without a sentence keep their identities",
        arguments: [
            ("CPU 45°", "CPU #°"),
            ("CPU 45° GPU 50°", "CPU #° GPU #°"),
            ("13°", "#°"),
        ]
    )
    func iStatSensorTitlesUnchanged(_ raw: String, _ expected: String) {
        #expect(MenuBarItemTag.canonicalIStatMetricTitle(raw) == expected)
    }

    @Test("The weather rule is idempotent")
    func iStatWeatherRuleIsIdempotent() {
        let once = MenuBarItemTag.canonicalIStatMetricTitle(
            "Currently 13° and Clear. High of 21°. Low of 13°. 83% chance of rain"
        )
        #expect(MenuBarItemTag.canonicalIStatMetricTitle(once) == once)
    }
}
