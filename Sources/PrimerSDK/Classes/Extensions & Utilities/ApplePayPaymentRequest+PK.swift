import PassKit

@available(iOS 15.0, *)
extension ApplePayBillingBase {
    func toPKRecurringPaymentSummaryItem(totalAmount: Int, currency: Currency) -> PKRecurringPaymentSummaryItem {
        let formattedAmount = NSDecimalNumber(decimal: totalAmount.formattedCurrencyAmount(currency: currency))
        let summaryItem = PKRecurringPaymentSummaryItem(label: label, amount: formattedAmount)

        summaryItem.startDate = recurringStartDate.flatMap(Date.init(timeIntervalSince1970:))
        summaryItem.endDate = recurringEndDate.flatMap(Date.init(timeIntervalSince1970:))
        summaryItem.intervalCount = recurringIntervalCount ?? summaryItem.intervalCount
        summaryItem.intervalUnit = recurringIntervalUnit?.nsCalendarUnit ?? summaryItem.intervalUnit

        return summaryItem
    }
}

@available(iOS 16.0, *)
extension ApplePayRecurringPaymentRequest {
    func toPKRecurringPaymentRequest(
        orderAmount: Int?,
        currency: Currency,
        descriptor: String?
    ) throws -> PKRecurringPaymentRequest {
        guard let totalAmount = regularBilling.amount ?? orderAmount else { throw handledError(.regularBillingAmount) }
        guard let paymentDescription = paymentDescription ?? descriptor else { throw handledError(.recurringPaymentMissingDescription) }
        guard let managementURL = URL(string: managementUrl) else { throw handledError(.recurringPaymentInvalidManagementUrl) }

        let summaryItem = regularBilling.toPKRecurringPaymentSummaryItem(totalAmount: totalAmount, currency: currency)

        let request = PKRecurringPaymentRequest(
            paymentDescription: paymentDescription,
            regularBilling: summaryItem,
            managementURL: managementURL
        )

        request.trialBilling = trialBilling?.toPKRecurringPaymentSummaryItem(totalAmount: trialBilling?.amount ?? 0, currency: currency)
        tokenManagementUrl.map { request.tokenNotificationURL = URL(string: $0) }
        request.billingAgreement = billingAgreement

        return request
    }
}

@available(iOS 16.4, *)
extension ApplePayDeferredPaymentRequest {
    func toPKDeferredPaymentRequest(
        orderAmount: Int?,
        currency: Currency,
        descriptor: String?
    ) throws -> PKDeferredPaymentRequest {
        guard let totalAmount = deferredBilling.amount ?? AppState.current.amount else {  throw handledError(.deferredBillingAmount) }
        guard let paymentDescription = paymentDescription ?? descriptor else { throw handledError(.deferredPaymentMissingDescription) }
        guard let managementURL = URL(string: managementUrl) else { throw handledError(.deferredPaymentInvalidManagementUrl) }

        let summaryItem = PKDeferredPaymentSummaryItem(
            label: deferredBilling.label,
            amount: NSDecimalNumber(decimal: totalAmount.formattedCurrencyAmount(currency: currency))
        )
        summaryItem.deferredDate = Date(timeIntervalSince1970: deferredBilling.deferredPaymentDate)

        let request = PKDeferredPaymentRequest(
            paymentDescription: paymentDescription,
            deferredBilling: summaryItem,
            managementURL: managementURL
        )

        request.freeCancellationDate = freeCancellationDate.flatMap(Date.init(timeIntervalSince1970:))
        freeCancellationTimeZone.map { request.freeCancellationDateTimeZone = TimeZone(identifier: $0) }
        tokenManagementUrl.map { request.tokenNotificationURL = URL(string: $0) }
        request.billingAgreement = billingAgreement

        return request
    }
}

@available(iOS 16.0, *)
extension ApplePayAutomaticReloadRequest {
    func toPKAutomaticReloadPaymentRequest(
        orderAmount: Int?,
        currency: Currency,
        descriptor: String?
    ) throws -> PKAutomaticReloadPaymentRequest {
        guard let totalAmount = automaticReloadBilling.amount ?? orderAmount else { throw handledError(.automaticReloadBillingAmount) }
        guard let paymentDescription = paymentDescription ?? descriptor else { throw handledError(.automaticReloadMissingDescription) }
        guard let managementURL = URL(string: managementUrl) else { throw handledError(.automaticReloadInvalidManagementUrl) }

        let summaryItem = PKAutomaticReloadPaymentSummaryItem(
            label: automaticReloadBilling.label,
            amount: NSDecimalNumber(decimal: totalAmount.formattedCurrencyAmount(currency: currency))
        )

        let decimal = automaticReloadBilling.automaticReloadThresholdAmount.formattedCurrencyAmount(currency: currency)
        summaryItem.thresholdAmount = NSDecimalNumber(decimal: decimal)

        let request = PKAutomaticReloadPaymentRequest(
            paymentDescription: paymentDescription,
            automaticReloadBilling: summaryItem,
            managementURL: managementURL
        )

        tokenManagementUrl.map { request.tokenNotificationURL = URL(string: $0) }
        request.billingAgreement = billingAgreement

        return request
    }
}

extension ApplePayOptions {
    func updatePKPaymentRequestUpdate(
        _ paymentUpdate: PKPaymentRequestUpdate,
        orderAmount: Int?,
        currency: Currency,
        descriptor: String?
    ) throws {
        if #available(iOS 16.0, *) {
            paymentUpdate.recurringPaymentRequest = try recurringPaymentRequest?.toPKRecurringPaymentRequest(
                orderAmount: orderAmount,
                currency: currency,
                descriptor: descriptor
            )

            paymentUpdate.automaticReloadPaymentRequest = try automaticReloadRequest?.toPKAutomaticReloadPaymentRequest(
                orderAmount: orderAmount,
                currency: currency,
                descriptor: descriptor
            )
        }

        if #available(iOS 16.4, *) {
            paymentUpdate.deferredPaymentRequest = try deferredPaymentRequest?.toPKDeferredPaymentRequest(
                orderAmount: orderAmount,
                currency: currency,
                descriptor: descriptor
            )
        }
    }
}

private extension String {
    static let regularBillingAmount = "regularBilling.amount or amount"
    static let recurringPaymentMissingDescription = "recurringPaymentRequest.paymentDescription or paymentMethod.descriptor"
    static let recurringPaymentInvalidManagementUrl = "recurringPaymentRequest.managementUrl"
    static let deferredBillingAmount = "deferredBilling.amount or amount"
    static let deferredPaymentMissingDescription = "deferredPaymentRequest.paymentDescription or paymentMethod.descriptor"
    static let deferredPaymentInvalidManagementUrl = "deferredPaymentRequest.managementUrl"
    static let automaticReloadBillingAmount = "automaticReloadBilling.amount or amount"
    static let automaticReloadMissingDescription = "automaticReloadRequest.paymentDescription or paymentMethod.descriptor"
    static let automaticReloadInvalidManagementUrl = "automaticReloadRequest.managementUrl"
}

private extension ApplePayPaymentRequestBase {
    func handledError(_ key: String) -> PrimerError {
        let error: PrimerError = .invalidValue(
            key: key,
            value: nil,
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
}
