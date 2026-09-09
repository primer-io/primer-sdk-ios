//
//  ThemeDemos.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// The theming catalog: each entry applies a different `PrimerCheckoutTheme` to the managed checkout,
/// rendered via ``ThemedManagedDemo``. Registered in bulk by ``DemoRegistry``.
@available(iOS 15.0, *)
enum ThemeDemos {
    static let entries: [(metadata: DemoMetadata, theme: PrimerCheckoutTheme)] = [
        (meta(.customTheme, "Custom Theme", "Purple brand, rounded corners, custom type"), customTheme),
        (meta(.redTheme, "Red Theme", "Brand color override"), brandTheme(0xE53E3E)),
        (meta(.greenTheme, "Green Theme", "Brand color override"), brandTheme(0x38A169)),
        (meta(.purpleTheme, "Purple Theme", "Brand color override"), brandTheme(0x805AD5)),
        (meta(.noRadiusTheme, "No Radius", "Sharp rectangular design via radius tokens"), noRadiusTheme),
        (meta(.smallSizesTheme, "Small Sizes", "Compact components via size tokens"), smallSizesTheme),
        (meta(.largeSizesTheme, "Large Sizes", "Bold components via size tokens"), largeSizesTheme),
        (meta(.lightTypographyTheme, "Light Typography", "Weight-300 typography"), typographyTheme(.init(weight: .light))),
        (meta(.boldTypographyTheme, "Bold Typography", "Weight-700 typography"), typographyTheme(.init(weight: .bold))),
        (meta(.largeTypographyTheme, "Large Typography", "32-point typography for accessibility"), typographyTheme(.init(size: 32))),
        (meta(.customFontTheme, "Custom Font", "Custom font via typography tokens"), typographyTheme(.init(font: "Marker Felt")))
    ]

    private static func meta(_ key: DemoKey, _ name: String, _ description: String) -> DemoMetadata {
        DemoMetadata(key: key, name: name, description: description, tags: ["THEME"], isCustom: false, category: .themes)
    }

    private static func brandTheme(_ hex: UInt32) -> PrimerCheckoutTheme {
        PrimerCheckoutTheme(
            colors: ColorOverrides(
                primerColorBrand: Color(hex: hex),
                primerColorBorderOutlinedDefault: Color(hex: hex),
                primerColorBorderOutlinedFocus: Color(hex: hex)
            )
        )
    }

    /// Applies the same `TypographyStyle` to every text token — the shape shared by the weight, size,
    /// and font demos.
    private static func typographyTheme(_ style: TypographyOverrides.TypographyStyle) -> PrimerCheckoutTheme {
        PrimerCheckoutTheme(
            typography: TypographyOverrides(
                titleXlarge: style,
                titleLarge: style,
                bodyLarge: style,
                bodyMedium: style,
                bodySmall: style
            )
        )
    }

    private static let customTheme = PrimerCheckoutTheme(
        colors: ColorOverrides(
            primerColorBrand: Color(hex: 0x6B46C1),
            primerColorBorderOutlinedDefault: Color(hex: 0xD6BCFA),
            primerColorBorderOutlinedFocus: Color(hex: 0x6B46C1)
        ),
        radius: RadiusOverrides(
            primerRadiusXsmall: 8, primerRadiusSmall: 12, primerRadiusMedium: 16,
            primerRadiusLarge: 24, primerRadiusBase: 12
        ),
        typography: TypographyOverrides(
            titleXlarge: .init(weight: .semibold),
            titleLarge: .init(weight: .semibold),
            bodyLarge: .init(weight: .regular),
            bodyMedium: .init(weight: .regular),
            bodySmall: .init(weight: .regular)
        )
    )

    private static let noRadiusTheme = PrimerCheckoutTheme(
        radius: RadiusOverrides(
            primerRadiusXsmall: 0, primerRadiusSmall: 0, primerRadiusMedium: 0,
            primerRadiusLarge: 0, primerRadiusBase: 0
        )
    )

    private static let smallSizesTheme = PrimerCheckoutTheme(
        sizes: SizeOverrides(
            primerSizeSmall: 12, primerSizeMedium: 16, primerSizeLarge: 18,
            primerSizeXlarge: 22, primerSizeXxlarge: 28, primerSizeXxxlarge: 34
        )
    )

    private static let largeSizesTheme = PrimerCheckoutTheme(
        sizes: SizeOverrides(
            primerSizeSmall: 24, primerSizeMedium: 32, primerSizeLarge: 40,
            primerSizeXlarge: 48, primerSizeXxlarge: 64, primerSizeXxxlarge: 80
        )
    )
}
