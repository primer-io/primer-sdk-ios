//
//  SettingsObserver.swift
//  PrimerSDK - CheckoutComponents
//
//  Created on 25.7.25.
//

import Foundation

/// Protocol for observing PrimerSettings changes in CheckoutComponents
/// This allows components to react to settings updates without requiring restart
@available(iOS 15.0, *)
protocol SettingsObserverProtocol: AnyObject {

    /// Called when PrimerSettings are updated
    /// - Parameters:
    ///   - oldSettings: Previous settings configuration
    ///   - newSettings: New settings configuration
    func settingsDidChange(from oldSettings: PrimerSettings, to newSettings: PrimerSettings) async

    /// Called when UI options change (screen settings, dismissal, theme)
    /// - Parameters:
    ///   - oldOptions: Previous UI options
    ///   - newOptions: New UI options
    func uiOptionsDidChange(from oldOptions: PrimerUIOptions, to newOptions: PrimerUIOptions) async

    /// Called when debug options change (3DS sanity check, logging level)
    /// - Parameters:
    ///   - oldOptions: Previous debug options
    ///   - newOptions: New debug options
    func debugOptionsDidChange(from oldOptions: PrimerDebugOptions, to newOptions: PrimerDebugOptions) async

    /// Called when payment method options change (URL scheme, Apple Pay, 3DS)
    /// - Parameters:
    ///   - oldOptions: Previous payment method options
    ///   - newOptions: New payment method options
    func paymentMethodOptionsDidChange(from oldOptions: PrimerPaymentMethodOptions, to newOptions: PrimerPaymentMethodOptions) async

    /// Called when locale data changes (language, region)
    /// - Parameters:
    ///   - oldLocale: Previous locale data
    ///   - newLocale: New locale data
    func localeDataDidChange(from oldLocale: PrimerLocaleData, to newLocale: PrimerLocaleData) async

    /// Called when payment handling mode changes
    /// - Parameters:
    ///   - oldMode: Previous payment handling mode
    ///   - newMode: New payment handling mode
    func paymentHandlingDidChange(from oldMode: PrimerPaymentHandling, to newMode: PrimerPaymentHandling) async
}

/// Service for observing and propagating PrimerSettings changes throughout CheckoutComponents
/// This service watches for settings updates and notifies registered observers
@available(iOS 15.0, *)
final class SettingsObserver: LogReporter, @unchecked Sendable {

    // MARK: - Properties

    /// Current settings being observed
    private var currentSettings: PrimerSettings

    /// Registered observers for settings changes
    private var observers: [WeakObserverReference] = []

    /// Queue for handling settings changes
    private let settingsQueue = DispatchQueue(label: "com.primer.settings-observer", qos: .utility)

    // MARK: - Initialization

    init(settings: PrimerSettings) {
        self.currentSettings = settings
        logger.debug(message: "🔧 [SettingsObserver] Initialized with settings")
    }

    // MARK: - Observer Management

    /// Register an observer for settings changes
    /// - Parameter observer: Observer to register
    func addObserver(_ observer: SettingsObserverProtocol) {
        settingsQueue.async { [weak self] in
            guard let self = self else { return }

            // Remove any existing reference to this observer (by memory address)
            self.observers.removeAll { $0.observer == nil || ObjectIdentifier($0.observer!) == ObjectIdentifier(observer) }

            // Add new observer reference
            self.observers.append(WeakObserverReference(observer: observer))

            self.logger.debug(message: "🔧 [SettingsObserver] Observer registered. Total observers: \(self.observers.count)")
        }
    }

    /// Unregister an observer for settings changes
    /// - Parameter observer: Observer to unregister
    func removeObserver(_ observer: SettingsObserverProtocol) {
        settingsQueue.async { [weak self] in
            guard let self = self else { return }

            self.observers.removeAll { $0.observer == nil || ObjectIdentifier($0.observer!) == ObjectIdentifier(observer) }

            self.logger.debug(message: "🔧 [SettingsObserver] Observer removed. Total observers: \(self.observers.count)")
        }
    }

    // MARK: - Settings Change Detection

    /// Manually trigger settings update
    /// - Parameter newSettings: New settings configuration
    func settingsDidUpdate(_ newSettings: PrimerSettings) async {
        await handleSettingsChange(newSettings)
    }

