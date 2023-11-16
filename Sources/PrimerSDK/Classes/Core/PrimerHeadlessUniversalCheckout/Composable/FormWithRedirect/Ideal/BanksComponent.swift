//
//  IdealComponent.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 06.11.2023.
//

import Foundation

public enum BanksCollectableData: FormCollectableData {
    case bankId(bankId: String)
    case bankFilterText(text: String)
}

public class BanksComponent: PrimerHeadlessFormComponent {

    public typealias T = BanksCollectableData
    let paymentMethodType: PrimerPaymentMethodType
    
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?

    public private(set) var nextDataStep: BanksStep = .loading
    private(set) var banks: [IssuingBank] = []
    private(set) var bankId: String?
    private let createWebRedirectComponent: () -> WebRedirectComponent
    private let tokenizationViewModel: BankSelectorTokenizationDelegate

    init(paymentMethodType: PrimerPaymentMethodType, tokenizationViewModel: BankSelectorTokenizationDelegate, createWebRedirectComponent: @escaping () -> WebRedirectComponent) {
        self.paymentMethodType = paymentMethodType
        self.tokenizationViewModel = tokenizationViewModel
        self.createWebRedirectComponent = createWebRedirectComponent
    }
    
    public func updateCollectedData(collectableData: BanksCollectableData) {
        validateData(for: collectableData)
        switch collectableData {
        case .bankId(bankId: let bankId):
            self.bankId = bankId
            let redirectComponent = createWebRedirectComponent()
        case .bankFilterText(text: let text):
            let filteredBanks = tokenizationViewModel.filterBanks(query: text)
            stepDelegate?.didReceiveStep(step: BanksStep.banksRetrieved(banks: filteredBanks.map { IssuingBank(bank: $0) }))
        }
    }
    
    func validateData(for data: BanksCollectableData) {
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        switch data {
        case .bankId(bankId: let bankId):
            if !banks.compactMap({ $0.id }).contains(bankId) {
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
        tokenizationViewModel.retrieveListOfBanks()
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
        case .webRedirect(component: _): break
        }
    }
}

private extension BanksComponent {
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

public extension BanksComponent {
    @objc final class IssuingBank: NSObject {
        public let id: String
        public let name: String
        public let iconUrlStr: String?
        public let isDisabled: Bool
        init(bank: AdyenBank) {
            self.id = bank.id
            self.name = bank.name
            self.iconUrlStr = bank.iconUrlStr
            self.isDisabled = bank.disabled
        }
    }
}
