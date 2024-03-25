//
//  PrimerHeadlessBanksComponentWrapper.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 22.11.2023.
//

import Foundation
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

// swiftlint:disable type_name
@objc public protocol PrimerHeadlessBanksComponentWrapperDelegate: AnyObject, PrimerHeadlessSubmitable, PrimerHeadlessStartable {
    @objc var stepDelegate: BanksComponentSteppable? { get set }
    @objc var errorDelegate: BanksComponentErrorable? { get set }
    @objc var validationDelegate: BanksComponentValidatable? { get set }
    @objc func selectBankById(_ bankdId: String)
    @objc func filterBankByName(_ text: String)
}

@objc public final class PrimerHeadlessBanksComponentWrapper: NSObject, PrimerHeadlessBanksComponentWrapperDelegate {
    var banksComponent: (any BanksComponent)?
    @objc public var stepDelegate: BanksComponentSteppable?
    @objc public var errorDelegate: BanksComponentErrorable?
    @objc public var validationDelegate: BanksComponentValidatable?
    init(manager: PrimerHeadlessUniversalCheckout.ComponentWithRedirectManager, paymentMethodType: String) {
        super.init()
        guard let banksComponent = try? manager.provideBanksComponent(paymentMethodType: paymentMethodType) as? (any BanksComponent) else {
            return
        }
        banksComponent.stepDelegate = self
        banksComponent.errorDelegate = self
        banksComponent.validationDelegate = self
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

extension PrimerHeadlessBanksComponentWrapper: PrimerHeadlessErrorableDelegate,
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
        case .error: return .error
        case .invalid: return .invalid
        }
    }
}
// swiftlint:enable type_name
