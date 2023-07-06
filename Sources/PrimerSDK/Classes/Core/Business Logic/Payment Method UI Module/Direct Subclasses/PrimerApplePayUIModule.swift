//
//  PrimerApplePayUIModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation
import PassKit
import UIKit

@available(iOS 11.0, *)
class PrimerApplePayUIModule: PrimerPaymentMethodUIModule {
    
    private var applePayWindow: UIWindow?
    private var request: PKPaymentRequest!
    private var applePayPaymentResponse: ApplePayPaymentResponse!
    // This is the completion handler that notifies that the necessary data were received.
    var applePayReceiveDataCompletion: ((Result<ApplePayPaymentResponse, Error>) -> Void)?
    // This is the PKPaymentAuthorizationViewController's completion, call it when tokenization has finished.
    private var applePayControllerCompletion: ((PKPaymentAuthorizationResult) -> Void)?
    private var didTimeout: Bool = false
        
    override func presentPreTokenizationUI() -> Promise<Void> {
        return Promise { seal in
            let countryCode = PrimerAPIConfigurationModule.apiConfiguration!.clientSession!.order!.countryCode!
            let currency = AppState.current.currency!
            let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions!.merchantIdentifier
            
            let orderItems: [OrderItem]
            
            do {
                orderItems = try self.createOrderItemsFromClientSession(AppState.current.apiConfiguration!.clientSession!)
            } catch {
                seal.reject(error)
                return
            }
            
            
            let applePayRequest = ApplePayRequest(
                currency: currency,
                merchantIdentifier: merchantIdentifier,
                countryCode: countryCode,
                items: orderItems
            )
            
            let supportedNetworks = PaymentNetwork.iOSSupportedPKPaymentNetworks
            if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks) {
                let request = PKPaymentRequest()
                let isBillingContactFieldsRequired = PrimerSettings.current.paymentMethodOptions.applePayOptions?.isCaptureBillingAddressEnabled == true
                request.requiredBillingContactFields = isBillingContactFieldsRequired ? [.postalAddress] : []
                request.currencyCode = applePayRequest.currency.rawValue
                request.countryCode = applePayRequest.countryCode.rawValue
                request.merchantIdentifier = merchantIdentifier
                request.merchantCapabilities = [.capability3DS]
                request.supportedNetworks = supportedNetworks
                request.paymentSummaryItems = applePayRequest.items.compactMap({ $0.applePayItem })
                
                guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                    let err = PrimerError.unableToPresentPaymentMethod(
                        paymentMethodType: PrimerPaymentMethodType.applePay.rawValue,
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                paymentVC.delegate = self
                
                DispatchQueue.main.async {
//                    self.isCancelled = true
                    PrimerUIManager.primerRootViewController?.present(paymentVC, animated: true, completion: {
                        DispatchQueue.main.async {
                            PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: self.paymentMethodOrchestrator.paymentMethodConfig.type)
//                            self.didPresentPaymentMethodUI?()
                            seal.fulfill()
                        }
                    })
                }
                
            } else {
                log(logLevel: .error, title: "APPLE PAY", message: "Cannot make payments on the provided networks")
                let err = PrimerError.unableToMakePaymentsOnProvidedNetworks(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func createOrderItemsFromClientSession(_ clientSession: ClientSession.APIResponse) throws -> [OrderItem] {
        var orderItems: [OrderItem] = []
        
        if let merchantAmount = clientSession.order?.merchantAmount {
            // If there's a hardcoded amount, create an order item with the merchant name as its title
            let summaryItem = try OrderItem(
                name: PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantName ?? "",
                unitAmount: merchantAmount,
                quantity: 1,
                discountAmount: nil,
                taxAmount: nil)
            orderItems.append(summaryItem)
            
        } else if let lineItems = clientSession.order?.lineItems {
            // If there's no hardcoded amount, map line items to order items
            guard !lineItems.isEmpty else {
                let err = PrimerError.invalidValue(
                    key: "clientSession.order.lineItems",
                    value: "[]",
                    userInfo: nil,
                    diagnosticsId: UUID().uuidString)
                throw err
            }
            
            for lineItem in lineItems {
                let orderItem = try lineItem.toOrderItem()
                orderItems.append(orderItem)
            }
            
            // Add fees, if present
            if let fees = clientSession.order?.fees {
                for fee in fees {
                    switch fee.type {
                    case .surcharge:
                        let feeItem = try OrderItem(
                            name: Strings.ApplePay.surcharge,
                            unitAmount: fee.amount,
                            quantity: 1,
                            discountAmount: nil,
                            taxAmount: nil)
                        orderItems.append(feeItem)
                    }
                }
            }
            
            let summaryItem = try OrderItem(
                name: PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantName ?? "",
                unitAmount: clientSession.order?.totalOrderAmount,
                quantity: 1,
                discountAmount: nil,
                taxAmount: nil)
            orderItems.append(summaryItem)
            
        } else {
            // Throw error that neither a hardcoded amount, nor line items exist
            let err = PrimerError.invalidValue(
                key: "clientSession.order.lineItems or clientSession.order.amount",
                value: nil,
                userInfo: nil,
                diagnosticsId: UUID().uuidString)
            throw err
        }
        
        return orderItems
    }
    
    fileprivate func clientSessionBillingAddressFromApplePayBillingContact(_ billingContact: PKContact?) -> ClientSession.Address? {
        guard let postalAddress = billingContact?.postalAddress else {
            return nil
        }
        
        // From: https://developer.apple.com/documentation/contacts/cnpostaladdress/1403414-street
        let addressLines = postalAddress.street.components(separatedBy: "\n")
        let addressLine1 = addressLines.first
        let addressLine2 = addressLines.count > 1 ? addressLines[1] : nil
        
        return ClientSession.Address(firstName: billingContact?.name?.givenName,
                                     lastName: billingContact?.name?.familyName,
                                     addressLine1: addressLine1,
                                     addressLine2: addressLine2,
                                     city: postalAddress.city,
                                     postalCode: postalAddress.postalCode,
                                     state: postalAddress.state,
                                     countryCode: CountryCode(rawValue: postalAddress.isoCountryCode))
    }
}

@available(iOS 11.0, *)
extension PrimerApplePayUIModule: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        if self.paymentMethodOrchestrator.isCancelled {
            controller.dismiss(animated: true, completion: nil)
            let err = PrimerError.cancelled(
                paymentMethodType: PrimerPaymentMethodType.applePay.rawValue,
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            applePayReceiveDataCompletion?(.failure(err))
            applePayReceiveDataCompletion = nil
            
        } else if self.didTimeout {
            controller.dismiss(animated: true, completion: nil)
            let err = PrimerError.applePayTimedOut(
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            applePayReceiveDataCompletion?(.failure(err))
            applePayReceiveDataCompletion = nil
        }
    }
    
    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        
        var isMockedBE: Bool = false
#if DEBUG
        if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
            isMockedBE = true
        }
#endif
        
#if targetEnvironment(simulator)
        if payment.token.paymentData.count == 0 && !isMockedBE {
            let err = PrimerError.invalidArchitecture(
                description: "Apple Pay does not work with Primer when used in the simulator due to a limitation from Apple Pay.",
                recoverSuggestion: "Use a real device instead of the simulator",
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [err]))
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                controller.dismiss(animated: true, completion: nil)
            }
            applePayReceiveDataCompletion?(.failure(err))
            applePayReceiveDataCompletion = nil
            return
        }
#endif
        
