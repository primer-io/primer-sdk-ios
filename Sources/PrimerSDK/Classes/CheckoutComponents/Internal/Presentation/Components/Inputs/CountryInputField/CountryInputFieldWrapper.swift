//
//  CountryInputFieldWrapper.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A wrapper view that properly observes the DefaultCardFormScope and ensures UI updates
@available(iOS 15.0, *)
struct CountryInputFieldWrapper: View, LogReporter {
    @ObservedObject var scope: DefaultCardFormScope

    let label: String?
    let placeholder: String
    let styling: PrimerFieldStyling?
    let onValidationChange: ((Bool) -> Void)?
    let onOpenCountrySelector: (() -> Void)?

    var body: some View {
        CountryInputField(
            label: label,
            placeholder: placeholder,
            scope: scope,
            selectedCountry: selectedCountryFromCode,
            styling: styling
        )
    }

    private var selectedCountryFromCode: CountryCode.PhoneNumberCountryCode? {
        let code = scope.structuredState.data[.countryCode]
        guard !code.isEmpty else {
            return nil
        }
        let matchingCountry = CountryCode.phoneNumberCountryCodes.first { phoneCountry in
            phoneCountry.code.caseInsensitiveCompare(code) == .orderedSame
        }
        return matchingCountry
    }
}
