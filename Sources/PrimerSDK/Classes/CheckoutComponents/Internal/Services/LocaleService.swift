//
//  LocaleService.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Claude on 25.7.25.
//

import Foundation

/// Service providing locale-aware string localization for CheckoutComponents
/// This service respects PrimerSettings.localeData configuration and provides
/// a centralized way to get localized strings based on merchant configuration.
@available(iOS 15.0, *)
internal protocol LocaleServiceProtocol {

    /// Get localized string for a given key using configured locale
    /// - Parameters:
    ///   - key: Localization key
    ///   - defaultValue: Default value if localization not found
    ///   - comment: Developer comment for localization context
    /// - Returns: Localized string
    func localizedString(key: String, defaultValue: String, comment: String) -> String

    /// Get formatted localized string with arguments
    /// - Parameters:
    ///   - key: Localization key
    ///   - defaultValue: Default format string
    ///   - comment: Developer comment
    ///   - arguments: Arguments for string formatting
    /// - Returns: Formatted localized string
    func localizedString(key: String, defaultValue: String, comment: String, arguments: CVarArg...) -> String

    /// Current locale being used for localization
    var currentLocale: Locale { get }

    /// Language code being used
    var currentLanguageCode: String { get }

    /// Region code being used (if any)
    var currentRegionCode: String? { get }
}

/// Default implementation of LocaleService
@available(iOS 15.0, *)
internal final class LocaleService: LocaleServiceProtocol, LogReporter {

    // MARK: - Properties

    private var settingsService: CheckoutComponentsSettingsServiceProtocol?

    // MARK: - Initialization

    init() {
        Task {
            await injectSettingsService()
        }
    }

    /// Inject settings service from DI container
    private func injectSettingsService() async {
        do {
            guard let container = await DIContainer.current else {
                logger.warn(message: "🌐 [LocaleService] DI Container not available for settings service injection")
                return
            }

            settingsService = try await container.resolve(CheckoutComponentsSettingsServiceProtocol.self)
            logger.debug(message: "🌐 [LocaleService] Settings service injected successfully")

            // Log current locale configuration
            if let service = settingsService {
                logger.info(message: "🌐 [LocaleService] Configured locale: \(service.localeCode) (language: \(service.languageCode ?? "default"), region: \(service.regionCode ?? "none"))")
            }
        } catch {
            logger.error(message: "🌐 [LocaleService] Failed to inject settings service: \(error)")
        }
    }

    // MARK: - LocaleServiceProtocol Implementation

    func localizedString(key: String, defaultValue: String, comment: String) -> String {
        guard let settingsService = settingsService else {
            // Fallback to system bundle if settings service not available
            logger.debug(message: "🌐 [LocaleService] Settings service not available, using default bundle for key: \(key)")
            return NSLocalizedString(key, bundle: Bundle.primerResources, value: defaultValue, comment: comment)
        }

        // LOCALE DATA INTEGRATION: Use configured locale bundle for string lookup
        let localizedBundle = settingsService.localizedBundle()
        let localizedString = NSLocalizedString(key, bundle: localizedBundle, value: defaultValue, comment: comment)

        // Log locale usage for debugging
        if localizedString != defaultValue {
            logger.debug(message: "🌐 [LocaleService] Using localized string for '\(key)' in locale \(settingsService.localeCode)")
        } else {
            logger.debug(message: "🌐 [LocaleService] Using default string for '\(key)' (no localization found for \(settingsService.localeCode))")
        }

        return localizedString
    }

    func localizedString(key: String, defaultValue: String, comment: String, arguments: CVarArg...) -> String {
        let formatString = localizedString(key: key, defaultValue: defaultValue, comment: comment)
        return String(format: formatString, arguments: arguments)
    }

    var currentLocale: Locale {
        guard let settingsService = settingsService else {
            return Locale.current
        }

        // LOCALE DATA INTEGRATION: Create locale from configured language and region
        let localeData = settingsService.localeData
        let localeIdentifier = localeData.localeCode

        return Locale(identifier: localeIdentifier)
    }

    var currentLanguageCode: String {
        guard let settingsService = settingsService,
              let languageCode = settingsService.languageCode,
              !languageCode.isEmpty else {
            return Locale.current.languageCode ?? "en"
        }

        return languageCode
    }

    var currentRegionCode: String? {
        guard let settingsService = settingsService else {
            return Locale.current.regionCode
        }

        return settingsService.regionCode
    }
}

// MARK: - DI Container Registration

@available(iOS 15.0, *)
extension LocaleService {

    /// Registers the locale service in the DI container
    /// - Parameter container: Container to register in
    static func register(in container: Container) async {
        _ = try? await container.register(LocaleServiceProtocol.self)
            .asSingleton()
            .with { _ in
                LocaleService()
            }
    }
}

// MARK: - CheckoutComponentsStrings Extension

/// Extension to CheckoutComponentsStrings to use locale service
@available(iOS 15.0, *)
extension CheckoutComponentsStrings {

    /// Get localized string using the locale service when available
    internal static func localized(
        key: String,
        defaultValue: String,
        comment: String,
        localeService: LocaleServiceProtocol? = nil
    ) -> String {
        if let localeService = localeService {
            return localeService.localizedString(key: key, defaultValue: defaultValue, comment: comment)
        } else {
            // Fallback to existing implementation
            return NSLocalizedString(key, bundle: Bundle.primerResources, value: defaultValue, comment: comment)
        }
    }

    /// Get formatted localized string using the locale service
    internal static func localized(
        key: String,
        defaultValue: String,
        comment: String,
        arguments: CVarArg...,
        localeService: LocaleServiceProtocol? = nil
    ) -> String {
        if let localeService = localeService {
            return localeService.localizedString(key: key, defaultValue: defaultValue, comment: comment, arguments: arguments)
        } else {
            // Fallback to existing implementation
            let formatString = NSLocalizedString(key, bundle: Bundle.primerResources, value: defaultValue, comment: comment)
            return String(format: formatString, arguments: arguments)
        }
    }
}
