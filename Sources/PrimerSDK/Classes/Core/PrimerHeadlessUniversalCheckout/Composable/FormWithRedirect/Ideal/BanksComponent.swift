//
//  IdealComponent.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 06.11.2023.
//

import Foundation

public enum BanksCollectableData: FormCollectableData {
    case bankId(bankId: String)
    case bankQueryString(bankQuery: String)
}

public class BanksComponent: PrimerHeadlessFormComponent {

    public typealias T = BanksCollectableData
    let paymentMethodType: PrimerPaymentMethodType
    
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    var tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol?

    public private(set) var nextDataStep: BanksStep = .loading
    private(set) var banks: [IssuingBank]?
    private(set) var selectedBankId: String?
    private let onBankSelection: (String) -> Void

    init(paymentMethodType: PrimerPaymentMethodType, onBankSelection: @escaping (String) -> Void) {
        self.paymentMethodType = paymentMethodType
        self.onBankSelection = onBankSelection
    }
    
    public func updateCollectedData(collectableData: BanksCollectableData) {

        //TODO: need new analytical events, refactor to move outside of NolPay
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: NolPayAnalyticsConstants.LINK_CARD_UPDATE_COLLECTED_DATA_METHOD,
                params: [
                    "category": paymentMethodType.rawValue,
                ]))
        Analytics.Service.record(events: [sdkEvent])

        switch collectableData {
        case .bankId(bankId: let bankId):
            self.selectedBankId = bankId
        default: break
        }
        
        validateData(for: collectableData)
    }
    
    func validateData(for data: BanksCollectableData) {
        // TODO: error handler
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        switch data {
        case .bankId(bankId: let bankId):
            if bankId.isEmpty || !(banks?.compactMap { $0.id }.contains(bankId) ?? false) {
//                ErrorHandler.handle(error: errors.last!)
//                validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
            } else {
//                validationDelegate?.didUpdate(validationStatus: .valid, for: data)
            }
        default: break
        }
    }
    
    public func submit() {
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: NolPayAnalyticsConstants.LINK_CARD_SUBMIT_DATA_METHOD,
                params: [
                    "category": paymentMethodType.rawValue,
                ]))
        Analytics.Service.record(events: [sdkEvent])

        switch nextDataStep {
        default: break
        }

        // todo: refactor this
        guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigViewModels.filter({ $0.config.type == PrimerPaymentMethodManagerCategory.formWithRedirect.rawValue }).first as? BankSelectorTokenizationViewModel else {
            return
        }
        self.tokenizationViewModel = paymentMethod
    }
    
    public func start() {
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: NolPayAnalyticsConstants.LINK_CARD_START_METHOD,
                params: [
                    "category": paymentMethodType.rawValue,
                ]))
        Analytics.Service.record(events: [sdkEvent])
        guard let paymentMethod = PrimerAPIConfiguration.paymentMethodConfigViewModels.filter({ $0.config.type == PrimerPaymentMethodManagerCategory.formWithRedirect.rawValue }).first as? BankSelectorTokenizationViewModel else {
            return
        }
        self.tokenizationViewModel = paymentMethod
//        let result = paymentMethod.performTokenizationStep().result
    }
    
    // Helper method
    private func makeAndHandleInvalidValueError(forKey key: String) {
        let error = PrimerError.invalidValue(key: key, value: nil, userInfo: [
            "file": #file,
            "class": "\(Self.self)",
            "function": #function,
            "line": "\(#line)"
        ],
        diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        self.errorDelegate?.didReceiveError(error: error)
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
