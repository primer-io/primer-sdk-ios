//
//  PrimerCheckoutTheme.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 2/2/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK
import UIKit

private let tropical1 = UIColor(red: 0/255, green: 112/255, blue: 67/255, alpha: 1)
private let tropical2 = UIColor(red: 255/255, green: 170/255, blue: 176/255, alpha: 1)
private let tropical3 = UIColor(red: 255/255, green: 208/255, blue: 131/255, alpha: 1)
private let tropical4 = UIColor(red: 188/255, green: 234/255, blue: 246/255, alpha: 1)
private let tropical5 = UIColor(red: 200/255, green: 98/255, blue: 24/255, alpha: 1)
private let tropical6 = UIColor(red: 3/255, green: 145/255, blue: 155/255, alpha: 1)
private let tropical7 = UIColor(red: 236/255, green: 80/255, blue: 100/255, alpha: 1)
private let tropical8 = UIColor(red: 10/255, green: 89/255, blue: 71/255, alpha: 1)
private let tropical9 = UIColor(red: 31/255, green: 130/255, blue: 118/255, alpha: 1)
private let tropical10 = UIColor(red: 230/255, green: 244/255, blue: 190/255, alpha: 1)

class PrimerCheckoutThemeTests: XCTestCase {

    static var tropical: PrimerTheme {
        let data = PrimerThemeData()
        data.colors.primary = tropical7
        data.colors.gray = tropical3
        data.colors.light = tropical10
        data.colors.error = tropical3
        data.blurView.backgroundColor = .darkGray
        data.view.backgroundColor = tropical1
        data.text.title = PrimerThemeData.Text(defaultColor: tropical10)
        data.text.amountLabel = PrimerThemeData.Text(defaultColor: tropical10)
        data.text.subtitle = PrimerThemeData.Text(defaultColor: tropical3)
        data.text.body = PrimerThemeData.Text(defaultColor: .white)
        data.text.system = PrimerThemeData.Text(defaultColor: tropical4)
        data.buttons.paymentMethod.border.defaultColor = tropical8
        data.buttons.paymentMethod.border.selectedColor = tropical8
        data.buttons.paymentMethod.text.defaultColor = tropical8
        data.buttons.paymentMethod.iconColor = tropical8
        data.buttons.main.defaultColor = tropical8
        data.buttons.main.selectedColor = tropical8
        data.buttons.main.text.defaultColor = tropical4
        data.buttons.main.disabledColor = tropical9
        data.input.border = PrimerThemeData.Border(defaultColor: tropical4, selectedColor: tropical4)
        data.input.text = PrimerThemeData.Text(defaultColor: tropical4)
        return PrimerTheme.init(with: data)
    }

    func test_custom_theme_exists() throws {
        let settings = PrimerSettings(uiOptions: PrimerUIOptions(theme: PrimerCheckoutThemeTests.tropical))
        Primer.shared.configure(settings: settings)

        let storedSettings: PrimerSettingsProtocol = DependencyContainer.resolve()
        XCTAssert(storedSettings.uiOptions.theme.colors.primary             == tropical7, "Primary color should be 'tropical7'")
        XCTAssert(storedSettings.uiOptions.theme.colors.error               == tropical3, "Error color should be 'tropical3'")
        XCTAssert(storedSettings.uiOptions.theme.text.title.color           == tropical10, "Text title color should be 'tropical10'")
        XCTAssert(storedSettings.uiOptions.theme.view.backgroundColor       == tropical1, "View background color should be 'tropical1'")
        XCTAssert(storedSettings.uiOptions.theme.blurView.backgroundColor   == UIColor.darkGray, "Blur view background color should be 'darkGray'")
        XCTAssert(storedSettings.uiOptions.theme.text.title.color           == tropical10, "Title color should be 'tropical10'")
        XCTAssert(storedSettings.uiOptions.theme.text.amountLabel.color     == tropical10, "Amount label color should be 'tropical10'")
        XCTAssert(storedSettings.uiOptions.theme.text.subtitle.color        == tropical3, "Subtitle color should be 'tropical3'")
        XCTAssert(storedSettings.uiOptions.theme.text.body.color            == UIColor.white, "Body color should be 'white'")
        XCTAssert(storedSettings.uiOptions.theme.text.system.color          == tropical4, "System color should be 'tropical4'")

        XCTAssert(storedSettings.uiOptions.theme.mainButton.colorStates.color(for: .enabled) == tropical8, "Main button's enabled color should be 'tropical8'")
        XCTAssert(storedSettings.uiOptions.theme.mainButton.colorStates.color(for: .selected) == tropical8, "Main button's selected color should be 'tropical8'")
        XCTAssert(storedSettings.uiOptions.theme.mainButton.text.color == tropical4, "Main button's enabled color should be 'tropical8'")
    }
}
