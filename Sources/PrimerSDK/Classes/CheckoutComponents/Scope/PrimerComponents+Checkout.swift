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

        public let splash: Component?
        public let loading: Component?
        public let success: Component?
        public let error: Error
        public let navigation: Navigation

        /// Creates a checkout configuration.
        /// - Parameters:
        ///   - splash: Custom splash screen shown during SDK initialization. Default: nil (uses SDK default)
        ///   - loading: Custom loading screen shown during loading operations.
        ///   - success: Custom success screen. Default: nil (uses SDK default)
        ///   - error: Error screen configuration. Default: Error()
        ///   - navigation: Navigation callbacks. Default: Navigation()
        public init(
            splash: Component? = nil,
            loading: Component? = nil,
            success: Component? = nil,
            error: Error = Error(),
            navigation: Navigation = Navigation()
        ) {
            self.splash = splash
            self.loading = loading
            self.success = success
            self.error = error
            self.navigation = navigation
        }

        // MARK: - Nested Types

        public struct Error {
            public let title: String?
            public let content: ErrorComponent?

            public init(title: String? = nil, content: ErrorComponent? = nil) {
                self.title = title
                self.content = content
            }
        }

        public struct Navigation {
            public let onCancel: (() -> Void)?
            public let onBack: (() -> Void)?
            public let onRetry: (() -> Void)?
            public let onOtherPaymentMethods: (() -> Void)?
            public let onSuccess: (() -> Void)?
            public let onError: ((_ errorMessage: String) -> Void)?

            /// Creates a navigation configuration.
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
