//
//  NavigationAnimationConfig.swift
//  PrimerSDK
//
//  Created by Boris Nikolic on 24.12.2025.
//

import SwiftUI

@available(iOS 15.0, *)
internal struct NavigationAnimationConfig {
    // MARK: - Animation Durations (configurable)
    static let screenTransitionDuration: Double = 0.4
    static let modalPresentationDuration: Double = 0.5
    static let splashFadeOutDuration: Double = 0.3
    static let resultScreenEntranceDuration: Double = 0.6
    static let loadingIndicatorDuration: Double = 0.8
    
    // MARK: - Animation Curves (optimized for natural feel)
    static let screenTransitionAnimation: Animation = .easeInOut(duration: screenTransitionDuration)
    static let modalPresentationAnimation: Animation = .spring(response: 0.6, dampingFraction: 0.8)
    static let splashAnimation: Animation = .easeOut(duration: splashFadeOutDuration)
    static let resultEntranceAnimation: Animation = .spring(response: 0.7, dampingFraction: 0.75)
    static let loadingAnimation: Animation = .easeInOut(duration: loadingIndicatorDuration).repeatForever(autoreverses: false)
    
    // MARK: - Transform Effects (subtle and performant)
    static let screenEntranceScale: CGFloat = 0.96
    static let modalEntranceScale: CGFloat = 0.94
    static let resultIconBounceScale: CGFloat = 1.15
    static let loadingIndicatorScale: CGFloat = 1.2
    
    // MARK: - Navigation Transition Effects
    static let forwardNavigationTransition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity.animation(.easeOut(duration: 0.2))),
        removal: .move(edge: .leading).combined(with: .opacity.animation(.easeIn(duration: 0.2)))
    )
    
    static let backNavigationTransition: AnyTransition = .asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity.animation(.easeOut(duration: 0.2))),
        removal: .move(edge: .trailing).combined(with: .opacity.animation(.easeIn(duration: 0.2)))
    )
    
    static let modalTransition: AnyTransition = .asymmetric(
        insertion: .scale(scale: modalEntranceScale).combined(with: .opacity),
        removal: .scale(scale: 0.8).combined(with: .opacity)
    )
    
    static let splashTransition: AnyTransition = .opacity.animation(splashAnimation)
    
    static let resultScreenTransition: AnyTransition = .asymmetric(
        insertion: .scale(scale: screenEntranceScale).combined(with: .opacity),
        removal: .opacity
    )
    
    // MARK: - Loading States
    static let loadingSpinnerTransition: AnyTransition = .scale.combined(with: .opacity)
    
    // MARK: - Staggered Animation Delays
    static func paymentMethodEntranceDelay(for index: Int) -> Double {
        return Double(index) * 0.1 // 100ms stagger between payment methods
    }
    
    static func resultElementEntranceDelay(for index: Int) -> Double {
        return Double(index) * 0.15 // 150ms stagger between result elements
    }
    
    static func formFieldEntranceDelay(for index: Int) -> Double {
        return Double(index) * 0.08 // 80ms stagger between form fields
    }
}

// MARK: - Merchant Configuration for Navigation Animations
@available(iOS 15.0, *)
public struct NavigationAnimationConfiguration {
    public let enableScreenTransitions: Bool
    public let enableModalAnimations: Bool
    public let enableLoadingAnimations: Bool
    public let enableResultAnimations: Bool
    public let enableEntranceAnimations: Bool
    public let enableStaggeredAnimations: Bool
    public let respectReduceMotion: Bool
    public let customTransitionDuration: Double?
    
    public init(
        enableScreenTransitions: Bool = true,
        enableModalAnimations: Bool = true,
        enableLoadingAnimations: Bool = true,
        enableResultAnimations: Bool = true,
        enableEntranceAnimations: Bool = true,
        enableStaggeredAnimations: Bool = true,
        respectReduceMotion: Bool = true,
        customTransitionDuration: Double? = nil
    ) {
        self.enableScreenTransitions = enableScreenTransitions
        self.enableModalAnimations = enableModalAnimations
        self.enableLoadingAnimations = enableLoadingAnimations
        self.enableResultAnimations = enableResultAnimations
        self.enableEntranceAnimations = enableEntranceAnimations
        self.enableStaggeredAnimations = enableStaggeredAnimations
        self.respectReduceMotion = respectReduceMotion
        self.customTransitionDuration = customTransitionDuration
    }
    