    /// Handle settings change and notify observers
    /// - Parameter newSettings: New settings configuration
    private func handleSettingsChange(_ newSettings: PrimerSettings) async {
        let oldSettings = currentSettings

        logger.info(message: "🔧 [SettingsObserver] Processing settings change")

        // Update current settings
        currentSettings = newSettings

        // Notify observers of overall settings change
        await notifyObservers { observer in
            await observer.settingsDidChange(from: oldSettings, to: newSettings)
        }

        // Check specific settings categories for granular updates
        await checkUIOptionsChange(from: oldSettings.uiOptions, to: newSettings.uiOptions)
        await checkDebugOptionsChange(from: oldSettings.debugOptions, to: newSettings.debugOptions)
        await checkPaymentMethodOptionsChange(from: oldSettings.paymentMethodOptions, to: newSettings.paymentMethodOptions)
        await checkLocaleDataChange(from: oldSettings.localeData, to: newSettings.localeData)
        await checkPaymentHandlingChange(from: oldSettings.paymentHandling, to: newSettings.paymentHandling)

        logger.info(message: "🔧 [SettingsObserver] Settings change processing completed")
    }

    // MARK: - Granular Change Detection

    /// Check for UI options changes
    private func checkUIOptionsChange(from oldOptions: PrimerUIOptions, to newOptions: PrimerUIOptions) async {
        if !areUIOptionsEqual(oldOptions, newOptions) {
            logger.debug(message: "🔧 [SettingsObserver] UI options changed")
            await notifyObservers { observer in
                await observer.uiOptionsDidChange(from: oldOptions, to: newOptions)
            }
        }
    }

    /// Check for debug options changes
    private func checkDebugOptionsChange(from oldOptions: PrimerDebugOptions, to newOptions: PrimerDebugOptions) async {
        if !areDebugOptionsEqual(oldOptions, newOptions) {
            logger.debug(message: "🔧 [SettingsObserver] Debug options changed")
            await notifyObservers { observer in
                await observer.debugOptionsDidChange(from: oldOptions, to: newOptions)
            }
        }
    }

    /// Check for payment method options changes
    private func checkPaymentMethodOptionsChange(from oldOptions: PrimerPaymentMethodOptions, to newOptions: PrimerPaymentMethodOptions) async {
        if !arePaymentMethodOptionsEqual(oldOptions, newOptions) {
            logger.debug(message: "🔧 [SettingsObserver] Payment method options changed")
            await notifyObservers { observer in
                await observer.paymentMethodOptionsDidChange(from: oldOptions, to: newOptions)
            }
        }
    }

    /// Check for locale data changes
    private func checkLocaleDataChange(from oldLocale: PrimerLocaleData, to newLocale: PrimerLocaleData) async {
        if oldLocale != newLocale {
            logger.debug(message: "🔧 [SettingsObserver] Locale data changed")
            await notifyObservers { observer in
                await observer.localeDataDidChange(from: oldLocale, to: newLocale)
            }
        }
    }

    /// Check for payment handling changes
    private func checkPaymentHandlingChange(from oldMode: PrimerPaymentHandling, to newMode: PrimerPaymentHandling) async {
        if oldMode != newMode {
            logger.debug(message: "🔧 [SettingsObserver] Payment handling changed from \(oldMode.rawValue) to \(newMode.rawValue)")
            await notifyObservers { observer in
                await observer.paymentHandlingDidChange(from: oldMode, to: newMode)
            }
        }
    }

    // MARK: - Observer Notification

    /// Notify all registered observers with a specific callback
    /// - Parameter callback: Async callback to execute for each observer
    private func notifyObservers(_ callback: @escaping (SettingsObserverProtocol) async -> Void) async {
        // Clean up dead observers first
        settingsQueue.async { [weak self] in
            self?.observers.removeAll { $0.observer == nil }
        }

        // Get current observers
        let currentObservers = await withCheckedContinuation { continuation in
            settingsQueue.async { [weak self] in
                let observers = self?.observers.compactMap { $0.observer } ?? []
                continuation.resume(returning: observers)
            }
        }

        // Notify each observer
        await withTaskGroup(of: Void.self) { group in
            for observer in currentObservers {
                group.addTask {
                    await callback(observer)
                }
            }
        }
    }

    // MARK: - Settings Comparison

