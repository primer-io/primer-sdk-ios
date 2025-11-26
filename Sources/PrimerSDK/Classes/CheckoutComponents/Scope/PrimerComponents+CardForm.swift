//
//  PrimerComponents+CardForm.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - PrimerComponents.CardForm

@available(iOS 15.0, *)
extension PrimerComponents {

    /// Configuration for card payment form.
    public struct CardForm {

        public let title: String?
        public let cardDetails: CardDetails
        public let billingAddress: BillingAddress
        public let selectCountry: SelectCountry
        public let submitButton: SubmitButton
        public let navigation: Navigation
        public let screen: Component?

        /// Creates a card form configuration.
        /// - Parameters:
        ///   - title: Custom title. Default: nil (uses SDK default)
        ///   - cardDetails: Card details config. Default: CardDetails()
        ///   - billingAddress: Billing address config. Default: BillingAddress()
        ///   - selectCountry: Country picker config. Default: SelectCountry()
        ///   - submitButton: Submit button config. Default: SubmitButton()
        ///   - navigation: Navigation callbacks. Default: Navigation()
        ///   - screen: Full screen override. Default: nil (uses SDK default)
        public init(
            title: String? = nil,
            cardDetails: CardDetails = CardDetails(),
            billingAddress: BillingAddress = BillingAddress(),
            selectCountry: SelectCountry = SelectCountry(),
            submitButton: SubmitButton = SubmitButton(),
            navigation: Navigation = Navigation(),
            screen: Component? = nil
        ) {
            self.title = title
            self.cardDetails = cardDetails
            self.billingAddress = billingAddress
            self.selectCountry = selectCountry
            self.submitButton = submitButton
            self.navigation = navigation
            self.screen = screen
        }

        // MARK: - Card Details

        /// Card details section configuration.
        public struct CardDetails {
            public let content: Component?
            public let cardNumber: Component?
            public let expiryDate: Component?
            public let cvv: Component?
            public let cardholderName: Component?
            public let cardNetwork: Component?

            /// Creates a card details configuration.
            /// - Parameters:
            ///   - content: Custom section layout. Default: nil (uses SDK default)
            ///   - cardNumber: Custom card number field. Default: nil (uses SDK default)
            ///   - expiryDate: Custom expiry date field. Default: nil (uses SDK default)
            ///   - cvv: Custom CVV field. Default: nil (uses SDK default)
            ///   - cardholderName: Custom cardholder name field. Default: nil (uses SDK default)
            ///   - cardNetwork: Custom network selector. Default: nil (uses SDK default)
            public init(
                content: Component? = nil,
                cardNumber: Component? = nil,
                expiryDate: Component? = nil,
                cvv: Component? = nil,
                cardholderName: Component? = nil,
                cardNetwork: Component? = nil
            ) {
                self.content = content
                self.cardNumber = cardNumber
                self.expiryDate = expiryDate
                self.cvv = cvv
                self.cardholderName = cardholderName
                self.cardNetwork = cardNetwork
            }
        }

        // MARK: - Billing Address

        /// Billing address section configuration.
        public struct BillingAddress {
            public let content: Component?
            public let countryCode: Component?
            public let firstName: Component?
            public let lastName: Component?
            public let addressLine1: Component?
            public let addressLine2: Component?
            public let postalCode: Component?
            public let city: Component?
            public let state: Component?