    // MARK: - Predefined Configurations
    public static let `default` = NavigationAnimationConfiguration()
    
    public static let minimal = NavigationAnimationConfiguration(
        enableScreenTransitions: true,
        enableModalAnimations: false,
        enableLoadingAnimations: true,
        enableResultAnimations: false,
        enableEntranceAnimations: false,
        enableStaggeredAnimations: false,
        respectReduceMotion: true
    )
    
    public static let disabled = NavigationAnimationConfiguration(
        enableScreenTransitions: false,
        enableModalAnimations: false,
        enableLoadingAnimations: false,
        enableResultAnimations: false,
        enableEntranceAnimations: false,
        enableStaggeredAnimations: false,
        respectReduceMotion: true
    )
    
    public static let enhanced = NavigationAnimationConfiguration(
        enableScreenTransitions: true,
        enableModalAnimations: true,
        enableLoadingAnimations: true,
        enableResultAnimations: true,
        enableEntranceAnimations: true,
        enableStaggeredAnimations: true,
        respectReduceMotion: true,
        customTransitionDuration: 0.5
    )
    
    public static let fast = NavigationAnimationConfiguration(
        enableScreenTransitions: true,
        enableModalAnimations: true,
        enableLoadingAnimations: true,
        enableResultAnimations: true,
        enableEntranceAnimations: true,
        enableStaggeredAnimations: false,
        respectReduceMotion: true,
        customTransitionDuration: 0.25
    )
}

// MARK: - Animation Utility Functions
@available(iOS 15.0, *)
internal extension NavigationAnimationConfiguration {
    /// Checks if animations should be enabled based on system reduce motion setting
    var shouldAnimateWithReduceMotion: Bool {
        if respectReduceMotion {
            return !UIAccessibility.isReduceMotionEnabled
        }
        return true
    }
    
    /// Returns appropriate animation for screen transitions based on configuration
    func screenTransitionAnimation() -> Animation? {
        guard enableScreenTransitions && shouldAnimateWithReduceMotion else { return nil }
        
        if let customDuration = customTransitionDuration {
            return .easeInOut(duration: customDuration)
        }
        return NavigationAnimationConfig.screenTransitionAnimation
    }
    
    /// Returns appropriate animation for modal presentations based on configuration
    func modalPresentationAnimation() -> Animation? {
        guard enableModalAnimations && shouldAnimateWithReduceMotion else { return nil }
        return NavigationAnimationConfig.modalPresentationAnimation
    }
    
    /// Returns appropriate animation for loading states based on configuration
    func loadingAnimation() -> Animation? {
        guard enableLoadingAnimations && shouldAnimateWithReduceMotion else { return nil }
        return NavigationAnimationConfig.loadingAnimation
    }
    
    /// Returns appropriate animation for result screens based on configuration
    func resultAnimation() -> Animation? {
        guard enableResultAnimations && shouldAnimateWithReduceMotion else { return nil }
        return NavigationAnimationConfig.resultEntranceAnimation
    }
    
    /// Returns appropriate animation for entrance effects based on configuration
    func entranceAnimation() -> Animation? {
        guard enableEntranceAnimations && shouldAnimateWithReduceMotion else { return nil }
        
        if let customDuration = customTransitionDuration {
            return .easeOut(duration: customDuration * 0.8)
        }
        return NavigationAnimationConfig.splashAnimation
    }
    
    /// Returns staggered delay if enabled
    func staggeredDelay(for index: Int, baseDelay: Double) -> Double {
        guard enableStaggeredAnimations && shouldAnimateWithReduceMotion else { return 0 }
        return baseDelay * Double(index)
    }
}

// MARK: - Route-Specific Transition Logic
@available(iOS 15.0, *)
internal extension NavigationAnimationConfiguration {
    /// Returns appropriate transition for navigation between specific routes
    func transition(from: CheckoutRoute, to: CheckoutRoute) -> AnyTransition {
        guard shouldAnimateWithReduceMotion && enableScreenTransitions else {
            return .identity
        }
        
        // Determine if this is forward or backward navigation
        let isForwardNavigation = isForwardTransition(from: from, to: to)
        
        switch to {
        case .splash:
            return NavigationAnimationConfig.splashTransition
        case .success, .failure:
            return enableResultAnimations ? 
                NavigationAnimationConfig.resultScreenTransition : 
                NavigationAnimationConfig.forwardNavigationTransition
        default:
            return isForwardNavigation ? 
                NavigationAnimationConfig.forwardNavigationTransition : 
                NavigationAnimationConfig.backNavigationTransition
        }
    }
    
