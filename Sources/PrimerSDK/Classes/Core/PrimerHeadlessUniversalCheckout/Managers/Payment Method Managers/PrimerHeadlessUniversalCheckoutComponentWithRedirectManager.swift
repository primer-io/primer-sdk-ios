//
//  PrimerHeadlessIdealManager.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 03.11.2023.
//

import Foundation
extension PrimerHeadlessUniversalCheckout {
    @objc public class ComponentWithRedirectManager: NSObject {
        @objc public func provideComponent(paymentMethodType: String) -> PrimerHeadlessMainComponentWrapper {
            PrimerHeadlessMainComponentWrapper(manager: self, paymentMethodType: paymentMethodType)
        }
        @available(iOS 13, *)
        public func provide<PrimerHeadlessMainComponent>(paymentMethodType: String) throws -> PrimerHeadlessMainComponent? where PrimerCollectableData: Any, PrimerHeadlessStep: Any {
            try provideBanksComponent(paymentMethodType: paymentMethodType) as? PrimerHeadlessMainComponent
        }
        public func provideBanksComponent(paymentMethodType: String) throws -> any PrimerHeadlessMainComponent {
            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType),
                  paymentMethodType == .adyenIDeal else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            guard let tokenizationModelDelegate = PrimerAPIConfiguration.paymentMethodConfigViewModels.first(where: { $0 is BankSelectorTokenizationDelegate }) as? BankSelectorTokenizationDelegate  else {
                let err = PrimerError.generic(message: "Unable to locate a correct payment method view model", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            guard let webDelegate = PrimerAPIConfiguration.paymentMethodConfigViewModels.first(where: { $0 is WebRedirectTokenizationDelegate }) as? WebRedirectTokenizationDelegate  else {
                let err = PrimerError.generic(message: "Unable to locate a correct payment method view model", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
            return DefaultBanksComponent(paymentMethodType: paymentMethodType, tokenizationModelDelegate: tokenizationModelDelegate) {
                webDelegate.setup()
                return WebRedirectComponent(paymentMethodType: paymentMethodType, tokenizationModelDelegate: webDelegate)
            }
        }
    }
}

@objc public protocol BanksComponentErrorable: AnyObject {
    @objc func didReceiveError(_ error: NSError)
}

@objc public protocol BanksComponentSteppable: AnyObject {
    @objc func didStartLoading()
    @objc func didReceiveBanks(_ banks: [IssuingBank])
}

@objc public enum ValidStatus: Int {
    case validating
    case valid
    case invalid
    case error
}

@objc public protocol BanksComponentValidatable: AnyObject {
    @objc func didReceiveValidationStatus(_ status: ValidStatus)
}

@objc public protocol PrimerHeadlessMainComponentWrapperDelegate: AnyObject, PrimerHeadlessSubmitable, PrimerHeadlessStartable {
    @objc var stepDelegate: BanksComponentSteppable? { get set }
    @objc var errorDelegate: BanksComponentErrorable? { get set }
    @objc var validationDelegate: BanksComponentValidatable? { get set }
    @objc func selectBankById(_ bankdId: String)
    @objc func filterBankByName(_ text: String)
}

@objc public final class PrimerHeadlessMainComponentWrapper: NSObject, PrimerHeadlessMainComponentWrapperDelegate {
    var banksComponent: (any BanksComponent)?
    @objc public var stepDelegate: BanksComponentSteppable?
    @objc public var errorDelegate: BanksComponentErrorable?
    @objc public var validationDelegate: BanksComponentValidatable?
    init(manager: PrimerHeadlessUniversalCheckout.ComponentWithRedirectManager, paymentMethodType: String) {
        super.init()
        guard let banksComponent = try? manager.provideBanksComponent(paymentMethodType: paymentMethodType) as? (any BanksComponent) else {
            return
        }
        banksComponent?.stepDelegate = self
        banksComponent?.errorDelegate = self
        banksComponent?.validationDelegate = self
        self.banksComponent = banksComponent
    }
    @objc public func submit() {
        banksComponent?.submit()
    }
    @objc public func start() {
        banksComponent?.start()
    }
    @objc public func selectBankById(_ bankdId: String) {
        banksComponent?.updateCollectedData(collectableData: .bankId(bankId: bankdId))
    }
    @objc public func filterBankByName(_ text: String) {
        banksComponent?.updateCollectedData(collectableData: .bankFilterText(text: text))
    }
}


extension PrimerHeadlessMainComponentWrapper:   PrimerHeadlessErrorableDelegate,
                                                PrimerHeadlessValidatableDelegate,
                                                PrimerHeadlessSteppableDelegate {
    public func didReceiveError(error: PrimerError) {
        errorDelegate?.didReceiveError(NSError(domain: error.errorId, code: -1, userInfo: error.errorUserInfo))
    }

    public func didUpdate(validationStatus: PrimerValidationStatus, for data: PrimerCollectableData?) {
        validationDelegate?.didReceiveValidationStatus(validationStatus.toValidStatus)
    }

    public func didReceiveStep(step: PrimerHeadlessStep) {
        guard let step = step as? BanksStep else {
            return
        }
        switch step {
        case .loading: stepDelegate?.didStartLoading()
        case .banksRetrieved(banks: let banks): stepDelegate?.didReceiveBanks(banks)
        }
    }

}

private extension PrimerValidationStatus {
    var toValidStatus: ValidStatus {
        switch self {
        case .valid: return .valid
        case .validating: return .validating
        case .error(error: _): return .error
        case .invalid(errors: _): return .invalid
        }
    }
}
