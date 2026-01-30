//
//  DefaultBanksComponent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerFoundation

final class DefaultBanksComponent: BanksComponent {

    let paymentMethodType: PrimerPaymentMethodType

    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?

    public internal(set) var nextDataStep: BanksStep = .loading
    private(set) var banks: [IssuingBank] = []
    private(set) var bankId: String?
    private let onFinished: () -> WebRedirectComponent
    private let tokenizationProvidingModel: BankSelectorTokenizationProviding

    init(paymentMethodType: PrimerPaymentMethodType,
         tokenizationProvidingModel: BankSelectorTokenizationProviding,
         onFinished: @escaping () -> WebRedirectComponent) {
        self.paymentMethodType = paymentMethodType
        self.tokenizationProvidingModel = tokenizationProvidingModel
        self.onFinished = onFinished
    }

    public func updateCollectedData(collectableData: BanksCollectableData) {
        trackCollectableData()
        switch collectableData {
        case let .bankId(bankId: bankId):
            if isBankIdValid(bankId: bankId) {
                self.bankId = bankId
            }
        case let .bankFilterText(text: text):
            let filteredBanks = tokenizationProvidingModel.filterBanks(query: text)
            let banksStep = BanksStep.banksRetrieved(banks: filteredBanks.map { IssuingBank(bank: $0) })
            stepDelegate?.didReceiveStep(step: banksStep)
        }
        validateData(for: collectableData)
    }

    func isBankIdValid(bankId: String) -> Bool {
        banks.compactMap(\.id).contains(bankId)
    }

    func validateData(for data: BanksCollectableData) {
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        switch data {
        case let .bankId(bankId: bankId):
            if !isBankIdValid(bankId: bankId) {
                let error = banks.isEmpty ? PrimerValidationError.banksNotLoaded() : PrimerValidationError.invalidBankId(bankId: bankId)
                validationDelegate?.didUpdate(validationStatus: .invalid(errors: [handled(error: error)]), for: data)
            } else {
                validationDelegate?.didUpdate(validationStatus: .valid, for: data)
            }
        case .bankFilterText:
            if banks.isEmpty {
                let error = handled(error: PrimerValidationError.banksNotLoaded())
                validationDelegate?.didUpdate(validationStatus: .invalid(errors: [error]), for: data)
            } else {
                validationDelegate?.didUpdate(validationStatus: .valid, for: data)
            }
        }
    }

    public func start() {
        trackStart()
        stepDelegate?.didReceiveStep(step: BanksStep.loading)
        Task {
            do {
                let banks = try await tokenizationProvidingModel.retrieveListOfBanks()
                self.banks = banks.map(IssuingBank.init)
                let step = BanksStep.banksRetrieved(banks: self.banks)
                self.nextDataStep = step
                self.stepDelegate?.didReceiveStep(step: step)
            } catch {
                ErrorHandler.handle(error: error)
            }
        }
    }

    public func submit() {
        trackSubmit()
        switch nextDataStep {
        case .loading: break
        case .banksRetrieved:
            guard let bankId = self.bankId else { return }
            let redirectComponent = onFinished()
            redirectComponent.start()

            Task {
                do {
                    _ = try await tokenizationProvidingModel.tokenize(bankId: bankId)
                    redirectComponent.didReceiveStep(step: WebStep.loaded)
                } catch {
                    ErrorHandler.handle(error: error)
                }
            }
        }
    }
}

private extension DefaultBanksComponent {
    func trackSubmit() {
        trackEvent(BanksAnalyticsEvent.submit)
    }
    func trackStart() {
        trackEvent(BanksAnalyticsEvent.start)
    }
    func trackCollectableData() {
        trackEvent(BanksAnalyticsEvent.updateCollectedData)
    }
    func trackEvent(_ event: BanksAnalyticsEvent, additionalParams: [String: String]? = nil) {
        var params: [String: String] = ["paymentMethodType": paymentMethodType.rawValue,
                                        "category": PrimerPaymentMethodManagerCategory.componentWithRedirect.rawValue]
        if let additionalParams {
            params.merge(additionalParams) { (_, new) in new }
        }

        let sdkEvent = Analytics.Event.sdk(name: event.rawValue, params: params)
        Analytics.Service.fire(events: [sdkEvent])
    }
}
