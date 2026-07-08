import SwiftUI

// MARK: - DuckPak-inspired type system
//
// Fredoka — the funky rounded display face for headings & the wordmark.
// Poppins — the clean geometric sans for body, labels, and UI chrome.
// Fonts are bundled in ClipVault/Fonts and registered via
// ATSApplicationFontsPath. Referenced by PostScript name for reliability.
extension Font {

    // MARK: Display (Fredoka)

    /// Big, bold, groovy — hero headings and the wordmark.
    static func cvDisplay(_ size: CGFloat) -> Font {
        .custom("Fredoka-Bold", fixedSize: size)
    }

    /// Slightly lighter display weight for subheads.
    static func cvDisplaySemi(_ size: CGFloat) -> Font {
        .custom("Fredoka-SemiBold", fixedSize: size)
    }

    // MARK: Body (Poppins)

    static func cvBody(_ size: CGFloat) -> Font {
        .custom("Poppins-Regular", fixedSize: size)
    }

    static func cvBodyMedium(_ size: CGFloat) -> Font {
        .custom("Poppins-Medium", fixedSize: size)
    }

    static func cvBodySemibold(_ size: CGFloat) -> Font {
        .custom("Poppins-SemiBold", fixedSize: size)
    }

    static func cvBodyBold(_ size: CGFloat) -> Font {
        .custom("Poppins-Bold", fixedSize: size)
    }
}
