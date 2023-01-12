//
//  PrimerRawCardDataTokenization.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 18/08/22.
//

#if canImport(UIKit)

import Foundation

class PrimerRawCardDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {
    
    var rawData: PrimerRawData? {
        didSet {
            if let rawCardData = self.rawData as? PrimerCardData {
                rawCardData.onDataDidChange = {
                    _ = self.validateRawData(rawCardData)
                    
                    let newCardNetwork = CardNetwork(cardNumber: rawCardData.cardNumber)
                    if newCardNetwork != self.cardNetwork {
                        self.cardNetwork = newCardNetwork
                    }
                }
                
                let newCardNetwork = CardNetwork(cardNumber: rawCardData.cardNumber)
                if newCardNetwork != self.cardNetwork {
                    self.cardNetwork = newCardNetwork
                }
                
            } else {
                if self.cardNetwork != .unknown {
                    self.cardNetwork = .unknown
                }
            }
            
            if let rawData = self.rawData {
                _ = self.validateRawData(rawData)
            }
        }
    }
    
    weak var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
    var isDataValid: Bool = false
    var paymentMethodType: String
    var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?
    
    public private(set) var cardNetwork: CardNetwork = .unknown {
        didSet {
            guard let rawDataManager = rawDataManager else {
                return
            }
            
            rawDataManager.delegate?.primerRawDataManager?(rawDataManager, metadataDidChange: ["cardNetwork": self.cardNetwork.rawValue])
        }
    }
    
    var requiredInputElementTypes: [PrimerInputElementType] {
        
        var mutableRequiredInputElementTypes: [PrimerInputElementType] = [.cardNumber, .expiryDate, .cvv]
        
        let cardInfoOptions = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?.filter({ $0.type == "CARD_INFORMATION" }).first?.options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions
        
        if let isCardHolderNameCheckoutModuleOptionEnabled = cardInfoOptions?.cardHolderName {
            if isCardHolderNameCheckoutModuleOptionEnabled {
                mutableRequiredInputElementTypes.append(.cardholderName)
            }
        } else {
            mutableRequiredInputElementTypes.append(.cardholderName)
        }
        
        return mutableRequiredInputElementTypes
    }
    
