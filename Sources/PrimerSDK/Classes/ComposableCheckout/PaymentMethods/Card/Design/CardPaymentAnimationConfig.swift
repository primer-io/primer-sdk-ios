//
//  CardPaymentAnimationConfig.swift
//  PrimerSDK
//
//  Created by Claude Code on 25.03.2025.
//

import SwiftUI

@available(iOS 15.0, *)
internal struct CardPaymentAnimationConfig {
    // MARK: - Animation Durations (configurable)
    static let fieldFocusDuration: Double = 0.2
    static let errorStateDuration: Double = 0.3
    static let buttonPressDuration: Double = 0.1
    static let layoutTransitionDuration: Double = 0.25
    static let cardNetworkIconsEntranceDuration: Double = 0.4
    static let formFieldEntranceDuration: Double = 0.3

    // MARK: - Animation Curves (optimized for performance)
    static let fieldFocusAnimation: Animation = .easeInOut(duration: fieldFocusDuration)
    static let errorStateAnimation: Animation = .easeInOut(duration: errorStateDuration)
    static let buttonPressAnimation: Animation = .easeInOut(duration: buttonPressDuration)
    static let layoutTransition: Animation = .easeInOut(duration: layoutTransitionDuration)
    static let cardNetworkIconsAnimation: Animation = .easeOut(duration: cardNetworkIconsEntranceDuration)
    static let formFieldAnimation: Animation = .easeOut(duration: formFieldEntranceDuration)

    // MARK: - Transform Effects (subtle and performant)
    static let fieldFocusScale: CGFloat = 1.02
    static let buttonPressScale: CGFloat = 0.98
    static let errorShakeOffset: CGFloat = 8.0
    static let iconEntranceScale: CGFloat = 0.8

    // MARK: - Transition Effects
    static let fieldEntranceTransition: AnyTransition = .asymmetric(
        insertion: .move(edge: .top).combined(with: .opacity),
        removal: .opacity
    )

    static let errorTextTransition: AnyTransition = .asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .opacity
    )

    static let iconEntranceTransition: AnyTransition = .asymmetric(
        insertion: .scale(scale: iconEntranceScale).combined(with: .opacity),
        removal: .opacity
    )

    // MARK: - Staggered Animation Delays
    static func iconEntranceDelay(for index: Int) -> Double {
        return Double(index) * 0.05 // 50ms stagger between icons
    }

    static func fieldEntranceDelay(for index: Int) -> Double {
        return Double(index) * 0.08 // 80ms stagger between fields
    }
}

// MARK: - Merchant Configuration for Animations
@available(iOS 15.0, *)
public struct CardPaymentAnimationConfiguration {
    public let enableFieldFocusAnimations: Bool
    public let enableErrorStateAnimations: Bool
    public let enableButtonAnimations: Bool
    public let enableLayoutTransitions: Bool
    public let enableEntranceAnimations: Bool
    public let respectReduceMotion: Bool

    public init(
        enableFieldFocusAnimations: Bool = true,
        enableErrorStateAnimations: Bool = true,
        enableButtonAnimations: Bool = true,
        enableLayoutTransitions: Bool = true,
        enableEntranceAnimations: Bool = true,
        respectReduceMotion: Bool = true
    ) {
        self.enableFieldFocusAnimations = enableFieldFocusAnimations
        self.enableErrorStateAnimations = enableErrorStateAnimations
        self.enableButtonAnimations = enableButtonAnimations
        self.enableLayoutTransitions = enableLayoutTransitions
        self.enableEntranceAnimations = enableEntranceAnimations
        self.respectReduceMotion = respectReduceMotion
    }

    // MARK: - Predefined Configurations
    public static let `default` = CardPaymentAnimationConfiguration()

    public static let minimal = CardPaymentAnimationConfiguration(
        enableFieldFocusAnimations: false,
        enableErrorStateAnimations: true,
        enableButtonAnimations: false,
        enableLayoutTransitions: false,
        enableEntranceAnimations: false,
        respectReduceMotion: true
    )

