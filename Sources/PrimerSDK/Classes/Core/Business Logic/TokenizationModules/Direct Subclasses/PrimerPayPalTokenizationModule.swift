//
//  PrimerPayPalTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerPayPalTokenizationModule: PrimerTokenizationModule {
    
    override func generatePaymentInstrument() -> Promise<TokenizationRequestBodyPaymentInstrument> {
        return Promise { seal in
            if PrimerInternal.shared.intent == .vault {
                firstly {
                    self.generateBillingAgreementConfirmation()
                }
                .done { billingAgreement in
                    let paymentInstrument = PayPalPaymentInstrument(
                        paypalOrderId: nil,
                        paypalBillingAgreementId: billingAgreement.billingAgreementId,
                        shippingAddress: billingAgreement.shippingAddress,
                        externalPayerInfo: billingAgreement.externalPayerInfo)
                    seal.fulfill(paymentInstrument)
                }
                .catch { err in
                    seal.reject(err)
                }
                
            } else {
                guard let orderId = PrimerAPIConfiguration.current?.clientSession?.order?.id else {
                    let err = PrimerError.invalidValue(
                        key: "orderId",
                        value: nil,
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                firstly {
                    self.fetchPayPalExternalPayerInfo(orderId: orderId)
                }
                .done { payerInfo in
                    let paymentInstrument = PayPalPaymentInstrument(
                        paypalOrderId: orderId,
                        paypalBillingAgreementId: nil,
                        shippingAddress: nil,
                        externalPayerInfo: payerInfo.externalPayerInfo)
                    seal.fulfill(paymentInstrument)
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
    }
    
    private func fetchPayPalExternalPayerInfo(orderId: String) -> Promise<Response.Body.PayPal.PayerInfo> {
        return Promise { seal in
            let paypalService = PayPalService()
            paypalService.fetchPayPalExternalPayerInfo(orderId: orderId) { result in
                switch result {
                case .success(let response):
                    seal.fulfill(response)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    private func generateBillingAgreementConfirmation() -> Promise<Response.Body.PayPal.ConfirmBillingAgreement> {
        return Promise { seal in
            let paypalService = PayPalService()
            paypalService.confirmBillingAgreement({ result in
                switch result {
                case .failure(let err):
                    let contaiinerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    
                case .success(let res):
                    seal.fulfill(res)
                }
            })
        }
    }
}

#endif
