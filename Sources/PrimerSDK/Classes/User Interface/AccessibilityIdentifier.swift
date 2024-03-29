//
//  AccessibilityIdentifier.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 24.11.2023.
//

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
}
