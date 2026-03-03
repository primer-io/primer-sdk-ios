//
//  PrimerResultPaymentStatusViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerUI
import SwiftUI

final class PrimerResultPaymentStatusViewModel: ObservableObject {

    private var paymentMethodType: PrimerPaymentMethodType
    private var error: PrimerError?

    init(paymentMethodType: PrimerPaymentMethodType, error: PrimerError?) {
        self.paymentMethodType = paymentMethodType
        self.error = error
    }

    var title: String {
        var paymentMethod: String = switch paymentMethodType {
        case .stripeAch:
            "ACH"
        default:
            ""
        }

        return String(format: Strings.ResultView.paymentTitle, paymentMethod)
    }

    var subtitle: String {
        switch paymentStatus {
        case .success:
            Strings.ResultView.Subtitle.successful
        case .failed:
            Strings.ResultView.Subtitle.failed
        case .cancelled:
            Strings.ResultView.Subtitle.cancelled
        }
    }

    var paymentMessage: String {
        paymentStatus == .success ? successMessage : errorMessage
    }

    private var successMessage: String {
        switch paymentMethodType {
        case .stripeAch:
            Strings.ResultView.successMessage
        default:
            ""
        }
    }

    private var errorMessage: String {
        switch paymentStatus {
        case .failed:
            error?.plainDescription ?? error.debugDescription
        case .cancelled:
            Strings.ResultView.cancelMessage
        default:
            ""
        }
    }

    private var paymentStatus: PrimerCustomResultViewController.PaymentStatus {
        if let error {
            switch error {
            case .cancelled:
                .cancelled
            default:
                .failed
            }
        } else {
            .success
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
