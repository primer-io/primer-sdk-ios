//
//  PrimerHeadlessUniversalCheckout.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//

#if canImport(UIKit)

import UIKit

public class PrimerHeadlessUniversalCheckout {
    
    public static let current = PrimerHeadlessUniversalCheckout()
    
    public weak var delegate: PrimerHeadlessUniversalCheckoutDelegate?
    public weak var uiDelegate: PrimerHeadlessUniversalCheckoutUIDelegate?
    private(set) public var clientToken: String?

    private var apiConfigurationModule: PrimerAPIConfigurationModuleProtocol = PrimerAPIConfigurationModule()
    private let unsupportedPaymentMethodTypes: [String] = [
        PrimerPaymentMethodType.adyenBlik.rawValue,
        PrimerPaymentMethodType.adyenDotPay.rawValue,
        PrimerPaymentMethodType.adyenIDeal.rawValue,
        PrimerPaymentMethodType.goCardless.rawValue,
        PrimerPaymentMethodType.primerTestKlarna.rawValue,
        PrimerPaymentMethodType.primerTestPayPal.rawValue,
        PrimerPaymentMethodType.primerTestSofort.rawValue,
        PrimerPaymentMethodType.xfersPayNow.rawValue,
    ]
    
    fileprivate init() {}
    
    public func start(
        withClientToken clientToken: String,
        settings: PrimerSettings? = nil,
        delegate: PrimerHeadlessUniversalCheckoutDelegate? = nil,
        uiDelegate: PrimerHeadlessUniversalCheckoutUIDelegate? = nil,
        completion: @escaping (_ paymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod]?, _ err: Error?) -> Void
    ) {
        PrimerInternal.shared.intent = .checkout
        
        if delegate != nil {
            PrimerHeadlessUniversalCheckout.current.delegate = delegate
        }
        
        if PrimerHeadlessUniversalCheckout.current.delegate == nil {
            print("WARNING!\nPrimerHeadlessUniversalCheckout delegate has not been set, and you won't be able to receive the Payment Method Token data to create a payment.")
        }
        
        DependencyContainer.register(settings ?? PrimerSettings() as PrimerSettingsProtocol)
                
        firstly {
            self.apiConfigurationModule.setupSession(
                forClientToken: clientToken,
                requestDisplayMetadata: true,
                requestClientTokenValidation: false,
                requestVaultedPaymentMethods: false)
        }
        .done {
            let availablePaymentMethodsTypes = PrimerHeadlessUniversalCheckout.current.listAvailablePaymentMethodsTypes()
            if (availablePaymentMethodsTypes ?? []).isEmpty {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                DispatchQueue.main.async {
                    completion(nil, err)
                }
            } else {
                DispatchQueue.main.async {
                    let availablePaymentMethods = PrimerHeadlessUniversalCheckout.PaymentMethod.availablePaymentMethods
                    PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods?(availablePaymentMethods)
                    completion(availablePaymentMethods, nil)
                }
            }
        }
        .catch { err in
            DispatchQueue.main.async {
                completion(nil, err)
            }
        }
    }
    
    // MARK: - HELPERS
    
    private func continueValidateSession() -> Promise<Void> {
        return Promise { seal in
            guard let clientToken = PrimerAPIConfigurationModule.clientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token is nil"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let decodedJWTToken = clientToken.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token cannot be decoded"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            do {
                try decodedJWTToken.validate()
            } catch {
                seal.reject(error)
            }
            
            guard let apiConfiguration = PrimerAPIConfigurationModule.apiConfiguration else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            guard let paymentMethods = apiConfiguration.paymentMethods, !paymentMethods.isEmpty else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            seal.fulfill()
        }
    }
    
    internal func validateSession() -> Promise<Void> {
        return Promise { seal in
            guard let clientToken = PrimerAPIConfigurationModule.clientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token is nil"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let decodedJWTToken = clientToken.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token cannot be decoded"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            do {
                try decodedJWTToken.validate()
            } catch {
                seal.reject(error)
            }
            
            guard let apiConfiguration = PrimerAPIConfigurationModule.apiConfiguration else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            guard let paymentMethods = apiConfiguration.paymentMethods, !paymentMethods.isEmpty else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            seal.fulfill()
        }
    }
    
    internal func listAvailablePaymentMethodsTypes() -> [String]? {
        var paymentMethods = PrimerAPIConfiguration.paymentMethodConfigs
        if let klarnaIndex = paymentMethods?.firstIndex(where: { $0.type == PrimerPaymentMethodType.klarna.rawValue }) {
#if !canImport(PrimerKlarnaSDK)
            paymentMethods?.remove(at: klarnaIndex)
            print("\nWARNING!\nKlarna configuration has been found but module 'PrimerKlarnaSDK' is missing. Add `PrimerKlarnaSDK' in your project by adding \"pod 'PrimerKlarnaSDK'\" in your podfile or by adding \"primer-klarna-sdk-ios\" in your Swift Package Manager, so you can perform payments with Klarna.\n\n")
#endif
        }
        return paymentMethods?.compactMap({ $0.type }).filter({ !unsupportedPaymentMethodTypes.contains($0) })
    }
}

#endif
