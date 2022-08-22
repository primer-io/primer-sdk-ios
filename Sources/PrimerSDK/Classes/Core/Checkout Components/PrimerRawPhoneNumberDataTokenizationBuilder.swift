//
//  PrimerRawPhoneNumberDataTokenization.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 17/08/22.
//

import Foundation

class PrimerRawPhoneNumberDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {
    
    var rawData: PrimerRawData? {
        didSet {
            if let rawPhoneNumberInput = self.rawData as? PrimerPhoneNumberData {
                rawPhoneNumberInput.onDataDidChange = {
                    _ = self.validateRawData(rawPhoneNumberInput)
                }
            }
            
            if let rawData = self.rawData {
                _ = self.validateRawData(rawData)
            }
        }
    }
    
    var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager? {
        didSet {
            self.delegate = rawDataManager?.delegate
        }
    }
    var isDataValid: Bool = false
    var paymentMethodType: String
    var delegate: PrimerRawDataManagerDelegate?
    
    var requiredInputElementTypes: [PrimerInputElementType] {
        [.phoneNumber]
    }
    
    required init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }
    
    func configureRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
        self.rawDataManager = rawDataManager
    }
    
    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<TokenizationRequest> {
        return Promise { seal in
            
            guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType), let paymentMethodId = paymentMethod.id else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let rawData = data as? PrimerPhoneNumberData else {
                let err = PrimerError.invalidValue(key: "rawData", value: nil, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let paymentInstrument = InputPhoneNumberPaymentMethodOptions(paymentMethodType:
                                                                            paymentMethodType,
                                                                         paymentMethodConfigId: paymentMethodId,
                                                                         sessionInfo: InputPhoneNumberPaymentMethodOptions.SessionInfo(phoneNumber: rawData.phoneNumber, locale: PrimerSettings.current.localeData.localeCode))
            
            let request = InputPhoneNumberPaymentMethodTokenizationRequest(paymentInstrument: paymentInstrument)
            seal.fulfill(request)
        }
    }
    
    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        return Promise { seal in
            
            var errors: [PrimerValidationError] = []
            
            guard let rawData = data as? PrimerPhoneNumberData, let rawDataManager = rawDataManager else {
                let err = PrimerValidationError.invalidRawData(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                errors.append(err)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            if !rawData.phoneNumber.isValidPhoneNumber {
                errors.append(PrimerValidationError.invalidPhoneNumber(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
            }
            
            if !errors.isEmpty {
                let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                self.isDataValid = false
                delegate?.primerRawDataManager?(rawDataManager, dataIsValid: false, errors: errors)
                seal.reject(err)
            } else {
                self.isDataValid = true
                delegate?.primerRawDataManager?(rawDataManager, dataIsValid: true, errors: nil)
                seal.fulfill()
            }
        }
    }
}
