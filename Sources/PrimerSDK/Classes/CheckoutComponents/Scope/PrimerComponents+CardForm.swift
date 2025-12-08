//
//  PrimerComponents+CardForm.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Input Field Configuration

/// Configuration for customizing a text input field.
/// Supports partial customization (label, placeholder, styling) or full component replacement.
///
/// ## Usage Examples
///
/// ### Partial Customization
/// ```swift
/// InputFieldConfig(
///     label: "Card Number",
///     placeholder: "0000 0000 0000 0000",
///     styling: PrimerFieldStyling(borderColor: .blue)
/// )
/// ```
///
/// ### Full Component Replacement
/// ```swift
/// InputFieldConfig(component: { MyCustomCardNumberField() })
/// ```
@available(iOS 15.0, *)
public struct InputFieldConfig {

    /// Custom label text. When nil, uses SDK default label.
    public let label: String?

    /// Custom placeholder text. When nil, uses SDK default placeholder.
    public let placeholder: String?

    /// Custom styling configuration. When nil, uses SDK default styling.
    public let styling: PrimerFieldStyling?

    /// Full component replacement. When provided, label/placeholder/styling are ignored
    /// and the custom component is rendered instead.
    public let component: Component?

    /// Creates a new input field configuration.
    /// - Parameters:
    ///   - label: Custom label text. Default: nil (uses SDK default)
    ///   - placeholder: Custom placeholder text. Default: nil (uses SDK default)
    ///   - styling: Custom styling. Default: nil (uses SDK default)
    ///   - component: Full component replacement. Default: nil (uses SDK default field)
    public init(
        label: String? = nil,
        placeholder: String? = nil,
        styling: PrimerFieldStyling? = nil,
        component: Component? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.styling = styling
        self.component = component
    }
}

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
        public let screen: CardFormScreenComponent?
        public let errorView: ErrorComponent?

        /// Creates a card form configuration.
        /// - Parameters:
        ///   - title: Custom title. Default: nil (uses SDK default)
        ///   - cardDetails: Card details config. Default: CardDetails()
        ///   - billingAddress: Billing address config. Default: BillingAddress()
        ///   - selectCountry: Country picker config. Default: SelectCountry()
        ///   - submitButton: Submit button config. Default: SubmitButton()
        ///   - navigation: Navigation callbacks. Default: Navigation()
        ///   - screen: Full screen override with scope access. Default: nil (uses SDK default)
        ///   - errorView: Custom error view. Default: nil (uses SDK default)
        public init(
            title: String? = nil,
            cardDetails: CardDetails = CardDetails(),
            billingAddress: BillingAddress = BillingAddress(),
            selectCountry: SelectCountry = SelectCountry(),
            submitButton: SubmitButton = SubmitButton(),
            navigation: Navigation = Navigation(),
            screen: CardFormScreenComponent? = nil,
            errorView: ErrorComponent? = nil
        ) {
            self.title = title
            self.cardDetails = cardDetails
            self.billingAddress = billingAddress
            self.selectCountry = selectCountry
            self.submitButton = submitButton
            self.navigation = navigation
            self.screen = screen
            self.errorView = errorView
        }

        // MARK: - Card Details

        /// Card details section configuration.
        public struct CardDetails {
            public let content: Component?
            public let cardNumber: InputFieldConfig?
            public let expiryDate: InputFieldConfig?
            public let cvv: InputFieldConfig?
            public let cardholderName: InputFieldConfig?
            public let cardNetwork: Component?
            public let retailOutlet: InputFieldConfig?
            public let otpCode: InputFieldConfig?

            public init(
                content: Component? = nil,
                cardNumber: InputFieldConfig? = nil,
                expiryDate: InputFieldConfig? = nil,
                cvv: InputFieldConfig? = nil,
                cardholderName: InputFieldConfig? = nil,
                cardNetwork: Component? = nil,
                retailOutlet: InputFieldConfig? = nil,
                otpCode: InputFieldConfig? = nil
            ) {
                self.content = content
                self.cardNumber = cardNumber
                self.expiryDate = expiryDate
                self.cvv = cvv
                self.cardholderName = cardholderName
                self.cardNetwork = cardNetwork
                self.retailOutlet = retailOutlet
                self.otpCode = otpCode
            }
        }

        // MARK: - Billing Address

        /// Billing address section configuration.
        public struct BillingAddress {
            public let content: Component?
            public let countryCode: InputFieldConfig?
            public let firstName: InputFieldConfig?
            public let lastName: InputFieldConfig?
            public let addressLine1: InputFieldConfig?
            public let addressLine2: InputFieldConfig?
            public let postalCode: InputFieldConfig?
            public let city: InputFieldConfig?
            public let state: InputFieldConfig?
            public let phoneNumber: InputFieldConfig?
            public let email: InputFieldConfig?

            public init(
                content: Component? = nil,
                countryCode: InputFieldConfig? = nil,
                firstName: InputFieldConfig? = nil,
                lastName: InputFieldConfig? = nil,
                addressLine1: InputFieldConfig? = nil,
                addressLine2: InputFieldConfig? = nil,
                postalCode: InputFieldConfig? = nil,
                city: InputFieldConfig? = nil,
                state: InputFieldConfig? = nil,
                phoneNumber: InputFieldConfig? = nil,
                email: InputFieldConfig? = nil
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
                self.phoneNumber = phoneNumber
                self.email = email
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
