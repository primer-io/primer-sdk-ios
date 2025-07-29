//
//  AccessibilityIdentifier.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
public struct AccessibilityIdentifier {
    public enum General: String {
        case backButton = "navigation_bar_back"
    }
    public enum BanksComponent: String {
        case title = "choose_bank_title"
        case banksList = "banks_list"
        case searchBar = "search_bar"
    }
    public enum KlarnaComponent: String {
        case title = "title"
        case initializeView = "initialize_klarna_view"
        case paymentViewContainer = "klarna_payment_view_container"
        case authorize = "authorize"
    }
    public enum StripeAchUserDetailsComponent: String {
        case title = "title"
        case subtitle = "subtitle"
        case firstNameTextField = "first_name_input"
        case lastNameTextField = "last_name_input"
        case emailAddressTextField = "email_address_input"
        case submitButton = "submit"
        case acceptMandateButton = "accept"
        case declineMandateButton = "decline"
    }
    public enum ResultScreen: String {
        case successImage = "checkmark.circle"
        case failureImage = "xmark.circle"
        case messageLabel = "session_complete_message"
        case descriptionLabel = "session_complete_description"
        case primaryButton = "primary_button"
        case secondaryButton = "secondary_button"
    }
}
