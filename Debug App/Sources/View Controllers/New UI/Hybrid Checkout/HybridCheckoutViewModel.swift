//
//  HybridCheckoutViewModel.swift
//  Debug App
//
//  Created by Niall Quinn on 22/07/24.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import Foundation
import UIKit
import PrimerSDK

class HybridCheckoutViewModel: ObservableObject {
    
    @Published var availablePaymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod] = []
    @Published var isLoading = true
    
    private var settings: PrimerSettings {
        .init(
          paymentMethodOptions: .init(
            urlScheme: "merchant://primer.io",
            applePayOptions: .init(
              merchantIdentifier: "merchant.com.getyourguide.mobile.primer.sandbox",
              merchantName: "GetYoutGuide",
              isCaptureBillingAddressEnabled: false,
              showApplePayForUnsupportedDevice: false,
              checkProvidedNetworks: false
            )
          ),
          debugOptions: PrimerDebugOptions(
            is3DSSanityCheckEnabled: false
          )
        )
      }
    private var clientSession: ClientSessionRequestBody?
    private var clientToken: String?
    
    var shouldPushViewController: ((UIViewController) -> Void)?
    
    private var sessionIntent: PrimerSessionIntent = .checkout
    private var checkoutData: PrimerCheckoutData?
    
    init(availablePaymentMethods: [PrimerHeadlessUniversalCheckout.PaymentMethod],
         settings: PrimerSettings,
         clientSession: ClientSessionRequestBody? = nil,
         clientToken: String? = nil) {
        self.availablePaymentMethods = availablePaymentMethods
//        self.settings = settings
        self.clientSession = clientSession
        self.clientToken = clientToken
        self.configure()
    }
    
    func configure() {
        // Start by configuring Headless to get available payment methods
        PrimerHeadlessUniversalCheckout.current.delegate = self
        PrimerHeadlessUniversalCheckout.current.uiDelegate = self
        Primer.shared.delegate = self
        
        isLoading = true
        setupSessionLogic()
        
        
    }
    
    func selectedPaymentMethod(_ paymentMethod: PrimerHeadlessUniversalCheckout.PaymentMethod) {
        
        guard let clientToken else {
            return
        }
        let paymentMethodType = paymentMethod.paymentMethodType
        switch paymentMethodType {
        case "PAYMENT_CARD":
            Primer.shared.showPaymentMethod(paymentMethod.paymentMethodType,
                                            intent: .checkout,
                                            clientToken: clientToken) { error in
                if let error {
                    print(error)
                }
            }
        case "KLARNA":
            #if canImport(PrimerKlarnaSDK)
            let vc = MerchantHeadlessCheckoutKlarnaViewController(sessionIntent: sessionIntent)
            shouldPushViewController?(vc)
            #else
            break
            #endif
        default:
            print("IMPLEMENT ME")
        }
        
    }
    
    var customError = PrimerError.unknown(userInfo: [:], diagnosticsId: "unknown")
    
    func configureHeadless() {
        Task.detached(priority: .low) {
            
            guard self.clientToken != nil else {
                print("No client token")
                return
            }
//            self.isLoading = true
            do {
                self.availablePaymentMethods = try await withCheckedThrowingContinuation { continuation in
                      DispatchQueue.main.async {
                        PrimerHeadlessUniversalCheckout.current.start(
                            withClientToken: self.clientToken!,
                          settings: self.settings,
                          delegate: self
                        ) { availablePaymentMethods, err in
                          if let err = err {
                            continuation.resume(throwing: (err as? PrimerError) ?? self.customError)
                          } else if let availablePaymentMethods = availablePaymentMethods {
                            continuation.resume(returning: availablePaymentMethods)
                          } else {
                            continuation.resume(throwing: self.customError)
                          }
                        }
                      }
                    }
            } catch {
                print(error)
            }
        }
    }
    
    private func setupSessionLogic() {
        if clientToken != nil {
            configureHeadless()
        } else if let clientSession {
            Networking.requestClientSession(requestBody: clientSession) { clientToken, err in
                self.isLoading = false
                self.clientToken = clientToken
                if let err {
                    print("Error fetching client token: \(err)")
                } else if clientToken != nil {
                    self.configureHeadless()
                }
            }
        }
    }
    
    func presentResultsVC() {
        guard let checkoutData else {
            print("No Checkout Data")
            return 
        }
        
    }
    
}

extension HybridCheckoutViewModel: PrimerHeadlessUniversalCheckoutDelegate {
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerSDK.PrimerCheckoutData) {
        self.checkoutData = data
    }
}

extension HybridCheckoutViewModel: PrimerHeadlessUniversalCheckoutUIDelegate {
    
}

extension HybridCheckoutViewModel: PrimerDelegate {
    func primerDidCompleteCheckoutWithData(_ data: PrimerSDK.PrimerCheckoutData) {
        self.checkoutData = data
        self.configureHeadless()
    }
    
    func primerDidDismiss() {
        self.configureHeadless()
    }
}
