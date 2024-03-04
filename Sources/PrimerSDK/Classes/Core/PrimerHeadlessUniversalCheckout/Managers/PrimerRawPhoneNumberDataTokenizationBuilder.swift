//
//  PrimerRawPhoneNumberDataTokenization.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 17/08/22.
//

import Foundation

// swiftlint:disable:next type_name
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

    weak var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
    var isDataValid: Bool = false
    var paymentMethodType: String
    var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?

    var requiredInputElementTypes: [PrimerInputElementType] {
        [.phoneNumber]
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

            guard let rawData = data as? PrimerPhoneNumberData else {
                let err = PrimerError.invalidValue(key: "rawData", value: nil, userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let sessionInfo = InputPhonenumberSessionInfo(phoneNumber: rawData.phoneNumber)

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

                guard let rawData = data as? PrimerPhoneNumberData else {
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

                if let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodType), !rawData.phoneNumber.isValidPhoneNumberForPaymentMethodType(paymentMethodType) {
                    errors.append(PrimerValidationError.invalidPhoneNumber(
                                    message: "Phone number is not valid.",
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