    public static let disabled = CardPaymentAnimationConfiguration(
        enableFieldFocusAnimations: false,
        enableErrorStateAnimations: false,
        enableButtonAnimations: false,
        enableLayoutTransitions: false,
        enableEntranceAnimations: false,
        respectReduceMotion: true
    )

    public static let enhanced = CardPaymentAnimationConfiguration(
        enableFieldFocusAnimations: true,
        enableErrorStateAnimations: true,
        enableButtonAnimations: true,
        enableLayoutTransitions: true,
        enableEntranceAnimations: true,
        respectReduceMotion: true
    )
}

// MARK: - Animation Utility Functions
@available(iOS 15.0, *)
internal extension CardPaymentAnimationConfiguration {
    /// Checks if animations should be enabled based on system reduce motion setting
    var shouldAnimateWithReduceMotion: Bool {
        if respectReduceMotion {
            return !UIAccessibility.isReduceMotionEnabled
        }
        return true
    }

    /// Returns appropriate animation for field focus based on configuration
    func fieldFocusAnimation() -> Animation? {
        guard enableFieldFocusAnimations && shouldAnimateWithReduceMotion else { return nil }
        return CardPaymentAnimationConfig.fieldFocusAnimation
    }

    /// Returns appropriate animation for error states based on configuration
    func errorStateAnimation() -> Animation? {
        guard enableErrorStateAnimations && shouldAnimateWithReduceMotion else { return nil }
        return CardPaymentAnimationConfig.errorStateAnimation
    }

    /// Returns appropriate animation for button press based on configuration
    func buttonPressAnimation() -> Animation? {
        guard enableButtonAnimations && shouldAnimateWithReduceMotion else { return nil }
        return CardPaymentAnimationConfig.buttonPressAnimation
    }

    /// Returns appropriate animation for layout transitions based on configuration
    func layoutTransitionAnimation() -> Animation? {
        guard enableLayoutTransitions && shouldAnimateWithReduceMotion else { return nil }
        return CardPaymentAnimationConfig.layoutTransition
    }

    /// Returns appropriate animation for entrance effects based on configuration
    func entranceAnimation() -> Animation? {
        guard enableEntranceAnimations && shouldAnimateWithReduceMotion else { return nil }
        return CardPaymentAnimationConfig.cardNetworkIconsAnimation
    }
}

// MARK: - Custom Animation ViewModifiers
@available(iOS 15.0, *)
internal struct CardPaymentFieldFocusModifier: ViewModifier {
    let isFocused: Bool
    let animationConfig: CardPaymentAnimationConfiguration

    func body(content: Content) -> some View {
        content
            .scaleEffect(
                animationConfig.enableFieldFocusAnimations && isFocused ?
                    CardPaymentAnimationConfig.fieldFocusScale : 1.0
            )
            .animation(animationConfig.fieldFocusAnimation(), value: isFocused)
    }
}

@available(iOS 15.0, *)
internal struct CardPaymentButtonPressModifier: ViewModifier {
    let isPressed: Bool
    let animationConfig: CardPaymentAnimationConfiguration

    func body(content: Content) -> some View {
        content
            .scaleEffect(
                animationConfig.enableButtonAnimations && isPressed ?
                    CardPaymentAnimationConfig.buttonPressScale : 1.0
            )
            .animation(animationConfig.buttonPressAnimation(), value: isPressed)
    }
}

// MARK: - View Extensions for Easy Animation Application
@available(iOS 15.0, *)
internal extension View {
    func cardPaymentFieldFocus(isFocused: Bool, config: CardPaymentAnimationConfiguration = .default) -> some View {
        self.modifier(CardPaymentFieldFocusModifier(isFocused: isFocused, animationConfig: config))
    }

    func cardPaymentButtonPress(isPressed: Bool, config: CardPaymentAnimationConfiguration = .default) -> some View {
        self.modifier(CardPaymentButtonPressModifier(isPressed: isPressed, animationConfig: config))
    }

}
