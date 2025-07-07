//
//  PrimerRawPhoneNumberDataTokenization.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 17/08/22.
//

// swiftlint:disable function_body_length
// swiftlint:disable type_name

import Foundation

// MARK: MISSING_TESTS
final class PrimerRawPhoneNumberDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {

    var rawData: PrimerRawData? {
        didSet {
            if let rawPhoneNumberInput = self.rawData as? PrimerPhoneNumberData {
                rawPhoneNumberInput.onDataDidChange = { [weak self] in
                    guard let self = self else { return }
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
                let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: .errorUserInfoDictionary(),
                                                               diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let rawData = data as? PrimerPhoneNumberData else {
                let err = PrimerError.invalidValue(key: "rawData",
                                                   value: nil,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
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

    func makeRequestBodyWithRawData(_ data: PrimerRawData) async throws -> Request.Body.Tokenization {
        guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType), let paymentMethodId = paymentMethod.id else {
            let err = PrimerError.unsupportedPaymentMethod(
                paymentMethodType: paymentMethodType,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: err)
            throw err
        }

        guard let rawData = data as? PrimerPhoneNumberData else {
            let err = PrimerError.invalidValue(
                key: "rawData",
                value: nil,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: err)
            throw err
        }

        return Request.Body.Tokenization(
            paymentInstrument: OffSessionPaymentInstrument(
                paymentMethodConfigId: paymentMethodId,
                paymentMethodType: paymentMethodType,
                sessionInfo: InputPhonenumberSessionInfo(phoneNumber: rawData.phoneNumber)
            )
        )
    }

    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.global(qos: .userInteractive).async {
                var errors: [PrimerValidationError] = []

                guard let rawData = data as? PrimerPhoneNumberData else {
                    let err = PrimerValidationError.invalidRawData(
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    errors.append(err)
                    ErrorHandler.handle(error: err)

                    self.notifyDelegateOfValidationResult(isValid: false, errors: errors)

                    DispatchQueue.main.async {
                        seal.reject(err)
                    }

                    return
                }

                if let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodType),
                   !rawData.phoneNumber.isValidPhoneNumberForPaymentMethodType(paymentMethodType) {
                    errors.append(PrimerValidationError.invalidPhoneNumber(
                                    message: "Phone number is not valid.",
                                    userInfo: .errorUserInfoDictionary(),
                                    diagnosticsId: UUID().uuidString))
                }

                if !errors.isEmpty {
                    let err = PrimerError.underlyingErrors(
                        errors: errors,
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)

                    self.notifyDelegateOfValidationResult(isValid: false, errors: errors)

                    DispatchQueue.main.async {
                        seal.reject(err)
                    }
                } else {
                    self.notifyDelegateOfValidationResult(isValid: true, errors: nil)

                    DispatchQueue.main.async {
                        seal.fulfill()
                    }
                }
            }
        }
    }

    func validateRawData(_ data: PrimerRawData) async throws {
        try await Task(priority: .userInitiated) {
            var errors: [PrimerValidationError] = []

            guard let rawData = data as? PrimerPhoneNumberData else {
                let err = PrimerValidationError.invalidRawData(
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                errors.append(err)
                ErrorHandler.handle(error: err)

                await self.notifyDelegateOfValidationResult_async(isValid: false, errors: errors)
                throw err
            }

            if let paymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodType),
               !rawData.phoneNumber.isValidPhoneNumberForPaymentMethodType(paymentMethodType) {
                errors.append(PrimerValidationError.invalidPhoneNumber(
                    message: "Phone number is not valid.",
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                ))
            }

            guard errors.isEmpty else {
                let err = PrimerError.underlyingErrors(
                    errors: errors,
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: err)

                await self.notifyDelegateOfValidationResult_async(isValid: false, errors: errors)
                throw err
            }

            await self.notifyDelegateOfValidationResult_async(isValid: true, errors: nil)
        }.value
    }
    
    private func notifyDelegateOfValidationResult(isValid: Bool, errors: [Error]?) {
        self.isDataValid = isValid

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let rawDataManager = self.rawDataManager else { return }

            rawDataManager.delegate?.primerRawDataManager?(
                rawDataManager,
                dataIsValid: isValid,
                errors: errors
            )
        }
    }

    @MainActor
    private func notifyDelegateOfValidationResult_async(isValid: Bool, errors: [Error]?) {
        self.isDataValid = isValid

        guard let rawDataManager else { return }
        rawDataManager.delegate?.primerRawDataManager?(
            rawDataManager,
            dataIsValid: isValid,
            errors: errors
        )
    }
}
// swiftlint:enable type_name
// swiftlint:enable function_body_length