    required init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }
    
    func configureRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
        self.rawDataManager = rawDataManager
    }
    
    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<Request.Body.Tokenization> {
        return Promise { seal in
            guard PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType) != nil else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
                        
            guard let rawData = data as? PrimerCardData,
                  (rawData.expiryDate.split(separator: "/")).count == 2
            else {
                let err = PrimerError.invalidValue(key: "rawData", value: nil, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let expiryMonth = String((rawData.expiryDate.split(separator: "/"))[0])
            let expiryYear = String((rawData.expiryDate.split(separator: "/"))[1])
                        
            let paymentInstrument = CardPaymentInstrument(
                number: PrimerInputElementType.cardNumber.clearFormatting(value: rawData.cardNumber) as! String,
                cvv: rawData.cvv,
                expirationMonth: expiryMonth,
                expirationYear: expiryYear,
                cardholderName: rawData.cardholderName)
            
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            seal.fulfill(requestBody)
        }
    }
    
    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        return Promise { seal in
            
            var errors: [PrimerValidationError] = []
            
            guard let rawData = data as? PrimerCardData, let rawDataManager = rawDataManager else {
                let err = PrimerValidationError.invalidRawData(
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                errors.append(err)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            if rawData.cardNumber.isEmpty {
                let err = PrimerValidationError.invalidCardnumber(
                    message: "Card number can not be blank.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                errors.append(err)
                
            } else if !rawData.cardNumber.isValidCardNumber {
                let err = PrimerValidationError.invalidCardnumber(
                    message: "Card number is not valid.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                errors.append(err)
            }
                        
            let expiryDateComponents = rawData.expiryDate.split(separator: "/")
                        
            if expiryDateComponents.count != 2 {
                let err = PrimerValidationError.invalidExpiryDate(
                    message: "Expiry date is not valid. Valid expiry date format is 2 characters for expiry month and 4 characters for expiry year separated by '/'.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                errors.append(err)
                
            } else {
                let expiryMonth = String(expiryDateComponents[0])
                let expiryYear = String(expiryDateComponents[1])
                
                var isInvalidMonth = false
                var isInvalidYear = false
                
                if expiryMonth.isEmpty {
                    isInvalidMonth = true
                    errors.append(PrimerValidationError.invalidExpiryMonth(
                        message: "Expiry month cannot be blank.",
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString))
                    
                } else if Int(expiryMonth) == nil {
                    isInvalidMonth = true
                    errors.append(PrimerValidationError.invalidExpiryMonth(
                        message: "Expiry month is not valid.",
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString))
                    
                } else {
                    if Int(expiryMonth)! > 12 {
                        isInvalidMonth = true
                        errors.append(PrimerValidationError.invalidExpiryMonth(
                            message: "Expiry month is not valid.",
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString))
                        
                    } else if Int(expiryMonth)! < 1 {
                        isInvalidMonth = true
                        errors.append(PrimerValidationError.invalidExpiryMonth(
                            message: "Expiry month is not valid.",
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString))
                        
                    }
                }
                                
                if expiryYear.isEmpty {
                    isInvalidYear = true
                    errors.append(PrimerValidationError.invalidExpiryYear(
                        message: "Expiry year cannot be blank.",
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString))
                    
                } else if Int(expiryYear) == nil {
                    isInvalidYear = true
                    errors.append(PrimerValidationError.invalidExpiryYear(
                        message: "Expiry year is not valid.",
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString))
                } else if expiryYear.count != 4 {
                    isInvalidYear = true
                    errors.append(PrimerValidationError.invalidExpiryYear(
                        message: "Expiry year is not valid.",
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString))
                }
                
                if !isInvalidMonth, !isInvalidYear {
                    if !rawData.expiryDate.isValidExpiryDateWith4DigitYear {
                        errors.append(PrimerValidationError.invalidExpiryDate(
                            message: "Expiry date is not valid. Expiry date should not be in the past.",
                            userInfo: [
                                "file": #file,
                                "class": "\(Self.self)",
                                "function": #function,
                                "line": "\(#line)"
                            ],
                            diagnosticsId: UUID().uuidString))
                    }
                }
            }
            
            let cardNetwork = CardNetwork(cardNumber: rawData.cardNumber)
            
            if rawData.cvv.isEmpty {
                let err = PrimerValidationError.invalidCvv(
                    message: "CVV cannot be blank.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                errors.append(err)
                
            } else if !rawData.cvv.isValidCVV(cardNetwork: cardNetwork) {
                let err = PrimerValidationError.invalidCvv(
                    message: "CVV is not valid.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                errors.append(err)
            }
            
            if self.requiredInputElementTypes.contains(PrimerInputElementType.cardholderName) {
                if (rawData.cardholderName ?? "").isEmpty {
                    errors.append(PrimerValidationError.invalidCardholderName(
                        message: "Cardholder name cannot be blank.",
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString))
                } else if !(rawData.cardholderName ?? "").isValidCardholderName {
                    errors.append(PrimerValidationError.invalidCardholderName(
                        message: "Cardholder name is not valid.",
                        userInfo: [
                            "file": #file,
                            "class": "\(Self.self)",
                            "function": #function,
                            "line": "\(#line)"
                        ],
                        diagnosticsId: UUID().uuidString))
                }
            }
            
            if !errors.isEmpty {
                let err = PrimerError.underlyingErrors(
                    errors: errors,
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString)
                self.isDataValid = false
                self.rawDataManager?.delegate?.primerRawDataManager?(rawDataManager, dataIsValid: false, errors: errors)
                seal.reject(err)
            } else {
                self.isDataValid = true
                self.rawDataManager?.delegate?.primerRawDataManager?(rawDataManager, dataIsValid: true, errors: nil)
                seal.fulfill()
            }
        }
    }
}

#endif