    /// Determines if transition is forward in the navigation flow
    private func isForwardTransition(from: CheckoutRoute, to: CheckoutRoute) -> Bool {
        let routeOrder: [CheckoutRoute.Type] = [
            CheckoutRoute.self, // splash
            CheckoutRoute.self, // paymentMethodsList
            CheckoutRoute.self, // paymentMethod
            CheckoutRoute.self  // success/failure
        ]
        
        // Simple heuristic: if going to success/failure, it's forward
        // if going to splash, it's backward (or reset)
        switch (from, to) {
        case (_, .success), (_, .failure):
            return true
        case (_, .splash):
            return false
        case (.splash, .paymentMethodsList):
            return true
        case (.paymentMethodsList, .paymentMethod):
            return true
        case (.paymentMethod, .paymentMethodsList):
            return false
        default:
            return true
        }
    }
}

// MARK: - Custom Animation ViewModifiers
@available(iOS 15.0, *)
internal struct NavigationScreenTransitionModifier: ViewModifier {
    let currentRoute: CheckoutRoute
    let animationConfig: NavigationAnimationConfiguration
    
    func body(content: Content) -> some View {
        content
            .animation(animationConfig.screenTransitionAnimation(), value: currentRoute.id)
    }
}

@available(iOS 15.0, *)
internal struct NavigationEntranceModifier: ViewModifier {
    let isVisible: Bool
    let animationConfig: NavigationAnimationConfiguration
    let delay: Double
    
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared ? 1 : NavigationAnimationConfig.screenEntranceScale)
            .onAppear {
                guard animationConfig.enableEntranceAnimations && animationConfig.shouldAnimateWithReduceMotion else {
                    hasAppeared = true
                    return
                }
                
                withAnimation(animationConfig.entranceAnimation()?.delay(delay)) {
                    hasAppeared = true
                }
            }
            .onDisappear {
                hasAppeared = false
            }
    }
}

@available(iOS 15.0, *)
internal struct NavigationLoadingModifier: ViewModifier {
    let isLoading: Bool
    let animationConfig: NavigationAnimationConfiguration
    
    @State private var rotationAngle: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotationAngle))
            .onAppear {
                guard animationConfig.enableLoadingAnimations && animationConfig.shouldAnimateWithReduceMotion else {
                    return
                }
                
                withAnimation(animationConfig.loadingAnimation()) {
                    rotationAngle = 360
                }
            }
    }
}

@available(iOS 15.0, *)
internal struct NavigationResultBounceModifier: ViewModifier {
    let isSuccess: Bool
    let animationConfig: NavigationAnimationConfiguration
    
    @State private var bounceScale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(bounceScale)
            .onAppear {
                guard animationConfig.enableResultAnimations && animationConfig.shouldAnimateWithReduceMotion else {
                    return
                }
                
                withAnimation(animationConfig.resultAnimation()) {
                    bounceScale = NavigationAnimationConfig.resultIconBounceScale
                }
                
                withAnimation(animationConfig.resultAnimation()?.delay(0.1)) {
                    bounceScale = 1.0
                }
            }
    }
}

// MARK: - View Extensions for Easy Animation Application
@available(iOS 15.0, *)
internal extension View {
    func navigationScreenTransition(currentRoute: CheckoutRoute, config: NavigationAnimationConfiguration = .default) -> some View {
        self.modifier(NavigationScreenTransitionModifier(currentRoute: currentRoute, animationConfig: config))
    }
    
    func navigationEntrance(isVisible: Bool = true, delay: Double = 0, config: NavigationAnimationConfiguration = .default) -> some View {
        self.modifier(NavigationEntranceModifier(isVisible: isVisible, animationConfig: config, delay: delay))
    }
    
    func navigationLoading(isLoading: Bool, config: NavigationAnimationConfiguration = .default) -> some View {
        self.modifier(NavigationLoadingModifier(isLoading: isLoading, animationConfig: config))
    }
    
    func navigationResultBounce(isSuccess: Bool, config: NavigationAnimationConfiguration = .default) -> some View {
        self.modifier(NavigationResultBounceModifier(isSuccess: isSuccess, animationConfig: config))
    }
}