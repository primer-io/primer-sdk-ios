//
//  PrimerResultPaymentStatusView.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 03.07.2024.
//

import SwiftUI

struct PrimerResultPaymentStatusView: View {
    var status: PrimerCustomResultViewController.PaymentStatus = .success
    var message: String
    
    var body: some View {
        VStack {
            switch status {
            case .success:
                PrimerResultSuccessView()
            case .failed:
                PrimerResultFailedView(
                    errorTitle: "Payment failed",
                    errorMessage: message,
                    onRetry: {
                        print("Retry")
                    },
                    onChooseOtherMethod: {
                        print("Choose other pm")
                    }
                )
            case .canceled:
                PrimerResultFailedView(
                    errorTitle: "Payment cancelled",
                    errorMessage: message,
                    onChooseOtherMethod: {
                        print("Choose other pm")
                    }
                )
            }
        }
    }
}
