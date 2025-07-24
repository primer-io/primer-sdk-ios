//
//  CountryInputFieldWrapper.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Assistant on 27.7.25.
//

import SwiftUI

/// A wrapper view that properly observes the DefaultCardFormScope and ensures UI updates
@available(iOS 15.0, *)
internal struct CountryInputFieldWrapper: View, LogReporter {
    @ObservedObject var scope: DefaultCardFormScope
    let label: String
    let placeholder: String
    let styling: PrimerFieldStyling?
    let onValidationChange: ((Bool) -> Void)?
    let onOpenCountrySelector: (() -> Void)?
    
    var body: some View {
        CountryInputField(
            label: label,
            placeholder: placeholder,
            selectedCountry: selectedCountryFromCode,
            styling: styling,
            onCountryCodeChange: { countryCode in
                scope.updateCountryCode(countryCode)
            },
            onValidationChange: onValidationChange,
            onOpenCountrySelector: onOpenCountrySelector
        )
    }
    
    /// Convert country code to CountryCode.PhoneNumberCountryCode
    private var selectedCountryFromCode: CountryCode.PhoneNumberCountryCode? {
        let code = scope.debugInternalState.countryCode
        
        guard !code.isEmpty else {
            return nil
        }
        
        // Find the matching country from the phone number country codes
        let matchingCountry = CountryCode.phoneNumberCountryCodes.first { phoneCountry in
            phoneCountry.code.caseInsensitiveCompare(code) == .orderedSame
        }
        
        return matchingCountry
    }
}