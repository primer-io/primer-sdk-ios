//
//  PrimerResultPaymentStatusViewModel.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 07.07.2024.
//

import SwiftUI

class PrimerResultPaymentStatusViewModel: ObservableObject {

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

        return "Pay with \(paymentMethod)"
    }

    var subtitle: String {
        switch paymentStatus {
        case .success:
            "Payment successful"
        case .failed:
            "Payment failed"
        case .canceled:
            "Payment cancelled"
        }
    }

    var paymentMessage: String {
        return paymentStatus == .success ? successMessage : errorMessage
    }

    private var successMessage: String {
        switch paymentMethodType {
        case .stripeAch:
            return "You have now authorised your bank account to be debited. You will be notified via email once the payment has been collected successfully."
        default:
            return ""
        }
    }

    private var errorMessage: String {
        switch paymentStatus {
        case .failed:
            return error?.plainDescription ?? error.debugDescription
        case .canceled:
            return "Please try again or select another bank"
        default:
            return ""
        }
    }

    private var paymentStatus: PrimerCustomResultViewController.PaymentStatus {
        if let error {
            switch error {
            case .cancelled:
                return .canceled
            default:
                return .failed
            }
        } else {
            return .success
        }
    }

    var showOnRetry: Bool {
        return paymentStatus == .failed
    }

    var showChooseOtherPaymentMethod: Bool {
        return paymentStatus != .success
    }

    var statusIconString: String {
        return paymentStatus == .success ? "checkmark.circle" : "xmark.circle"
    }

    var statusIconColor: Color {
        return paymentStatus == .success ? .blue.opacity(0.8) : .red.opacity(0.8)
    }

    var titleBottomSpacing: CGFloat {
        return paymentStatus == .success ? 20 : 40
    }
    
    var paymentMessageBottomSpacing: CGFloat {
        return paymentStatus == .success ? 60 : 40
    }
}
