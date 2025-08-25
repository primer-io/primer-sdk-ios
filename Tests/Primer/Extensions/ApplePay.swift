//
//  ApplePay.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if DEBUG
import XCTest
import PassKit
@testable import PrimerSDK

@available(iOS 16.4, *)
extension ApplePayAutomaticReloadRequest {
    init(description: String?, amount: Int?, managementUrl: String = "https://example.com") {
        self.init(
            paymentDescription: description,
            billingAgreement: nil,
            managementUrl: managementUrl,
            automaticReloadBilling: ApplePayAutomaticReloadBillingOption(
                label: "Reload Item",
                amount: amount,
                automaticReloadThresholdAmount: 0
            ),
            tokenManagementUrl: nil
        )
    }
    
    func toPK() throws -> PKAutomaticReloadPaymentRequest {
        try toPKAutomaticReloadPaymentRequest(
            orderAmount: nil,
            currency: Currency(code: "USD", decimalDigits: 2),
            descriptor: nil
        )
    }
}

@available(iOS 16.4, *)
extension ApplePayDeferredPaymentRequest {
    init(description: String?, amount: Int?) {
        self.init(
            paymentDescription: description,
            billingAgreement: nil,
            managementUrl: "https://example.com",
            deferredBilling: ApplePayDeferredBillingOption(
                label: "Deferred Item",
                amount: amount,
                deferredPaymentDate: Date().timeIntervalSince1970
            ),
            freeCancellationDate: nil,
            freeCancellationTimeZone: nil,
            tokenManagementUrl: nil
        )
    }
    
    func toPK() throws -> PKDeferredPaymentRequest {
        try toPKDeferredPaymentRequest(
            orderAmount: nil,
            currency: Currency(code: "USD", decimalDigits: 2),
            descriptor: nil
        )
    }
}

@available(iOS 16.4, *)
extension ApplePayRecurringPaymentRequest {
    init(
        description: String?,
        amount: Int?,
        managementUrl: String = "https://example.com"
    ) {
        self.init(
            paymentDescription: description,
            billingAgreement: "Agreement123",
            managementUrl: managementUrl,
            regularBilling: ApplePayRegularBillingOption(label: "Test Billing", amount: amount),
            trialBilling: nil,
            tokenManagementUrl: nil
        )
    }
    
    func toPK() throws -> PKRecurringPaymentRequest {
        try toPKRecurringPaymentRequest(
            orderAmount: nil,
            currency: Currency(code: "USD", decimalDigits: 2),
            descriptor: nil
        )
    }
}

extension ApplePayRegularBillingOption {
    init(label: String, amount: Int?) {
        self.init(
            label: label,
            amount: amount,
            recurringStartDate: Date().timeIntervalSince1970,
            recurringEndDate: nil,
            recurringIntervalUnit: .month,
            recurringIntervalCount: 1
        )
    }
}

@available(iOS 16.4, *)
extension ApplePayTrialBillingOption {
    init() {
        self.init(
            label: "Trial Plan",
            amount: 0,
            recurringStartDate: Date().timeIntervalSince1970,
            recurringEndDate: Date().timeIntervalSince1970,
            recurringIntervalUnit: .month,
            recurringIntervalCount: 1
        )
    }
    
    func toPK() throws -> PKRecurringPaymentSummaryItem {
        toPKRecurringPaymentSummaryItem(
            totalAmount: 0,
            currency: Currency(code: "USD", decimalDigits: 2)
        )
    }
}

extension ApplePayOptions {
    init(merchantName: String?) {
        self.init(
            merchantName: merchantName,
            recurringPaymentRequest: nil,
            deferredPaymentRequest: nil,
            automaticReloadRequest: nil
        )
    }
}
#endif
