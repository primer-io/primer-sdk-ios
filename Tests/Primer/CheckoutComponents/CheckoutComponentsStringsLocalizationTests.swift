//
//  CheckoutComponentsStringsLocalizationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerResources
import XCTest

final class CheckoutComponentsStringsLocalizationTests: XCTestCase {

    private static let table = "CheckoutComponentsStrings"
    private static let klarnaPayWithKey = "primer_klarna_pay_with"
    private static let missing = "__missing__"

    func test_klarnaPayWith_isTranslatedInEveryLocalization() {
        // Given
        let bundles = makeLocalizedBundles()

        // Then
        XCTAssertEqual(bundles.count, 57)
        for (localization, bundle) in bundles {
            let value = bundle.localizedString(forKey: Self.klarnaPayWithKey, value: Self.missing, table: Self.table)
            XCTAssertNotEqual(value, Self.missing, localization)
            XCTAssertFalse(value.isEmpty, localization)
        }
    }

    func test_klarnaPayWith_inEnglish_isPayWith() throws {
        // Given
        let bundle = try XCTUnwrap(makeLocalizedBundles()["en"])

        // When
        let value = bundle.localizedString(forKey: Self.klarnaPayWithKey, value: Self.missing, table: Self.table)

        // Then
        XCTAssertEqual(value, "Pay with")
    }

    // MARK: - Helpers

    private func makeLocalizedBundles() -> [String: Bundle] {
        let resources = Bundle.primerResources
        return Dictionary(uniqueKeysWithValues: resources.localizations.compactMap { localization in
            guard let path = resources.path(forResource: localization, ofType: "lproj"),
                  let bundle = Bundle(path: path),
                  bundle.path(forResource: Self.table, ofType: "strings") != nil
            else { return nil }
            return (localization, bundle)
        })
    }
}
