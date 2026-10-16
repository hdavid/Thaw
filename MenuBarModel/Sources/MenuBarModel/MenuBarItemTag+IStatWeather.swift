//
//  MenuBarItemTag+IStatWeather.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import Foundation

extension MenuBarItemTag {
    /// iStat 7.3 weather reads "Currently 13° and Clear. High of 21°. …", with no "Module: " prefix.
    /// Keeps the text through the first reading, so the localized sky condition cannot churn identity.
    /// Requires a sentence break, so sensor lists such as "CPU #° GPU #°" keep their identities.
    /// Returns the masked title unchanged when it is not a weather sentence.
    static func leadingTemperatureSentence(_ masked: String) -> String {
        guard masked.contains(". "),
              let reading = masked.firstMatch(of: /#°[CF]?/),
              reading.range.upperBound < masked.endIndex,
              masked[reading.range.upperBound...].contains(where: \.isLetter)
        else { return masked }
        return String(masked[..<reading.range.upperBound])
    }
}
