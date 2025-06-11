//
//  PrimerCardPaymentConfiguration.swift
//  PrimerSDK
//
//  Created by Claude Code on 25.03.2025.
//

import SwiftUI

// MARK: - Main Configuration Object
@available(iOS 15.0, *)
public struct PrimerCardPaymentConfiguration {
    public let animationConfig: CardPaymentAnimationConfiguration
    public let designConfig: CardPaymentDesignConfiguration
    public let features: CardPaymentFeatureConfiguration
    public let accessibility: CardPaymentAccessibilityConfiguration
    
    public init(
        animationConfig: CardPaymentAnimationConfiguration = .default,
        designConfig: CardPaymentDesignConfiguration = .default,
        features: CardPaymentFeatureConfiguration = .default,
        accessibility: CardPaymentAccessibilityConfiguration = .default
    ) {
        self.animationConfig = animationConfig
        self.designConfig = designConfig
        self.features = features
        self.accessibility = accessibility
    }
    
    // MARK: - Predefined Configurations
    public static let `default` = PrimerCardPaymentConfiguration()
    
    public static let minimal = PrimerCardPaymentConfiguration(
        animationConfig: .minimal,
        designConfig: .default,
        features: .minimal,
        accessibility: .default
    )
    
    public static let enhanced = PrimerCardPaymentConfiguration(
        animationConfig: .enhanced,
        designConfig: .default,
        features: .enhanced,
        accessibility: .enhanced
    )
    
    public static let accessible = PrimerCardPaymentConfiguration(
        animationConfig: .minimal,
        designConfig: .default,
        features: .accessible,
        accessibility: .enhanced
    )
}

// MARK: - Feature Configuration
@available(iOS 15.0, *)
public struct CardPaymentFeatureConfiguration {
    public let showCardNetworkIcons: Bool
    public let enableDynamicCardNetworkDetection: Bool
    public let showHeaderNavigation: Bool
    public let enableFormValidation: Bool
    public let showFieldLabels: Bool
    public let enableHapticFeedback: Bool
    public let autoAdvanceFields: Bool
    
    public init(
        showCardNetworkIcons: Bool = true,
        enableDynamicCardNetworkDetection: Bool = true,
        showHeaderNavigation: Bool = true,
        enableFormValidation: Bool = true,
        showFieldLabels: Bool = true,
        enableHapticFeedback: Bool = true,
        autoAdvanceFields: Bool = false
    ) {
        self.showCardNetworkIcons = showCardNetworkIcons
        self.enableDynamicCardNetworkDetection = enableDynamicCardNetworkDetection
        self.showHeaderNavigation = showHeaderNavigation
        self.enableFormValidation = enableFormValidation
        self.showFieldLabels = showFieldLabels
        self.enableHapticFeedback = enableHapticFeedback
        self.autoAdvanceFields = autoAdvanceFields
    }
    
    // MARK: - Predefined Feature Sets
    public static let `default` = CardPaymentFeatureConfiguration()
    
    public static let minimal = CardPaymentFeatureConfiguration(
        showCardNetworkIcons: false,
        enableDynamicCardNetworkDetection: false,
        showHeaderNavigation: false,
        enableHapticFeedback: false,
        autoAdvanceFields: false
    )
    
    public static let enhanced = CardPaymentFeatureConfiguration(
        showCardNetworkIcons: true,
        enableDynamicCardNetworkDetection: true,
        showHeaderNavigation: true,
        enableFormValidation: true,
        showFieldLabels: true,
        enableHapticFeedback: true,
        autoAdvanceFields: true
    )
    
    public static let accessible = CardPaymentFeatureConfiguration(
        showCardNetworkIcons: true,
        enableDynamicCardNetworkDetection: true,
        showHeaderNavigation: true,
        enableFormValidation: true,
        showFieldLabels: true,
        enableHapticFeedback: false, // Some users prefer reduced haptics
        autoAdvanceFields: false // Better for accessibility
    )
}

// MARK: - Accessibility Configuration
@available(iOS 15.0, *)
public struct CardPaymentAccessibilityConfiguration {
    public let enableVoiceOverEnhancements: Bool
    public let enableLargeTextSupport: Bool
    public let enableHighContrastMode: Bool
    public let enableReducedMotion: Bool
    public let announceFormErrors: Bool
    public let announceCardNetworkDetection: Bool
    public let announcePaymentProcessing: Bool
    public let useSemanticHeaders: Bool
    
    public init(
        enableVoiceOverEnhancements: Bool = true,
        enableLargeTextSupport: Bool = true,
        enableHighContrastMode: Bool = false,
        enableReducedMotion: Bool = true,
        announceFormErrors: Bool = true,
        announceCardNetworkDetection: Bool = true,
        announcePaymentProcessing: Bool = true,
        useSemanticHeaders: Bool = true
    ) {
        self.enableVoiceOverEnhancements = enableVoiceOverEnhancements
        self.enableLargeTextSupport = enableLargeTextSupport
        self.enableHighContrastMode = enableHighContrastMode
        self.enableReducedMotion = enableReducedMotion
        self.announceFormErrors = announceFormErrors
        self.announceCardNetworkDetection = announceCardNetworkDetection
        self.announcePaymentProcessing = announcePaymentProcessing
        self.useSemanticHeaders = useSemanticHeaders
    }
    
    // MARK: - Predefined Accessibility Configurations
    public static let `default` = CardPaymentAccessibilityConfiguration()
    