    /// Compare two PrimerSettings instances for equality
    private func areSettingsEqual(_ lhs: PrimerSettings, _ rhs: PrimerSettings) -> Bool {
        return areUIOptionsEqual(lhs.uiOptions, rhs.uiOptions) &&
            areDebugOptionsEqual(lhs.debugOptions, rhs.debugOptions) &&
            arePaymentMethodOptionsEqual(lhs.paymentMethodOptions, rhs.paymentMethodOptions) &&
            lhs.localeData == rhs.localeData &&
            lhs.paymentHandling == rhs.paymentHandling
    }

    /// Compare UI options for equality
    private func areUIOptionsEqual(_ lhs: PrimerUIOptions, _ rhs: PrimerUIOptions) -> Bool {
        return lhs.isInitScreenEnabled == rhs.isInitScreenEnabled &&
            lhs.isSuccessScreenEnabled == rhs.isSuccessScreenEnabled &&
            lhs.isErrorScreenEnabled == rhs.isErrorScreenEnabled &&
            lhs.dismissalMechanism == rhs.dismissalMechanism &&
            lhs.theme == rhs.theme &&
            lhs.appearanceMode == rhs.appearanceMode
    }

    /// Compare debug options for equality
    private func areDebugOptionsEqual(_ lhs: PrimerDebugOptions, _ rhs: PrimerDebugOptions) -> Bool {
        return lhs.is3DSSanityCheckEnabled == rhs.is3DSSanityCheckEnabled
        // Note: Logger comparison not included as it's typically set once
    }

    /// Compare payment method options for equality
    private func arePaymentMethodOptionsEqual(_ lhs: PrimerPaymentMethodOptions, _ rhs: PrimerPaymentMethodOptions) -> Bool {
        let lhsUrlScheme = try? lhs.validSchemeForUrlScheme()
        let rhsUrlScheme = try? rhs.validSchemeForUrlScheme()
        return lhsUrlScheme == rhsUrlScheme &&
            areApplePayOptionsEqual(lhs.applePayOptions, rhs.applePayOptions) &&
            lhs.threeDsOptions == rhs.threeDsOptions &&
            lhs.stripeOptions == rhs.stripeOptions
    }

    /// Compare Apple Pay options for equality
    private func areApplePayOptionsEqual(_ lhs: PrimerApplePayOptions?, _ rhs: PrimerApplePayOptions?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (lhsOptions?, rhsOptions?):
            return lhsOptions.merchantIdentifier == rhsOptions.merchantIdentifier
        default:
            return false
        }
    }

}

// MARK: - Weak Observer Reference

/// Weak reference wrapper for observer objects to prevent retain cycles
@available(iOS 15.0, *)
private class WeakObserverReference {
    weak var observer: SettingsObserverProtocol?

    init(observer: SettingsObserverProtocol) {
        self.observer = observer
    }
}

// MARK: - DI Container Registration

@available(iOS 15.0, *)
extension SettingsObserver {

    /// Registers the settings observer in the DI container
    /// - Parameters:
    ///   - container: Container to register in
    ///   - settings: Initial settings configuration
    static func register(in container: Container, with settings: PrimerSettings) async {
        _ = try? await container.register(SettingsObserver.self)
            .asSingleton()
            .with { _ in SettingsObserver(settings: settings) }
    }
}

// MARK: - Convenience Extensions

@available(iOS 15.0, *)
extension SettingsObserverProtocol {

    /// Default implementation for granular change methods - only implement the ones you need
    func uiOptionsDidChange(from oldOptions: PrimerUIOptions, to newOptions: PrimerUIOptions) async {
        // Default implementation does nothing
    }

    func debugOptionsDidChange(from oldOptions: PrimerDebugOptions, to newOptions: PrimerDebugOptions) async {
        // Default implementation does nothing
    }

    func paymentMethodOptionsDidChange(from oldOptions: PrimerPaymentMethodOptions, to newOptions: PrimerPaymentMethodOptions) async {
        // Default implementation does nothing
    }

    func localeDataDidChange(from oldLocale: PrimerLocaleData, to newLocale: PrimerLocaleData) async {
        // Default implementation does nothing
    }

    func paymentHandlingDidChange(from oldMode: PrimerPaymentHandling, to newMode: PrimerPaymentHandling) async {
        // Default implementation does nothing
    }
}
