//
//  PrimerRawCardDataRedirectTokenizationBuilder.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 27/09/22.
//

import Foundation

// swiftlint:disable type_name
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

class PrimerRawCardDataRedirectTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {

    var requiredInputElementTypes: [PrimerInputElementType]

    var paymentMethodType: String

    var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?

    var isDataValid: Bool

    var rawData: PrimerRawData?

    required init(paymentMethodType: String) {
        fatalError("\(#function) must be overriden")
    }

    func configure(withRawDataManager rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
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
            if let rawCardData = self.rawData as? PrimerBancontactCardData {
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

            DispatchQueue.main.async {
                rawDataManager.delegate?.primerRawDataManager?(rawDataManager, metadataDidChange: ["cardNetwork": self.cardNetwork.rawValue])
            }
        }
    }

    var requiredInputElementTypes: [PrimerInputElementType] {
        [.cardNumber, .expiryDate, .cardholderName]
    }

    required init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }

    func configure(withRawDataManager rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
        self.rawDataManager = rawDataManager
    }

    func makeRequestBodyWithRawData(_ data: PrimerRawData) -> Promise<Request.Body.Tokenization> {
        return Promise { seal in

            guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType),
                  let configId = AppState.current.apiConfiguration?.getConfigId(for: paymentMethod.type) else {
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let rawData = data as? PrimerCardData,
                  (rawData.expiryDate.split(separator: "/")).count == 2
            else {
                let err = PrimerError.invalidValue(key: "rawData", value: nil,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let expiryMonth = String((rawData.expiryDate.split(separator: "/"))[0])
            let expiryYear = String((rawData.expiryDate.split(separator: "/"))[1])

            let sanatizedCardNumber = (PrimerInputElementType.cardNumber.clearFormatting(value: rawData.cardNumber) as? String) ?? rawData.cardNumber
            let paymentInstrument = CardOffSessionPaymentInstrument(paymentMethodConfigId: configId,
                                                                    paymentMethodType: paymentMethodType,
                                                                    number: sanatizedCardNumber,
                                                                    expirationMonth: expiryMonth,
                                                                    expirationYear: expiryYear,
                                                                    cardholderName: rawData.cardholderName ?? "")

            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            seal.fulfill(requestBody)
        }
    }

    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.global(qos: .userInteractive).async {
                var errors: [PrimerValidationError] = []

                guard let rawData = data as? PrimerBancontactCardData else {
                    let err = PrimerValidationError.invalidRawData(
                        userInfo: .errorUserInfoDictionary(),
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

                if rawData.cardNumber.isEmpty {
                    let err = PrimerValidationError.invalidCardnumber(
                        message: "Card number can not be blank.",
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    errors.append(err)

                } else if !rawData.cardNumber.isValidCardNumber {
                    let err = PrimerValidationError.invalidCardnumber(
                        message: "Card number is not valid.",
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    errors.append(err)
                }

                do {
                    try rawData.expiryDate.validateExpiryDateString()
                } catch {
                    if let err = error as? PrimerValidationError {
                        errors.append(err)
                    }
                }

                if self.requiredInputElementTypes.contains(PrimerInputElementType.cardholderName) {
                    if rawData.cardholderName.isEmpty {
                        errors.append(PrimerValidationError.invalidCardholderName(
                                        message: "Cardholder name cannot be blank.",
                                        userInfo: .errorUserInfoDictionary(),
                                        diagnosticsId: UUID().uuidString))

                    } else if !(rawData.cardholderName).isValidNonDecimalString {
                        errors.append(PrimerValidationError.invalidCardholderName(
                                        message: "Cardholder name is not valid.",
                                        userInfo: .errorUserInfoDictionary(),
                                        diagnosticsId: UUID().uuidString))
                    }
                }

                if !errors.isEmpty {
                    let err = PrimerError.underlyingErrors(
                        errors: errors,
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)

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

// swiftlint:enable type_name
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
