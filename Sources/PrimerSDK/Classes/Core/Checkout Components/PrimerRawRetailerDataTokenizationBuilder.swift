//
//  PrimerRawRetailerDataTokenizationBuilder.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 18/10/22.
//

#if canImport(UIKit)

import Foundation

class PrimerRawRetailerDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {
    
    var rawData: PrimerRawData? {
        didSet {
            if let rawRetailerData = self.rawData as? PrimerRawRetailerData {
                rawRetailerData.onDataDidChange = {
                    _ = self.validateRawData(rawRetailerData)
                }
            }
            
            if let rawData = self.rawData {
                _ = self.validateRawData(rawData)
            }
        }
    }
    
    var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
    var isDataValid: Bool = false
    var paymentMethodType: String
    var delegate: PrimerRawDataManagerDelegate?
    
    var requiredInputElementTypes: [PrimerInputElementType] {
        [.retailer]
    }
    
    required init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }
    
    func configureRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
        self.rawDataManager = rawDataManager
    }
    
    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<Request.Body.Tokenization> {
        return Promise { seal in
            
            guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType), let paymentMethodId = paymentMethod.id else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let rawData = data as? PrimerRawRetailerData else {
                let err = PrimerError.invalidValue(key: "rawData", value: nil, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let sessionInfo = RetailOutletTokenizationSessionRequestParameters(retailOutlet: rawData.id)
            
            let paymentInstrument = OffSessionPaymentInstrument(
                paymentMethodConfigId: paymentMethodId,
                paymentMethodType: paymentMethodType,
                sessionInfo: sessionInfo)
            
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            seal.fulfill(requestBody)
        }
    }
    
    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        return Promise { seal in
            
            var errors: [PrimerValidationError] = []
            
            guard let rawData = data as? PrimerRawRetailerData, let rawDataManager = rawDataManager else {
                let err = PrimerValidationError.invalidRawData(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                errors.append(err)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            if rawData.id.isEmpty {
                errors.append(PrimerValidationError.invalidRawData(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
            }
            
            if !errors.isEmpty {
                let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
