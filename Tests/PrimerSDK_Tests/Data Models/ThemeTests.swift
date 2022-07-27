//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class PrimerThemeTests: XCTestCase {
    
    let data: PrimerThemeData = PrimerThemeData()
    
    func test_color_swatch_default_correctly() throws {
        let swatch = data.colors
        XCTAssert(swatch.primary == PrimerColors.blue)
        XCTAssert(swatch.light == PrimerColors.white)
        XCTAssert(swatch.dark == PrimerColors.black)
        XCTAssert(swatch.error == PrimerColors.red)
        XCTAssert(swatch.gray == PrimerColors.gray)
        XCTAssert(swatch.lightGray == PrimerColors.lightGray)
    }
    
    func test_dimensions_default_correctly() throws {
        let dimensions = data.dimensions
        XCTAssert(dimensions.safeArea == PrimerDimensions.safeArea)
        XCTAssert(dimensions.cornerRadius == PrimerDimensions.cornerRadius)
    }
    
    func test_view_theme_defaults_correctly() throws {
        let theme = data.view.theme(for: .main, with: data)
        XCTAssert(theme.safeMargin == PrimerDimensions.safeArea)
        XCTAssert(theme.cornerRadius == PrimerDimensions.cornerRadius)
        XCTAssert(theme.backgroundColor == data.colors.light)
    }
    
    func test_main_button_theme_defaults_correctly() throws {
        let theme = data.buttons.theme(for: .main, with: data)
        XCTAssert(theme.color(for: .enabled) == data.colors.primary)
        XCTAssert(theme.border.color(for: .enabled) == data.colors.primary)
        XCTAssert(theme.text.color == data.colors.light)
        XCTAssert(theme.iconColor == data.colors.light)
    }
    
    func test_payment_method_button_theme_defaults_correctly() throws {
        let theme = data.buttons.theme(for: .paymentMethod, with: data)
        XCTAssert(theme.color(for: .enabled) == data.colors.light)
        XCTAssert(theme.border.color(for: .enabled) == data.colors.dark)
        XCTAssert(theme.text.color == data.colors.dark)
        XCTAssert(theme.iconColor == data.colors.dark)
    }
    
    func test_input_theme_defaults_correctly() throws {
        let theme = data.input.theme(with: data)
        XCTAssert(theme.color == data.colors.light)
        XCTAssert(theme.border.color(for: .enabled) == data.colors.dark)
        XCTAssert(theme.text.color == data.colors.dark)
    }
    
    func test_body_text_theme_defaults_correctly() throws {
        let theme = data.text.theme(for: .body, with: data)
        XCTAssert(theme.color == data.colors.dark)
        XCTAssert(theme.fontSize == Int(PrimerDimensions.Font.body))
    }
    
    func test_title_text_theme_defaults_correctly() throws {
        let theme = data.text.theme(for: .title, with: data)
        XCTAssert(theme.color == data.colors.dark)
        XCTAssert(theme.fontSize == Int(PrimerDimensions.Font.title))
    }
    
    func test_subtitle_text_theme_defaults_correctly() throws {
        let theme = data.text.theme(for: .subtitle, with: data)
        XCTAssert(theme.color == data.colors.gray)
        XCTAssert(theme.fontSize == Int(PrimerDimensions.Font.subtitle))
    }
    
    func test_amount_label_text_theme_defaults_correctly() throws {
        let theme = data.text.theme(for: .amountLabel, with: data)
        XCTAssert(theme.color == data.colors.dark)
        XCTAssert(theme.fontSize == Int(PrimerDimensions.Font.amountLabel))
    }
    
    func test_system_text_theme_defaults_correctly() throws {
        let theme = data.text.theme(for: .system, with: data)
        XCTAssert(theme.color == data.colors.primary)
        XCTAssert(theme.fontSize == Int(PrimerDimensions.Font.system))
    }
    
    func test_error_text_theme_defaults_correctly() throws {
        let theme = data.text.theme(for: .error, with: data)
        XCTAssert(theme.color == data.colors.error)
        XCTAssert(theme.fontSize == Int(PrimerDimensions.Font.error))
    }
}


#endif