            /// Creates a billing address configuration.
            /// - Parameters:
            ///   - content: Custom section layout. Default: nil (uses SDK default)
            ///   - countryCode: Custom country code field. Default: nil (uses SDK default)
            ///   - firstName: Custom first name field. Default: nil (uses SDK default)
            ///   - lastName: Custom last name field. Default: nil (uses SDK default)
            ///   - addressLine1: Custom address line 1 field. Default: nil (uses SDK default)
            ///   - addressLine2: Custom address line 2 field. Default: nil (uses SDK default)
            ///   - postalCode: Custom postal code field. Default: nil (uses SDK default)
            ///   - city: Custom city field. Default: nil (uses SDK default)
            ///   - state: Custom state field. Default: nil (uses SDK default)
            public init(
                content: Component? = nil,
                countryCode: Component? = nil,
                firstName: Component? = nil,
                lastName: Component? = nil,
                addressLine1: Component? = nil,
                addressLine2: Component? = nil,
                postalCode: Component? = nil,
                city: Component? = nil,
                state: Component? = nil
            ) {
                self.content = content
                self.countryCode = countryCode
                self.firstName = firstName
                self.lastName = lastName
                self.addressLine1 = addressLine1
                self.addressLine2 = addressLine2
                self.postalCode = postalCode
                self.city = city
                self.state = state
            }
        }

        // MARK: - Select Country

        public struct SelectCountry {
            public let title: String?
            public let searchBar: SearchBar
            public let countryItem: CountryItemComponent?
            public let screen: Component?
            public let navigation: Navigation

            /// Creates a country picker configuration.
            /// - Parameters:
            ///   - title: Custom title. Default: nil (uses SDK default)
            ///   - searchBar: Search bar config. Default: SearchBar()
            ///   - countryItem: Custom item renderer. Default: nil (uses SDK default)
            ///   - screen: Full screen override. Default: nil (uses SDK default)
            ///   - navigation: Navigation callbacks. Default: Navigation()
            public init(
                title: String? = nil,
                searchBar: SearchBar = SearchBar(),
                countryItem: CountryItemComponent? = nil,
                screen: Component? = nil,
                navigation: Navigation = Navigation()
            ) {
                self.title = title
                self.searchBar = searchBar
                self.countryItem = countryItem
                self.screen = screen
                self.navigation = navigation
            }

            public struct SearchBar {
                public let placeholder: String?
                public let content: Component?

                /// Creates a search bar configuration.
                /// - Parameters:
                ///   - placeholder: Custom placeholder. Default: nil (uses SDK default)
                ///   - content: Custom search bar. Default: nil (uses SDK default)
                public init(placeholder: String? = nil, content: Component? = nil) {
                    self.placeholder = placeholder
                    self.content = content
                }
            }

            public struct Navigation {
                /// Called when country is selected with ISO code (e.g., "US") and display name (e.g., "United States").
                public let onCountrySelected: ((_ code: String, _ name: String) -> Void)?

                /// Creates a navigation configuration.
                /// - Parameters:
                ///   - onCountrySelected: Selection callback. Default: nil (uses SDK default)
                public init(onCountrySelected: ((_ code: String, _ name: String) -> Void)? = nil) {
                    self.onCountrySelected = onCountrySelected
                }
            }
        }

        // MARK: - Submit Button

        public struct SubmitButton {
            public let text: String?
            /// Shows loading indicator during submission.
            public let showLoadingIndicator: Bool
            public let content: Component?

            /// Creates a submit button configuration.
            /// - Parameters:
            ///   - text: Custom button text. Default: nil (uses SDK default)
            ///   - showLoadingIndicator: Show loading indicator. Default: true
            ///   - content: Custom button component. Default: nil (uses SDK default)
            public init(
                text: String? = nil,
                showLoadingIndicator: Bool = true,
                content: Component? = nil
            ) {
                self.text = text
                self.showLoadingIndicator = showLoadingIndicator
                self.content = content
            }
        }

        // MARK: - Navigation

        public struct Navigation {
            public let showCountrySelection: (() -> Void)?

            /// Creates a navigation configuration.
            /// - Parameters:
            ///   - showCountrySelection: Country selection callback. Default: nil (uses SDK default)
            public init(showCountrySelection: (() -> Void)? = nil) {
                self.showCountrySelection = showCountrySelection
            }
        }
    }
}

// MARK: - PaymentMethodConfiguration Conformance

@available(iOS 15.0, *)
extension PrimerComponents.CardForm: PaymentMethodConfiguration {

    public static var paymentMethodType: String {
        PrimerPaymentMethodType.paymentCard.rawValue
    }
}
