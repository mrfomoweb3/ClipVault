import SwiftUI

// MARK: - DuckPak-inspired palette
//
// Warm off-white canvas, near-black brown ink, chunky yellow accents,
// a playful purple selection, and thin black outlines.
extension Color {
    /// #F7F4EF — warm off-white canvas
    static let cvBackground   = Color(red: 0.969, green: 0.957, blue: 0.937)
    /// #FFFFFF — cards, search field
    static let cvSurface      = Color(red: 1.000, green: 1.000, blue: 1.000)
    /// #F0EBE2 — hover wash
    static let cvHover        = Color(red: 0.941, green: 0.922, blue: 0.886)
    /// #5B4DE0 — playful purple selection
    static let cvSelected     = Color(red: 0.357, green: 0.302, blue: 0.878)
    /// #231F1C — near-black outline / ink
    static let cvBorder       = Color(red: 0.137, green: 0.122, blue: 0.110)
    /// #231F1C — primary text
    static let cvText         = Color(red: 0.137, green: 0.122, blue: 0.110)
    /// #8A8078 — muted secondary text
    static let cvTextSecond   = Color(red: 0.541, green: 0.502, blue: 0.471)
    /// #FFC72C — signature yellow
    static let cvPin          = Color(red: 1.000, green: 0.780, blue: 0.173)
    /// #EAE4DA — hairline dividers
    static let cvDivider      = Color(red: 0.918, green: 0.894, blue: 0.855)
    /// #FFFFFF — search field background
    static let cvSearchBg     = Color(red: 1.000, green: 1.000, blue: 1.000)

    // Brand accents
    /// #FFC72C — CTA yellow
    static let cvYellow       = Color(red: 1.000, green: 0.780, blue: 0.173)
    /// #F26B21 — brand orange
    static let cvOrange       = Color(red: 0.949, green: 0.420, blue: 0.129)
    /// #5B4DE0 — brand purple
    static let cvPurple       = Color(red: 0.357, green: 0.302, blue: 0.878)
}
