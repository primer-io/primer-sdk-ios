//
//  PrimerRawCardDataRedirectTokenizationBuilder.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 27/09/22.
//

#if canImport(UIKit)

import Foundation

class PrimerRawCardDataRedirectTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {
    
    var requiredInputElementTypes: [PrimerInputElementType]
    
    var paymentMethodType: String
    
    var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
    
    var isDataValid: Bool
    
    var rawData: PrimerRawData?
    
    required init(paymentMethodType: String) {
        fatalError("\(#function) must be overriden")
    }
    
    func configureRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
        fatalError("\(#function) must be overriden")
    }
    
    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<Request.Body.Tokenization> {
        fatalError("\(#function) must be overriden")
    }
    
    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }
}

class PrimerBancontactRawCardDataRedirectTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {
    
    var rawData: PrimerRawData? {
        didSet {
            if let rawCardData = self.rawData as? PrimerBancontactCardRedirectData {
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
    
    public private(set) var cardNetwork: CardNetwork = .unknown {
        didSet {
            guard let rawDataManager = rawDataManager else {
                return
            }
            
            rawDataManager.delegate?.primerRawDataManager?(rawDataManager, metadataDidChange: ["cardNetwork": self.cardNetwork.rawValue])
        }
    }
    
    var requiredInputElementTypes: [PrimerInputElementType] {
        [.cardNumber, .expiryDate, .cardholderName]
    }
    
    required init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }
    
    func configureRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
        self.rawDataManager = rawDataManager
    }
    
    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<Request.Body.Tokenization> {
        return Promise { seal in
            
            guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType),
                  let configId = AppState.current.apiConfiguration?.getConfigId(for: paymentMethod.type) else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
                        
            guard let rawData = data as? PrimerBancontactCardRedirectData else {
                let err = PrimerError.invalidValue(key: "rawData", value: nil, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let paymentInstrument = CardOffSessionPaymentInstrument(paymentMethodConfigId: configId,
                                                                    paymentMethodType: paymentMethodType,
                                                                    number: PrimerInputElementType.cardNumber.clearFormatting(value: rawData.cardNumber) as! String,
                                                                    expirationMonth: rawData.expiryMonth,
                                                                    expirationYear: rawData.expiryYear,
                                                                    cardholderName: rawData.cardholderName)
            
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            seal.fulfill(requestBody)
        }
    }
    
    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        return Promise { seal in
            
            var errors: [PrimerValidationError] = []
            
            guard let rawData = data as? PrimerBancontactCardRedirectData, let rawDataManager = rawDataManager else {
                let err = PrimerValidationError.invalidRawData(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                errors.append(err)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            if !rawData.cardNumber.isValidCardNumber {
                errors.append(PrimerValidationError.invalidCardnumber(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString))
            }
            
            let expiryDate = rawData.expiryMonth + "/" + rawData.expiryYear.suffix(2)
            
            if !expiryDate.isValidExpiryDate {
                errors.append(PrimerValidationError.invalidExpiryDate(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString))
            }
            
            if self.requiredInputElementTypes.contains(PrimerInputElementType.cardholderName) {
                if !(rawData.cardholderName).isValidCardholderName {
                    errors.append(PrimerValidationError.invalidCardholderName(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString))
                }
            }
            
            if !errors.isEmpty {
                let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
