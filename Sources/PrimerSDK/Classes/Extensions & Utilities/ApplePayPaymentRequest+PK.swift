//
//  ApplePayPaymentRequest+PK.swift
//
//
//  Created by Semir on 25/03/2025.
//

import PassKit
import Foundation

// MARK: - ApplePayBillingBase to PKRecurringPaymentSummaryItem
@available(iOS 15.0, *)
extension ApplePayBillingBase {

    func toPKRecurringPaymentSummaryItem(
        totalAmount: Int,
        currency: Currency
    ) -> PKRecurringPaymentSummaryItem {
        let formattedAmount = NSDecimalNumber(decimal: totalAmount.formattedCurrencyAmount(currency: currency))
        let summaryItem = PKRecurringPaymentSummaryItem(
            label: self.label,
            amount: formattedAmount
        )

        summaryItem.startDate = self.recurringStartDate
        summaryItem.endDate = self.recurringEndDate

        if let recurringIntervalCount = self.recurringIntervalCount {
            summaryItem.intervalCount = recurringIntervalCount
        }

        if let recurringIntervalUnit = self.recurringIntervalUnit?.nsCalendarUnit {
            summaryItem.intervalUnit = recurringIntervalUnit
        }

        return summaryItem
    }
}

// MARK: - ApplePayRecurringPaymentRequest to PKRecurringPaymentRequest
@available(iOS 16.0, *)
internal extension ApplePayRecurringPaymentRequest {
    func toPKRecurringPaymentRequest(orderAmount: Int?, currency: Currency, descriptor: String?) throws -> PKRecurringPaymentRequest {
        guard let totalAmount = regularBilling.amount ?? orderAmount else {
            let err = PrimerError.invalidValue(key: "regularBilling.amount or amount",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard let paymentDescription = self.paymentDescription ?? descriptor else {
            let err = PrimerError.invalidValue(key: "recurringPaymentRequest.paymentDescription or paymentMethod.descriptor",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        let request = PKRecurringPaymentRequest(
            paymentDescription: paymentDescription,
            regularBilling: self.regularBilling.toPKRecurringPaymentSummaryItem(totalAmount: totalAmount, currency: currency),
            managementURL: URL(string: self.managementURL)!)

        if let trialBilling = self.trialBilling {
            request.trialBilling = trialBilling.toPKRecurringPaymentSummaryItem(totalAmount: trialBilling.amount ?? 0, currency: currency)
        }

        if let tokenManagementUrl = self.tokenManagementUrl {
            request.tokenNotificationURL = URL(string: tokenManagementUrl)
        }
        request.billingAgreement = self.billingAgreement
        return request
    }
}

// MARK: - ApplePayDeferredPaymentRequest to PKDeferredPaymentRequest
@available(iOS 16.4, *)
internal extension ApplePayDeferredPaymentRequest {
    func toPKDeferredPaymentRequest(orderAmount: Int?, currency: Currency, descriptor: String?) throws -> PKDeferredPaymentRequest {
        guard let totalAmount = deferredBilling.amount ?? AppState.current.amount else {
            let err = PrimerError.invalidValue(key: "deferredBilling.amount or amount",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard let paymentDescription = self.paymentDescription ?? descriptor else {
            let err = PrimerError.invalidValue(key: "deferredPaymentRequest.paymentDescription or paymentMethod.descriptor",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        let summaryItem: PKDeferredPaymentSummaryItem = PKDeferredPaymentSummaryItem(
            label: self.deferredBilling.label,
            amount: NSDecimalNumber(decimal: totalAmount.formattedCurrencyAmount(currency: currency))
        )
        summaryItem.deferredDate = self.deferredBilling.deferredPaymentDate

        let request = PKDeferredPaymentRequest(
            paymentDescription: paymentDescription,
            deferredBilling: summaryItem,
            managementURL: URL(string: self.managementURL)!
        )

        if let freeCancellationDate = self.freeCancellationDate {
            request.freeCancellationDate = freeCancellationDate
        }

        if let freeCancellationTimeZone = self.freeCancellationTimeZone {
            request.freeCancellationDateTimeZone = TimeZone(identifier: freeCancellationTimeZone)
        }

        if let tokenManagementUrl = self.tokenManagementUrl {
            request.tokenNotificationURL = URL(string: tokenManagementUrl)
        }
        request.billingAgreement = self.billingAgreement

        return request
    }
}

// MARK: - ApplePayAutomaticReloadRequest to PKAutomaticReloadPaymentRequest
@available(iOS 16.0, *)
internal extension ApplePayAutomaticReloadRequest {
    func toPKAutomaticReloadPaymentRequest(orderAmount: Int?, currency: Currency, descriptor: String?) throws -> PKAutomaticReloadPaymentRequest {
        guard let totalAmount = automaticReloadBilling.amount ?? orderAmount else {
            let err = PrimerError.invalidValue(key: "automaticReloadBilling.amount or amount",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard let paymentDescription = self.paymentDescription ?? descriptor else {
            let err = PrimerError.invalidValue(key: "automaticReloadRequest.paymentDescription or paymentMethod.descriptor",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        let summaryItem: PKAutomaticReloadPaymentSummaryItem = PKAutomaticReloadPaymentSummaryItem(
            label: self.automaticReloadBilling.label,
            amount: NSDecimalNumber(decimal: totalAmount.formattedCurrencyAmount(currency: currency))
        )
        summaryItem.thresholdAmount = NSDecimalNumber(
            decimal: self.automaticReloadBilling.automaticReloadThresholdAmount.formattedCurrencyAmount(currency: currency)
        )

        let request = PKAutomaticReloadPaymentRequest(
            paymentDescription: paymentDescription,
            automaticReloadBilling: summaryItem,
            managementURL: URL(string: self.managementURL)!
        )

        if let tokenManagementUrl = self.tokenManagementUrl {
            request.tokenNotificationURL = URL(string: tokenManagementUrl)
        }
        request.billingAgreement = self.billingAgreement

        return request
    }
}

internal extension ApplePayOptions {
    func updatePKPaymentRequestUpdate(
        _ paymentUpdate: PKPaymentRequestUpdate,
        orderAmount: Int?,
        currency: Currency,
        descriptor: String?
    ) throws {
        if #available(iOS 16.0, *) {
            paymentUpdate.recurringPaymentRequest = try self.recurringPaymentRequest?.toPKRecurringPaymentRequest(
                orderAmount: orderAmount,
                currency: currency,
                descriptor: descriptor
            )
        }

        if #available(iOS 16.0, *) {
            paymentUpdate.automaticReloadPaymentRequest = try self.automaticReloadRequest?.toPKAutomaticReloadPaymentRequest(
                orderAmount: orderAmount,
                currency: currency,
                descriptor: descriptor
            )
        }

        if #available(iOS 16.4, *) {
            paymentUpdate.deferredPaymentRequest = try self.deferredPaymentRequest?.toPKDeferredPaymentRequest(
                orderAmount: orderAmount,
                currency: currency,
                descriptor: descriptor
            )
        }
    }
}