    public static let enhanced = CardPaymentAccessibilityConfiguration(
        enableVoiceOverEnhancements: true,
        enableLargeTextSupport: true,
        enableHighContrastMode: true,
        enableReducedMotion: true,
        announceFormErrors: true,
        announceCardNetworkDetection: true,
        announcePaymentProcessing: true,
        useSemanticHeaders: true
    )
    
    public static let minimal = CardPaymentAccessibilityConfiguration(
        enableVoiceOverEnhancements: false,
        enableLargeTextSupport: false,
        enableHighContrastMode: false,
        enableReducedMotion: false,
        announceFormErrors: false,
        announceCardNetworkDetection: false,
        announcePaymentProcessing: false,
        useSemanticHeaders: false
    )
}

// MARK: - Configuration Environment Key
@available(iOS 15.0, *)
internal struct CardPaymentConfigurationKey: EnvironmentKey {
    static let defaultValue = PrimerCardPaymentConfiguration.default
}

@available(iOS 15.0, *)
internal extension EnvironmentValues {
    var cardPaymentConfiguration: PrimerCardPaymentConfiguration {
        get { self[CardPaymentConfigurationKey.self] }
        set { self[CardPaymentConfigurationKey.self] = newValue }
    }
}

// MARK: - SwiftUI View Extensions
@available(iOS 15.0, *)
public extension View {
    /// Configures card payment settings for the view hierarchy
    func cardPaymentConfiguration(_ configuration: PrimerCardPaymentConfiguration) -> some View {
        self.environment(\.cardPaymentConfiguration, configuration)
    }
    
    /// Applies card payment animation configuration
    func cardPaymentAnimationConfiguration(_ config: CardPaymentAnimationConfiguration) -> some View {
        self.environment(\.cardPaymentConfiguration, PrimerCardPaymentConfiguration(
            animationConfig: config,
            designConfig: .default,
            features: .default,
            accessibility: .default
        ))
    }
    
    /// Applies card payment feature configuration
    func cardPaymentFeatureConfiguration(_ config: CardPaymentFeatureConfiguration) -> some View {
        self.environment(\.cardPaymentConfiguration, PrimerCardPaymentConfiguration(
            animationConfig: .default,
            designConfig: .default,
            features: config,
            accessibility: .default
        ))
    }
}

// MARK: - Configuration Builder Pattern
@available(iOS 15.0, *)
public class PrimerCardPaymentConfigurationBuilder {
    private var animationConfig = CardPaymentAnimationConfiguration.default
    private var designConfig = CardPaymentDesignConfiguration.default
    private var features = CardPaymentFeatureConfiguration.default
    private var accessibility = CardPaymentAccessibilityConfiguration.default
    
    public init() {}
    
    @discardableResult
    public func withAnimations(_ config: CardPaymentAnimationConfiguration) -> Self {
        self.animationConfig = config
        return self
    }
    
    @discardableResult
    public func withDesign(_ config: CardPaymentDesignConfiguration) -> Self {
        self.designConfig = config
        return self
    }
    
    @discardableResult
    public func withFeatures(_ config: CardPaymentFeatureConfiguration) -> Self {
        self.features = config
        return self
    }
    
    @discardableResult
    public func withAccessibility(_ config: CardPaymentAccessibilityConfiguration) -> Self {
        self.accessibility = config
        return self
    }
    
    @discardableResult
    public func enableAnimations(_ enable: Bool = true) -> Self {
        if enable {
            self.animationConfig = .enhanced
        } else {
            self.animationConfig = .disabled
        }
        return self
    }
    
    @discardableResult
    public func enableCardNetworkIcons(_ enable: Bool = true) -> Self {
        self.features = CardPaymentFeatureConfiguration(
            showCardNetworkIcons: enable,
            enableDynamicCardNetworkDetection: features.enableDynamicCardNetworkDetection,
            showHeaderNavigation: features.showHeaderNavigation,
            enableFormValidation: features.enableFormValidation,
            showFieldLabels: features.showFieldLabels,
            enableHapticFeedback: features.enableHapticFeedback,
            autoAdvanceFields: features.autoAdvanceFields
        )
        return self
    }
    
    @discardableResult
    public func enableAccessibilityEnhancements(_ enable: Bool = true) -> Self {
        if enable {
            self.accessibility = .enhanced
        } else {
            self.accessibility = .minimal
        }
        return self
    }
    
    public func build() -> PrimerCardPaymentConfiguration {
        return PrimerCardPaymentConfiguration(
            animationConfig: animationConfig,
            designConfig: designConfig,
            features: features,
            accessibility: accessibility
        )
    }
}

// MARK: - Convenience Extensions
@available(iOS 15.0, *)
public extension PrimerCardPaymentConfiguration {
    /// Creates a configuration using the builder pattern
    static func build(_ builderBlock: (PrimerCardPaymentConfigurationBuilder) -> Void) -> PrimerCardPaymentConfiguration {
        let builder = PrimerCardPaymentConfigurationBuilder()
        builderBlock(builder)
        return builder.build()
    }
    
    /// Quick configuration for merchants who want minimal setup
    static func simple(
        animations: Bool = true,
        cardNetworkIcons: Bool = true,
        accessibility: Bool = true
    ) -> PrimerCardPaymentConfiguration {
        return build { builder in
            builder
                .enableAnimations(animations)
                .enableCardNetworkIcons(cardNetworkIcons)
                .enableAccessibilityEnhancements(accessibility)
        }
    }
}