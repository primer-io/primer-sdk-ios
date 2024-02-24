//
//  PrimerRawRetailerDataTokenizationBuilder.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 18/10/22.
//

import Foundation

class PrimerRawRetailerDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {

    var rawData: PrimerRawData? {
        didSet {
            if let rawRetailerData = self.rawData as? PrimerRetailerData {
                rawRetailerData.onDataDidChange = {
                    _ = self.validateRawData(rawRetailerData)
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

    var requiredInputElementTypes: [PrimerInputElementType] {
        [.retailer]
    }

    required init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }

    func configure(withRawDataManager rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
        self.rawDataManager = rawDataManager
    }

    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<Request.Body.Tokenization> {
        return Promise { seal in

            guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType), let paymentMethodId = paymentMethod.id else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let rawData = data as? PrimerRetailerData else {
                let err = PrimerError.invalidValue(key: "rawData", value: nil, userInfo: nil, diagnosticsId: UUID().uuidString)
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
            DispatchQueue.global(qos: .userInteractive).async {
                var errors: [PrimerValidationError] = []

                guard let rawData = data as? PrimerRetailerData else {
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

                    self.isDataValid = false

                    DispatchQueue.main.async {
                        if let rawDataManager = self.rawDataManager {
                            self.rawDataManager?.delegate?.primerRawDataManager?(rawDataManager,
                                                                                 dataIsValid: self.isDataValid,
                                                                                 errors: errors.count == 0 ? nil : errors)
                        }

                        seal.reject(err)
                    }
                    return
                }

                if rawData.id.isEmpty {
                    errors.append(PrimerValidationError.invalidRawData(
                                    userInfo: [
                                        "file": #file,
                                        "class": "\(Self.self)",
                                        "function": #function,
                                        "line": "\(#line)"
                                    ],
                                    diagnosticsId: UUID().uuidString))
                }

                if !errors.isEmpty {
                    let err = PrimerError.underlyingErrors(
                        errors: errors,
                        userInfo: ["file": #file,
                                   "class": "\(Self.self)",
                                   "function": #function,
                                   "line": "\(#line)"],
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)

                    self.isDataValid = false

                    DispatchQueue.main.async {
                        if let rawDataManager = self.rawDataManager {
                            self.rawDataManager?.delegate?.primerRawDataManager?(rawDataManager,
                                                                                 dataIsValid: self.isDataValid,
                                                                                 errors: errors.count == 0 ? nil : errors)
                        }

                        seal.reject(err)
                    }
                } else {
                    self.isDataValid = true

                    DispatchQueue.main.async {
                        if let rawDataManager = self.rawDataManager {
                            self.rawDataManager?.delegate?.primerRawDataManager?(rawDataManager,
                                                                                 dataIsValid: self.isDataValid,
                                                                                 errors: errors.count == 0 ? nil : errors)
                        }

                        seal.fulfill()
                    }
                }
            }
        }
    }
}
