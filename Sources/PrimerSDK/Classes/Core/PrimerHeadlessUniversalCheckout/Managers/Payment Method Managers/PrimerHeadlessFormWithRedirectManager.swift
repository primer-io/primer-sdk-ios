//
//  PrimerHeadlessIdealManager.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 03.11.2023.
//

import Foundation
extension PrimerHeadlessUniversalCheckout {
    public class PrimerHeadlessFormWithRedirectManager: NSObject {
        private var banksComponent: BanksComponent?
        private var webRedirectComponent: WebRedirectComponent?
        private weak var flowDelegate: PrimerComponentFlowDelegate?

        public init(flowDelegate: PrimerComponentFlowDelegate? = nil) {
            self.flowDelegate = flowDelegate
        }

        public func start(paymentMethodType: String, flowDelegate: PrimerComponentFlowDelegate?) -> Bool {
            self.flowDelegate = flowDelegate
            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType) else {
                return false
            }
            switch paymentMethodType {
            case .adyenIDeal, .adyenDotPay:
                let banksComponent = BanksComponent(paymentMethodType: paymentMethodType, onSelection: { [weak self] bankId in
                    guard let self = self else { return }
                    let webRedirectComponent = WebRedirectComponent(paymentMethodType: paymentMethodType, bankId: bankId)
                    self.webRedirectComponent = webRedirectComponent
                    self.flowDelegate?.didChangeComponent(to: webRedirectComponent)
                })
                self.banksComponent = banksComponent
                self.flowDelegate?.didChangeComponent(to: banksComponent)
                return true
            default: return false
            }
        }

        // using start

        public func provideBanksComponent(methodType: String) -> BanksComponent? {
            guard let paymentMethodType = PrimerPaymentMethodType(rawValue: methodType) else {
                return nil
            }
            switch paymentMethodType {
            case .adyenIDeal, .adyenDotPay:
                self.banksComponent = BanksComponent(paymentMethodType: paymentMethodType, onSelection: { [weak self] bankId in
                    guard let self = self else { return }
                    let webRedirectComponent = WebRedirectComponent(paymentMethodType: paymentMethodType, bankId: bankId)
                    self.webRedirectComponent = webRedirectComponent
                    self.flowDelegate?.didChangeComponent(to: webRedirectComponent)
                })
            default:
                assertionFailure("PrimerHeadlessIdealManager only works for the payment method iDeal via Adyen")
            }
            return banksComponent
        }

        public func provideWebRedirectComponent() -> WebRedirectComponent? {
            return webRedirectComponent
        }
    }
}