        self.paymentMethodOrchestrator.isCancelled = false
        self.didTimeout = true
        
        self.applePayControllerCompletion = { obj in
            self.didTimeout = false
            completion(obj)
        }
        
        do {
            let tokenPaymentData: ApplePayPaymentResponseTokenPaymentData
            if isMockedBE {
                tokenPaymentData = ApplePayPaymentResponseTokenPaymentData(
                    data: "apple-pay-payment-response-mock-data",
                    signature: "apple-pay-mock-signature",
                    version: "apple-pay-mock-version",
                    header: ApplePayTokenPaymentDataHeader(
                        ephemeralPublicKey: "apple-pay-mock-ephemeral-key",
                        publicKeyHash: "apple-pay-mock-public-key-hash",
                        transactionId: "apple-pay-mock--transaction-id"))
            } else {
                tokenPaymentData = try JSONParser().parse(ApplePayPaymentResponseTokenPaymentData.self, from: payment.token.paymentData)
            }
                        
            let billingAddress = clientSessionBillingAddressFromApplePayBillingContact(payment.billingContact)
            
            applePayPaymentResponse = ApplePayPaymentResponse(
                token: ApplePayPaymentInstrument.PaymentResponseToken(
                    paymentMethod: ApplePayPaymentResponsePaymentMethod(
                        displayName: payment.token.paymentMethod.displayName,
                        network: payment.token.paymentMethod.network?.rawValue,
                        type: payment.token.paymentMethod.type.primerValue
                    ),
                    transactionIdentifier: payment.token.transactionIdentifier,
                    paymentData: tokenPaymentData
                ),
                billingAddress: billingAddress)
            
            
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            controller.dismiss(animated: true, completion: nil)
            applePayReceiveDataCompletion?(.success(applePayPaymentResponse))
            applePayReceiveDataCompletion = nil
            
        } catch {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            controller.dismiss(animated: true, completion: nil)
            applePayReceiveDataCompletion?(.failure(error))
            applePayReceiveDataCompletion = nil
        }
    }
}

#endif
