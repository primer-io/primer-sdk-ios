//
//  PrimerResultPaymentStatusViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import SwiftUI

final class PrimerResultPaymentStatusViewModel: ObservableObject {

    private var paymentMethodType: PrimerPaymentMethodType
    private var error: PrimerError?

    init(paymentMethodType: PrimerPaymentMethodType, error: PrimerError?) {
        self.paymentMethodType = paymentMethodType
        self.error = error
    }

    var title: String {
        var paymentMethod: String
        switch paymentMethodType {
        case .stripeAch:
            paymentMethod = "ACH"
        default:
            paymentMethod = ""
        }

        return String(format: Strings.ResultView.paymentTitle, paymentMethod)
    }

    var subtitle: String {
        switch paymentStatus {
        case .success:
            return Strings.ResultView.Subtitle.successful
        case .failed:
            return Strings.ResultView.Subtitle.failed
        case .cancelled:
            return Strings.ResultView.Subtitle.cancelled
        }
    }

    var paymentMessage: String {
        paymentStatus == .success ? successMessage : errorMessage
    }

    private var successMessage: String {
        switch paymentMethodType {
        case .stripeAch:
            return Strings.ResultView.successMessage
        default:
            return ""
        }
    }

    private var errorMessage: String {
        switch paymentStatus {
        case .failed:
            return error?.plainDescription ?? error.debugDescription
        case .cancelled:
            return Strings.ResultView.cancelMessage
        default:
            return ""
        }
    }

    private var paymentStatus: PrimerCustomResultViewController.PaymentStatus {
        if let error {
            switch error {
            case .cancelled:
                return .cancelled
            default:
                return .failed
            }
        } else {
            return .success
        }
    }

    var showOnRetry: Bool {
        paymentStatus == .failed
    }

    var showChooseOtherPaymentMethod: Bool {
        paymentStatus != .success
    }

    var statusIconString: String {
        paymentStatus == .success ? "checkmark.circle" : "xmark.circle"
    }

    var statusIconAccessibilityIdentifier: String {
        let successImage = AccessibilityIdentifier.ResultScreen.successImage.rawValue
        let failureImage = AccessibilityIdentifier.ResultScreen.failureImage.rawValue
        return paymentStatus == .success ? successImage : failureImage
    }

    var statusIconColor: Color {
        paymentStatus == .success ? .blue.opacity(0.8) : .red.opacity(0.8)
    }

    var titleBottomSpacing: CGFloat {
        paymentStatus == .success ? 20 : 40
    }

    var paymentMessageBottomSpacing: CGFloat {
        paymentStatus == .success ? 60 : 40
    }
}
