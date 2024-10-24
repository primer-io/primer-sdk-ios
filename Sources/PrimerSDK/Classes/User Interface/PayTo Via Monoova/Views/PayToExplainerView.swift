//
//  PayToExplainerView.swift
//  IQKeyboardManagerSwift
//
//  Created by Jack Newcombe on 06/09/2024.
//

import Foundation
import SwiftUI

struct AgreementDetailsTableRow: View {
    let title: String

    let value: String

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .foregroundColor(bodyTextColor)
                    .padding(.bottom, 8)
                Spacer()
                Text(value)
                    .subtitleText(bolded: true)
            }
            .padding(.top, 8)
            Rectangle()
                .frame(height: 0.35)
                .background(bodyTextColor)
        }
    }
}

struct AgreementDetailsTable: View {

    let tableData: [String: String]

    var body: some View {
        VStack {
            ForEach(tableData.keys.map { $0 }, id: \.self) { key in
                AgreementDetailsTableRow(title: key, value: tableData[key]!)
            }
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(bodyTextColor, lineWidth: 0.25)
        )
    }
}

// Root Views

// MARK: PayTo Explainer

struct PayToExplainerView: View {
    var body: some View {
        PayToTitledView(title: "What is PayTo?") {
            Text(PayToStrings.explainerSummary)
                .bodyText()
                .padding(.bottom, 8)
            Text(PayToStrings.explainerSubtitle)
                .subtitleText(bolded: true)
            BulletPointText(text: PayToStrings.explainerPoint1)
            BulletPointText(text: PayToStrings.explainerPoint2)
            BulletPointText(text: PayToStrings.explainerPoint3)
            PrimaryActionButton(text: "Continue") {
                // TOODO: proceed to next screen
                print(".")
            }
        }
    }
}

#Preview("Explainer") {
    PayToExplainerView()
}

// MARK: PayTo Payment Details

struct PayToPaymentDetailsView: View {

    @State var payID: String = ""

    var body: some View {
        PayToTitledView(title: "Pay with PayTo") {
            Text("Payment details")
                .subtitleText(bolded: false)
                .padding(.bottom, 12)
            Text("Select your PayID type").bodyText()
            PickerButton(selection: "1")
                .padding(.bottom, 12)
            Text("Enter your Account Number").bodyText()
            TextField("test", text: $payID)
                .userDetailsControl()
            Text("We’ll only use this to keep you updated about your payment.")
                .bodyText()
            PrimaryActionButton(text: "Continue") {
                // TOODO
            }
        }
    }
}

#Preview("Payment Details") {
    PayToPaymentDetailsView()
}

// MARK: Payment Agreement Review

struct PayToPaymentAgreementReview: View {
    var body: some View {
        PayToTitledView(title: "Payment") {
            Text("Premium Payments")
                .subtitleText()
            CalloutText(text: PayToStrings.paymentAgreementReviewSummary)
            AgreementDetailsTable(tableData: [
                "PayID": "+61 4 1234 5678",
                "PayID Name": "Cameron Smith",
                "Payee": "Health Insurance Co.",
                "Amount": "$150",
                "Payment frequency": "Monthly",
                "Start date": "2 July 2024"
            ])
            PrimaryActionButton(text: "Submit") {
                // TOODO
            }
        }
    }
}

#Preview("Payment Agreement Review") {
    PayToPaymentAgreementReview()
}

// MARK: Payment Approval View

struct PayToPaymentApprovalView: View {
    var body: some View {
        PayToTitledView(title: "One last step in your bank") {
            Text("A PayTo agreement has been sent to your bank")
                .bodyText()
                .padding(.bottom, 8)
            CalloutText(
                text: "Expires in [X] minutes",
                icon: "calendar-icon"
            )
            Text(attributedText.string)
                .bodyText()
            // TOODO: may need to host UITextView to use NSAttributedString
            // TOODO: drop down boxes
            PrimaryActionButton(text: "I have approved the agreement") {
                // TOODO
            }
        }
    }

    var attributedText: NSAttributedString {
        // TOODO: link
        NSAttributedString(string: """
Didn't receive the request? [Resend the request] or double check your bank details.
""")
    }
}

#Preview("Payment Approval") {
    PayToPaymentApprovalView()
}

class PayToStrings {
    static let explainerSummary = "PayTo allows you to make immediate and secure payments directly from your bank account."
    static let explainerSubtitle = "Things you need to know"

    static let explainerPoint1 = "After you click the Pay with PayTo button, your cart will be reserved for {10} minutes."
    static let explainerPoint2 = "To complete your payment, you’ll need to go to your bank app and approve the agreement."
    static let explainerPoint3 = "Once your payment is processed, you’ll receive a confirmation."

    // MARK: Payment Agreement Review

    static let paymentAgreementReviewSummary = """
The PayTo agreement will be sent to your banking app. You will have 10 minutes to authorise the agreement.
"""
}
