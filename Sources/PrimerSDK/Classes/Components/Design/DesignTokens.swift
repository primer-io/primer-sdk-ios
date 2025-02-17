//
//  DesignTokens.swift
//
//
//  Created by Boris on 12.2.25..
//

import SwiftUI

/// The model representing the design tokens fetched from the API.
/// The keys should match the JSON returned by your API.
struct DesignTokens: Decodable {
    let primerColorGray100: String
    let primerColorGray200: String
    let primerColorBrand: String
    // Add additional tokens as needed.

    // Convenience computed properties to convert hex strings to SwiftUI Colors.
    var colorGray100: Color { Color(hex: primerColorGray100) }
    var colorGray200: Color { Color(hex: primerColorGray200) }
    var colorBrand: Color { Color(hex: primerColorBrand) }
}
