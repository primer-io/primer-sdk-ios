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
    var tokenizationViewModel: BankSelectorTokenizationViewModel?

    public private(set) var nextDataStep: BanksStep = .loading
    private(set) var banks: [IssuingBank] = []
    private(set) var bankId: String?
    private let createWebRedirectComponent: () -> WebRedirectComponent

    init(paymentMethodType: PrimerPaymentMethodType, createWebRedirectComponent: @escaping () -> WebRedirectComponent) {
        self.paymentMethodType = paymentMethodType
        self.createWebRedirectComponent = createWebRedirectComponent
    }
    
    public func updateCollectedData(collectableData: BanksCollectableData) {
        switch collectableData {
        case .bankId(bankId: let bankId):
            self.bankId = bankId
//            let redirectComponent = createWebRedirectComponent()
        case .bankFilterText(text: let text):
            let filteredBanks = self.tokenizationViewModel?.filterBanks(query: text) ?? []
            stepDelegate?.didReceiveStep(step: BanksStep.banksRetrieved(banks: filteredBanks.map { IssuingBank(bank: $0) }))
        default: break
        }

        validateData(for: collectableData)
    }
    
    func validateData(for data: BanksCollectableData) {
        // TODO: error handler
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        switch data {
        case .bankId(bankId: let bankId):
            if bankId.isEmpty || !banks.compactMap { $0.id }.contains(bankId) {
//                ErrorHandler.handle(error: errors.last!)
//                validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
            } else {
//                validationDelegate?.didUpdate(validationStatus: .valid, for: data)
            }
        default: break
        }
    }
    
    public func submit() {
        guard let bankId else { return }
        trackSubmit()
        // todo: refactor this
    }
    
    public func start() {
        trackStart()
        stepDelegate?.didReceiveStep(step: BanksStep.loading)
        retrieveViewModel()
        tokenizationViewModel?.fetchBanksHeadless()
            .done { banks -> Void in
                self.banks = banks.map { IssuingBank(bank: $0) }
                self.stepDelegate?.didReceiveStep(step: BanksStep.banksRetrieved(banks: self.banks))
            }.catch { errror in
                print("Error")
            }
    }
}

private extension BanksComponent {
    func retrieveViewModel() {
        guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigViewModels.first(where: { $0 is BankSelectorTokenizationViewModel }) as? BankSelectorTokenizationViewModel  else {
            return
        }
        self.tokenizationViewModel = paymentMethod
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
        let id: String
        let name: String
        let iconUrlStr: String?
        let isDisabled: Bool
        init(bank: AdyenBank) {
            self.id = bank.id
            self.name = bank.name
            self.iconUrlStr = bank.iconUrlStr
            self.isDisabled = bank.disabled
        }
    }
}
