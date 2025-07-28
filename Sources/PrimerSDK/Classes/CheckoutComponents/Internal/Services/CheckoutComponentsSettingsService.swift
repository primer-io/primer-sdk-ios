//
//  CheckoutComponentsSettingsService.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Claude on 25.7.25.
//

import Foundation

/// Service providing type-safe access to PrimerSettings for CheckoutComponents
/// This service ensures CheckoutComponents respects all PrimerSettings configurations
/// and maintains API parity with Drop-in and Headless integrations.
@available(iOS 15.0, *)
internal protocol CheckoutComponentsSettingsServiceProtocol {

    // MARK: - UI Options

    /// Whether the initialization loading screen should be shown
    var isInitScreenEnabled: Bool { get }

    /// Whether the success screen should be shown after successful payment
    var isSuccessScreenEnabled: Bool { get }

    /// Whether the error screen should be shown after failed payment
    var isErrorScreenEnabled: Bool { get }

    /// Available dismissal mechanisms (gestures, close button)
    var dismissalMechanism: [DismissalMechanism] { get }

    /// Card form UI customization options
    var cardFormUIOptions: PrimerCardFormUIOptions? { get }

    /// Theme configuration for UI components
    var theme: PrimerTheme { get }

    // MARK: - Debug Options

    /// Whether 3DS sanity checks are enabled (critical for security)
    var is3DSSanityCheckEnabled: Bool { get }

    // MARK: - Payment Method Options

    /// URL scheme for deep linking and payment method redirects
    var urlScheme: String? { get }

    /// Apple Pay configuration options
    var applePayOptions: PrimerApplePayOptions? { get }

    /// Klarna payment options
    var klarnaOptions: PrimerKlarnaOptions? { get }

    /// 3DS configuration options
    var threeDsOptions: PrimerThreeDsOptions? { get }

    /// Stripe payment options (ACH, etc.)
    var stripeOptions: PrimerStripeOptions? { get }

    // MARK: - Payment Handling

    /// Payment handling mode (auto vs manual)
    var paymentHandling: PrimerPaymentHandling { get }

    // MARK: - Locale Data

    /// Language code for localization
    var languageCode: String? { get }

    /// Region code for localization
    var regionCode: String? { get }

    /// Complete locale code (language + region)
    var localeCode: String { get }

    /// Complete locale data for localization
    var localeData: PrimerLocaleData { get }

    /// Locale-aware bundle for string localization based on configured locale
    func localizedBundle() -> Bundle

    // MARK: - Other Options

    /// API version for backend communication
    var apiVersion: PrimerApiVersion { get }

    /// Whether client session caching is enabled
    var clientSessionCachingEnabled: Bool { get }

    // MARK: - Validation Methods

    /// Validates URL scheme configuration
    /// - Throws: PrimerError if URL scheme is invalid
    /// - Returns: Valid URL for the configured scheme
    func validUrlForUrlScheme() throws -> URL

    /// Validates URL scheme and returns the scheme string
    /// - Throws: PrimerError if URL scheme is invalid
    /// - Returns: Valid scheme string
    func validSchemeForUrlScheme() throws -> String
}

/// Default implementation of CheckoutComponentsSettingsService
@available(iOS 15.0, *)
internal final class CheckoutComponentsSettingsService: CheckoutComponentsSettingsServiceProtocol {

    // MARK: - Properties

    private let settings: PrimerSettings

    // MARK: - Initialization

    init(settings: PrimerSettings) {
        self.settings = settings
    }

    // MARK: - UI Options

    var isInitScreenEnabled: Bool {
        settings.uiOptions.isInitScreenEnabled
    }

    var isSuccessScreenEnabled: Bool {
        settings.uiOptions.isSuccessScreenEnabled
    }

    var isErrorScreenEnabled: Bool {
        settings.uiOptions.isErrorScreenEnabled
    }

    var dismissalMechanism: [DismissalMechanism] {
        settings.uiOptions.dismissalMechanism
    }

    var cardFormUIOptions: PrimerCardFormUIOptions? {
        settings.uiOptions.cardFormUIOptions
    }

    var theme: PrimerTheme {
        settings.uiOptions.theme
    }

    // MARK: - Debug Options

    var is3DSSanityCheckEnabled: Bool {
        settings.debugOptions.is3DSSanityCheckEnabled
    }

    // MARK: - Payment Method Options

    var urlScheme: String? {
        // Access private urlScheme through validation methods
        return try? validSchemeForUrlScheme()
    }

    var applePayOptions: PrimerApplePayOptions? {
        settings.paymentMethodOptions.applePayOptions
    }

    var klarnaOptions: PrimerKlarnaOptions? {
        settings.paymentMethodOptions.klarnaOptions
    }

    var threeDsOptions: PrimerThreeDsOptions? {
        settings.paymentMethodOptions.threeDsOptions
    }

    var stripeOptions: PrimerStripeOptions? {
        settings.paymentMethodOptions.stripeOptions
    }

    // MARK: - Payment Handling

    var paymentHandling: PrimerPaymentHandling {
        settings.paymentHandling
    }

    // MARK: - Locale Data

    var languageCode: String? {
        settings.localeData.languageCode
    }

    var regionCode: String? {
        settings.localeData.regionCode
    }

    var localeCode: String {
        settings.localeData.localeCode
    }

    var localeData: PrimerLocaleData {
        settings.localeData
    }

    func localizedBundle() -> Bundle {
        // LOCALE DATA INTEGRATION: Get locale-aware bundle for CheckoutComponents
        // This respects the PrimerSettings.localeData configuration

        // If a specific language code is configured, try to get that bundle
        if let languageCode = settings.localeData.languageCode.isEmpty ? nil : settings.localeData.languageCode,
           languageCode != "en" { // Only apply custom localization for non-English

            // Try to get localized bundle for the configured language
            if let localizedPath = Bundle.primerResources.path(forResource: languageCode, ofType: "lproj"),
               let localizedBundle = Bundle(path: localizedPath) {
                return localizedBundle
            }

            // If region code is available, try language-region combo (e.g., "en-US")
            if let regionCode = settings.localeData.regionCode {
                let localeString = "\(languageCode)-\(regionCode)"
                if let localizedPath = Bundle.primerResources.path(forResource: localeString, ofType: "lproj"),
                   let localizedBundle = Bundle(path: localizedPath) {
                    return localizedBundle
                }
            }
        }

        // Fallback to default bundle if no localization found or if default language
        return Bundle.primerResources
    }

    // MARK: - Other Options

    var apiVersion: PrimerApiVersion {
        settings.apiVersion
    }

    var clientSessionCachingEnabled: Bool {
        settings.clientSessionCachingEnabled
    }

    // MARK: - Validation Methods

    func validUrlForUrlScheme() throws -> URL {
        try settings.paymentMethodOptions.validUrlForUrlScheme()
    }

    func validSchemeForUrlScheme() throws -> String {
        try settings.paymentMethodOptions.validSchemeForUrlScheme()
    }
}

// MARK: - DI Container Registration

@available(iOS 15.0, *)
extension CheckoutComponentsSettingsService {

    /// Registers the settings service in the DI container
    /// - Parameter container: Container to register in
    /// - Parameter settings: PrimerSettings instance to use
    static func register(in container: Container, with settings: PrimerSettings) async {
        let service = CheckoutComponentsSettingsService(settings: settings)
        _ = try? await container.register(CheckoutComponentsSettingsServiceProtocol.self)
            .asSingleton()
            .with { _ in service }
    }
}
