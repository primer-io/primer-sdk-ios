//
//  IdealComponent.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 06.11.2023.
//

import Foundation

final class DefaultBanksComponent: BanksComponent {

    let paymentMethodType: PrimerPaymentMethodType
    
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?

    public internal(set) var nextDataStep: BanksStep = .loading
    private(set) var banks: [IssuingBank] = []
    private(set) var bankId: String?
    private let onFinished: () -> WebRedirectComponent
    private let tokenizationProvingModel: BankSelectorTokenizationProviding

    init(paymentMethodType: PrimerPaymentMethodType, tokenizationProvingModel: BankSelectorTokenizationProviding, onFinished: @escaping () -> WebRedirectComponent) {
        self.paymentMethodType = paymentMethodType
        self.tokenizationProvingModel = tokenizationProvingModel
        self.onFinished = onFinished
    }
    
    public func updateCollectedData(collectableData: BanksCollectableData) {
        trackCollectableData()
        switch collectableData {
        case .bankId(bankId: let bankId):
            if isBankIdValid(bankId: bankId) {
                self.bankId = bankId
            }
        case .bankFilterText(text: let text):
            let filteredBanks = tokenizationProvingModel.filterBanks(query: text)
            stepDelegate?.didReceiveStep(step: BanksStep.banksRetrieved(banks: filteredBanks.map { IssuingBank(bank: $0) }))
        }
        validateData(for: collectableData)
    }

    func isBankIdValid(bankId: String) -> Bool {
        banks.compactMap({ $0.id }).contains(bankId)
    }
    
    func validateData(for data: BanksCollectableData) {
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        switch data {
        case .bankId(bankId: let bankId):
            if !isBankIdValid(bankId: bankId) {
                let userInfo = [
                    "file": #file,
                    "class": "\(Self.self)",
                    "function": #function,
                    "line": "\(#line)"
                ]
                let error = banks.isEmpty ? PrimerValidationError.banksNotLoaded(
                    userInfo: userInfo,
                    diagnosticsId: UUID().uuidString) :
                    PrimerValidationError.invalidBankId(
                    bankId: bankId,
                    userInfo: userInfo,
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: error)
                validationDelegate?.didUpdate(validationStatus: .invalid(errors: [error]), for: data)
            } else {
                validationDelegate?.didUpdate(validationStatus: .valid, for: data)
            }
        case .bankFilterText(text: let text):
            if banks.isEmpty {
                let error = PrimerValidationError.banksNotLoaded(
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)",
                        "text": text
                    ],
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: error)
                validationDelegate?.didUpdate(validationStatus: .invalid(errors: [error]), for: data)
            } else {
                validationDelegate?.didUpdate(validationStatus: .valid, for: data)
            }
        }
    }

    public func start() {
        trackStart()
        stepDelegate?.didReceiveStep(step: BanksStep.loading)
        tokenizationProvingModel.retrieveListOfBanks()
            .done { banks -> Void in
                self.banks = banks.map { IssuingBank(bank: $0) }
                let step = BanksStep.banksRetrieved(banks: self.banks)
                self.nextDataStep = step
                self.stepDelegate?.didReceiveStep(step: step)
            }.catch { error in
                ErrorHandler.handle(error: error)
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
            tokenizationProvingModel.tokenize(bankId: bankId)
                .done { _ in
                    redirectComponent.didReceiveStep(step: WebStep.loaded)
            }.catch { error in
                ErrorHandler.handle(error: error)
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
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: event.rawValue,
                params: params))
        Analytics.Service.record(events: [sdkEvent])
    }
}
