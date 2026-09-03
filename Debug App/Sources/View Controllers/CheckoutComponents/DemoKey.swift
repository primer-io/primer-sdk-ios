//
//  DemoKey.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

/// Stable identifier of a CheckoutComponents demo, used as the deep link's `demo` query value.
/// The raw values are a cross-platform contract shared byte-for-byte with Primer Studio (Android)
/// and the E2E suite — they are literals, never derived from a display name.
enum DemoKey: String, CaseIterable {
    case defaultCheckout = "default_checkout"
    case inlineCheckout = "inline_checkout"
    case inlineCardForm = "inline_card_form"
    case cardFormSheet = "card_form_sheet"
    case customCardForm = "custom_card_form"
    case prefillCardholderName = "prefill_cardholder_name"
    case beforePaymentGate = "before_payment_gate"
    case paymentMethodListOnly = "payment_method_list_only"
    case customPaymentMethods = "custom_payment_methods"
    case customGridPaymentMethods = "custom_grid_payment_methods"
    case radioSelection = "radio_selection"
    case vaultManagement = "vault_management"
    case vaultedPaymentMethods = "vaulted_payment_methods"
    case vaultModeInline = "vault_mode_inline"
    case dynamicVault = "dynamic_vault"
    case merchantNavigation = "merchant_navigation"
    case customResultScreens = "custom_result_screens"
    case customNavigation = "custom_navigation"
    case customTheme = "custom_theme"
    case redTheme = "red_theme"
    case greenTheme = "green_theme"
    case purpleTheme = "purple_theme"
    case noRadiusTheme = "no_radius_theme"
    case smallSizesTheme = "small_sizes_theme"
    case largeSizesTheme = "large_sizes_theme"
    case lightTypographyTheme = "light_typography_theme"
    case boldTypographyTheme = "bold_typography_theme"
    case largeTypographyTheme = "large_typography_theme"
    case customFontTheme = "custom_font_theme"
    case refreshClientSession = "refresh_client_session"
}
