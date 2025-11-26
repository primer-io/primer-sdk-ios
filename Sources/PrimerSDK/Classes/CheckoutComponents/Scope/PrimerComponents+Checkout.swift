//
//  PrimerComponents+Checkout.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - PrimerComponents.Checkout

@available(iOS 15.0, *)
extension PrimerComponents {

    /// Configuration for checkout flow screens and navigation.
    public struct Checkout {

        /// Custom splash screen component shown during initialization and loading.
        public let splash: Component?

        /// Custom success screen component
        public let success: Component?

        /// Error screen configuration
        public let error: Error

        /// Navigation callback overrides
        public let navigation: Navigation

        /// Creates a new checkout configuration.
        /// - Parameters:
        ///   - splash: Custom splash screen shown during initialization and loading. Default: nil (uses SDK default)
        ///   - success: Custom success screen. Default: nil (uses SDK default)
        ///   - error: Error screen configuration. Default: Error()
        ///   - navigation: Navigation callbacks. Default: Navigation()
        public init(
            splash: Component? = nil,
            success: Component? = nil,
            error: Error = Error(),
            navigation: Navigation = Navigation()
        ) {
            self.splash = splash
            self.success = success
            self.error = error
            self.navigation = navigation
        }

        // MARK: - Nested Types

        /// Error screen configuration
        public struct Error {
            /// Custom error title (nil uses default)
            public let title: String?

            /// Custom error content component
            public let content: ErrorComponent?

            /// Creates a new error configuration.
            /// - Parameters:
            ///   - title: Custom title. Default: nil (uses SDK default)
            ///   - content: Custom error content. Default: nil (uses SDK default)
            public init(title: String? = nil, content: ErrorComponent? = nil) {
                self.title = title
                self.content = content
            }
        }

        /// Navigation callback overrides for checkout flow
        public struct Navigation {
            /// Called when user cancels checkout
            public let onCancel: (() -> Void)?

            /// Called when user navigates back
            public let onBack: (() -> Void)?

            /// Called when user retries after error
            public let onRetry: (() -> Void)?

            /// Called when user selects "other payment methods"
            public let onOtherPaymentMethods: (() -> Void)?

            /// Called when payment succeeds
            public let onSuccess: (() -> Void)?

            /// Called when payment fails
            /// - Parameter errorMessage: The error message describing what went wrong
            public let onError: ((_ errorMessage: String) -> Void)?

            /// Creates a new navigation configuration.
            /// - Parameters:
            ///   - onCancel: Cancel callback. Default: nil (uses SDK default)
            ///   - onBack: Back callback. Default: nil (uses SDK default)
            ///   - onRetry: Retry callback. Default: nil (uses SDK default)
            ///   - onOtherPaymentMethods: Other methods callback. Default: nil (uses SDK default)
            ///   - onSuccess: Success callback. Default: nil (uses SDK default)
            ///   - onError: Error callback. Default: nil (uses SDK default)
            public init(
                onCancel: (() -> Void)? = nil,
                onBack: (() -> Void)? = nil,
                onRetry: (() -> Void)? = nil,
                onOtherPaymentMethods: (() -> Void)? = nil,
                onSuccess: (() -> Void)? = nil,
                onError: ((_ errorMessage: String) -> Void)? = nil
            ) {
                self.onCancel = onCancel
                self.onBack = onBack
                self.onRetry = onRetry
                self.onOtherPaymentMethods = onOtherPaymentMethods
                self.onSuccess = onSuccess
                self.onError = onError
            }
        }
    }
}
