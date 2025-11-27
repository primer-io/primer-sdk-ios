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

        /// Custom form title
        public let title: String?

        /// Card details section configuration
        public let cardDetails: CardDetails

        /// Billing address section configuration
        public let billingAddress: BillingAddress

        /// Country picker configuration
        public let selectCountry: SelectCountry

        /// Submit button configuration
        public let submitButton: SubmitButton

        /// Navigation callback overrides
        public let navigation: Navigation

        /// Full form screen override
        public let screen: Component?

        /// Creates a new card form configuration.
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

        /// Card details section configuration
        public struct CardDetails {
            /// Custom section content layout
            public let content: Component?

            /// Custom card number field
            public let cardNumber: Component?

            /// Custom expiry date field
            public let expiryDate: Component?

            /// Custom CVV field
            public let cvv: Component?

            /// Custom cardholder name field
            public let cardholderName: Component?

            /// Custom card network selector
            public let cardNetwork: Component?

            /// Creates a new card details configuration.
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

        /// Billing address section configuration
        public struct BillingAddress {
            /// Custom section content layout
            public let content: Component?

            /// Custom country code field
            public let countryCode: Component?

            /// Custom first name field
            public let firstName: Component?

            /// Custom last name field
            public let lastName: Component?

            /// Custom address line 1 field
            public let addressLine1: Component?

            /// Custom address line 2 field
            public let addressLine2: Component?

            /// Custom postal code field
            public let postalCode: Component?

            /// Custom city field
            public let city: Component?

            /// Custom state field
            public let state: Component?

            /// Creates a new billing address configuration.
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

        /// Country picker configuration
        public struct SelectCountry {
            /// Custom picker title
            public let title: String?

            /// Search bar configuration
            public let searchBar: SearchBar

            /// Custom country item renderer
            public let countryItem: CountryItemComponent?

            /// Full screen override
            public let screen: Component?

            /// Navigation callback overrides
            public let navigation: Navigation

            /// Creates a new country picker configuration.
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

            /// Search bar configuration
            public struct SearchBar {
                /// Custom placeholder text
                public let placeholder: String?

                /// Custom search bar component
                public let content: Component?

                /// Creates a new search bar configuration.
                /// - Parameters:
                ///   - placeholder: Custom placeholder. Default: nil (uses SDK default)
                ///   - content: Custom search bar. Default: nil (uses SDK default)
                public init(placeholder: String? = nil, content: Component? = nil) {
                    self.placeholder = placeholder
                    self.content = content
                }
            }

            /// Navigation callback overrides
            public struct Navigation {
                /// Called when country is selected
                /// - Parameters:
                ///   - code: The ISO country code (e.g., "US", "GB")
                ///   - name: The country display name (e.g., "United States", "United Kingdom")
                public let onCountrySelected: ((_ code: String, _ name: String) -> Void)?

                /// Creates a new navigation configuration.
                /// - Parameters:
                ///   - onCountrySelected: Selection callback. Default: nil (uses SDK default)
                public init(onCountrySelected: ((_ code: String, _ name: String) -> Void)? = nil) {
                    self.onCountrySelected = onCountrySelected
                }
            }
        }

        // MARK: - Submit Button

        /// Submit button configuration
        public struct SubmitButton {
            /// Custom button text
            public let text: String?

            /// Whether to show loading indicator during submission
            public let showLoadingIndicator: Bool

            /// Custom button component
            public let content: Component?

            /// Creates a new submit button configuration.
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

        /// Navigation callback overrides for card form
        public struct Navigation {
            /// Called to show country selection
            public let showCountrySelection: (() -> Void)?

            /// Creates a new navigation configuration.
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

    /// Card payment method type identifier.
    public static var paymentMethodType: String {
        PrimerPaymentMethodType.paymentCard.rawValue
    }

    // Note: `screen: Component?` property already exists in CardForm,
    // satisfying the protocol requirement.
}
