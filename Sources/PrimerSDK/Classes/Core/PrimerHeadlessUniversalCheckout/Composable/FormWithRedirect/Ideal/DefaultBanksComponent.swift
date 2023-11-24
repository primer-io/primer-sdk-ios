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
        validateData(for: collectableData)
        switch collectableData {
        case .bankId(bankId: let bankId):
            self.bankId = bankId
            if isBankIdValid(bankId: bankId) {
                let redirectComponent = onFinished()
                redirectComponent.start()
                tokenizationProvingModel.tokenize(bankId: bankId)
                    .done { model in
                        redirectComponent.didReceiveStep(step: WebStep.loaded)
                }.catch { errror in
                    print("Error")
                }
            }
        case .bankFilterText(text: let text):
            let filteredBanks = tokenizationProvingModel.filterBanks(query: text)
            stepDelegate?.didReceiveStep(step: BanksStep.banksRetrieved(banks: filteredBanks.map { IssuingBank(bank: $0) }))
        }
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
        case .bankFilterText(text: _):
            if banks.isEmpty {
                let error = PrimerValidationError.banksNotLoaded(
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
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
                self.stepDelegate?.didReceiveStep(step: BanksStep.banksRetrieved(banks: self.banks))
            }.catch { errror in
                print("Error")
            }
    }
    
    public func submit() {
        trackSubmit()
        switch nextDataStep {
        case .loading: break
        case .banksRetrieved(banks: _): break
        }
    }

    public func cancel() {
        tokenizationProvingModel.cancel()
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
        var params: [String: String] = ["category": paymentMethodType.rawValue]
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
