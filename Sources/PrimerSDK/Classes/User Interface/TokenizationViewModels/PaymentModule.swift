//
//  PaymentModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation

protocol PaymentModuleProtocol: NSObjectProtocol {
    
    var paymentCheckoutData: PrimerCheckoutData? { get set }
    
    init(
        paymentMethodConfiguration: PrimerPaymentMethod,
        userInterfaceModule: UserInterfaceModule,
        checkoutEventsNotifier: CheckoutEventsNotifierModule)
    
    func pay(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?>
    func createPayment(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<DecodedJWTToken?>
    func handleDecodedJWTTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?>
    func resumePayment(with resumeToken: String) -> Promise<PrimerCheckoutData?>
    func cancel()
}

class PaymentModule: NSObject, PaymentModuleProtocol {
    
    weak var paymentMethodConfiguration: PrimerPaymentMethod!
    weak var userInterfaceModule: UserInterfaceModule!
    weak var checkoutEventsNotifier: CheckoutEventsNotifierModule!
    
    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    var paymentId: String?
    var paymentCheckoutData: PrimerCheckoutData?
    var didCancel: (() -> Void)?
    var presentedViewController: UIViewController?
    
    required init(
        paymentMethodConfiguration: PrimerPaymentMethod,
        userInterfaceModule: UserInterfaceModule,
        checkoutEventsNotifier: CheckoutEventsNotifierModule
    ) {
        self.paymentMethodConfiguration = paymentMethodConfiguration
        self.userInterfaceModule = userInterfaceModule
        self.checkoutEventsNotifier = checkoutEventsNotifier
        super.init()
    }
    
    func pay(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?> {
        self.paymentMethodTokenData = paymentMethodTokenData
        
        return Promise { seal in
            DispatchQueue.main.async {
                PrimerUIManager.primerRootViewController?.enableUserInteraction(false)
            }
            
            firstly {
                self.createPayment(with: paymentMethodTokenData)
            }
            .done { decodedJWTToken in
                if let decodedJWTToken = decodedJWTToken {
                    firstly {
                        self.handleDecodedJWTTokenIfNeeded(decodedJWTToken)
                    }
                    .done { resumeToken in
                        if let resumeToken = resumeToken {
                            DispatchQueue.main.async {
                                PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
                                
                                if self.presentedViewController != nil {
                                    self.presentedViewController!.dismiss(animated: true)
                                    self.presentedViewController = nil
                                }
                            }
                            
                            firstly {
                                self.resumePayment(with: resumeToken)
                            }
                            .done { checkoutData in
                                seal.fulfill(checkoutData)
                            }
                            .catch { err in
                                seal.reject(err)
                            }
                        } else {
                            seal.fulfill(self.paymentCheckoutData)
                        }
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                } else {
                    seal.fulfill(self.paymentCheckoutData)
                }
            }
            .ensure {
                DispatchQueue.main.async {
                    PrimerUIManager.primerRootViewController?.enableUserInteraction(true)
                }
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    func createPayment(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<DecodedJWTToken?> {
        return Promise { seal in
            if PrimerSettings.current.paymentHandling == .manual {
                PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData) { resumeDecision in
                    switch resumeDecision.type {
                    case .succeed:
                        seal.fulfill(nil)
                        
                    case .continueWithNewClientToken(let newClientToken):
                        let apiConfigurationModule = PrimerAPIConfigurationModule()

                        firstly {
                            apiConfigurationModule.storeRequiredActionClientToken(newClientToken)
                        }
                        .done {
                            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                ErrorHandler.handle(error: err)
                                throw err
                            }
                            
                            seal.fulfill(decodedJWTToken)
                        }
                        .catch { err in
                            seal.reject(err)
                        }
                        
                    case .fail(let message):
                        var merchantErr: Error!
                        if let message = message {
                            let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            merchantErr = err
                        } else {
                            merchantErr = NSError.emptyDescriptionError
                        }
                        seal.reject(merchantErr)
                    }
                }

            } else {
                guard let paymentMethodTokenString = paymentMethodTokenData.token else {
                    let paymentMethodTokenError = PrimerError.invalidValue(key: "resumePaymentId", value: "Payment method token not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: paymentMethodTokenError)
                    throw paymentMethodTokenError
                }
                
                let paymentService: PaymentServiceProtocol = PaymentService()
                paymentService.createPayment(paymentRequest: Request.Body.Payment.Create(token: paymentMethodTokenString)) { paymentResponse, error in
                    guard error == nil else {
                        seal.reject(error!)
                        return
                    }
                    
                    guard let status = paymentResponse?.status, status != .failed else {
                        seal.reject(PrimerError.paymentFailed(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
                        return
                    }
                    
                    if let paymentFailureReason = paymentResponse?.paymentFailureReason,
                    let paymentErrorCode = PrimerPaymentErrorCode(rawValue: paymentFailureReason),
                       let error = PrimerError.simplifiedErrorFromErrorID(paymentErrorCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]) {
                        seal.reject(error)
                        return
                    }
                                    
                    guard paymentResponse != nil else {
                        let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        seal.reject(err)
                        return
                    }

                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse!))
                    self.paymentId = paymentResponse!.id
                    
                    if let requiredAction = paymentResponse!.requiredAction {
                        let apiConfigurationModule = PrimerAPIConfigurationModule()

                        firstly {
                            apiConfigurationModule.storeRequiredActionClientToken(requiredAction.clientToken)
                        }
                        .done {
                            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                                ErrorHandler.handle(error: err)
                                throw err
                            }

                            seal.fulfill(decodedJWTToken)
                        }
                        .catch { err in
                            seal.reject(err)
                        }

                    } else {
                        seal.fulfill(nil)
                    }
                }
            }
        }
    }
    
    func handleDecodedJWTTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken) -> Promise<String?> {
        fatalError("\(#function) must be overriden")
    }
    
    func resumePayment(with resumeToken: String) -> Promise<PrimerCheckoutData?> {
        return Promise { seal in
            if PrimerSettings.current.paymentHandling == .manual {
                PrimerDelegateProxy.primerDidResumeWith(resumeToken) { resumeDecision in
                    switch resumeDecision.type {
                    case .fail(let message):
                        var merchantErr: Error!
                        if let message = message {
                            let err = PrimerError.merchantError(message: message, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            merchantErr = err
                        } else {
                            merchantErr = NSError.emptyDescriptionError
                        }
                        seal.reject(merchantErr)

                    case .succeed:
                        seal.fulfill(self.paymentCheckoutData)

                    case .continueWithNewClientToken:
                        seal.fulfill(nil)
                    }
                }
                
            } else {
                guard let paymentId = self.paymentId else {
                    let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId", value: "Resume Payment ID not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: resumePaymentIdError)
                    seal.reject(resumePaymentIdError)
                    return
                }
                
                let createResumePaymentService: PaymentServiceProtocol = PaymentService()
                createResumePaymentService.resumePaymentWithPaymentId(paymentId, paymentResumeRequest: Request.Body.Payment.Resume(token: resumeToken)) { paymentResponse, error in
                    
                    guard error == nil else {
                        seal.reject(error!)
                        return
                    }
                    
                    guard let status = paymentResponse?.status, status != .failed else {
                        seal.reject(PrimerError.paymentFailed(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
                        return
                    }
                    
                    if let paymentFailureReason = paymentResponse?.paymentFailureReason,
                    let paymentErrorCode = PrimerPaymentErrorCode(rawValue: paymentFailureReason),
                       let error = PrimerError.simplifiedErrorFromErrorID(paymentErrorCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]) {
                        seal.reject(error)
                        return
                    }
                                    
                    guard let paymentResponse = paymentResponse else {
                        let err = PrimerError.invalidValue(key: "paymentResponse", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }
                    
                    self.paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                    seal.fulfill(self.paymentCheckoutData)
                }
            }
        }
    }
    
    func cancel() {
        self.didCancel?()
    }
}

#endif
