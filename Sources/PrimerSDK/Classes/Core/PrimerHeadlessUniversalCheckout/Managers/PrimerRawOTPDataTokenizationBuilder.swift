//
//  PrimerRawOTPDataTokenizationBuilder.swift
//  PrimerSDK
//
//  Created by Boris on 26.9.24..
//

// swiftlint:disable function_body_length

import Foundation

final class PrimerRawOTPDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {

    var rawData: PrimerRawData? {
        didSet {
            if let rawOTPInput = self.rawData as? PrimerOTPData {
                rawOTPInput.onDataDidChange = { [weak self] in
                    guard let self = self else { return }
                    _ = self.validateRawData(rawOTPInput)
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
        [.otp]
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

            guard let rawData = data as? PrimerOTPData else {
                let err = PrimerError.invalidValue(key: "rawData",
                                                   value: nil,
                                                   userInfo: .errorUserInfoDictionary(),
                                                   diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let sessionInfo = BlikSessionInfo(blikCode: rawData.otp,
                                              locale: PrimerSettings.current.localeData.localeCode)

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
            let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard let rawData = data as? PrimerOTPData else {
            let err = PrimerError.invalidValue(key: "rawData",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        let sessionInfo = BlikSessionInfo(blikCode: rawData.otp,
                                          locale: PrimerSettings.current.localeData.localeCode)

        let paymentInstrument = OffSessionPaymentInstrument(
            paymentMethodConfigId: paymentMethodId,
            paymentMethodType: paymentMethodType,
            sessionInfo: sessionInfo
        )

        let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
        return requestBody
    }

    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.global(qos: .userInteractive).async {
                var errors: [PrimerValidationError] = []

                guard let rawData = data as? PrimerOTPData else {
                    let err = PrimerValidationError.invalidRawData(
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    errors.append(err)
                    ErrorHandler.handle(error: err)

                    Task { @MainActor in
                        self.notifyDelegateOfValidationResult(isValid: false, errors: errors)
                        seal.reject(err)
                    }

                    return
                }

                if !rawData.otp.isValidOTP {
                    errors.append(PrimerValidationError.invalidOTPCode(
                                    message: "OTP is not valid.",
                                    userInfo: .errorUserInfoDictionary(),
                                    diagnosticsId: UUID().uuidString))
                }

                if !errors.isEmpty {
                    let err = PrimerError.underlyingErrors(
                        errors: errors,
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)

                    Task { @MainActor in
                        self.notifyDelegateOfValidationResult(isValid: false, errors: errors)
                        seal.reject(err)
                    }
                } else {
                    Task { @MainActor in
                        self.notifyDelegateOfValidationResult(isValid: true, errors: nil)
                        seal.fulfill()
                    }
                }
            }
        }
    }

    func validateRawData(_ data: PrimerRawData) async throws {
        try await Task(priority: .userInitiated) {
            var errors: [PrimerValidationError] = []

            guard let rawData = data as? PrimerOTPData else {
                let err = PrimerValidationError.invalidRawData(
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                errors.append(err)
                ErrorHandler.handle(error: err)

                await self.notifyDelegateOfValidationResult(isValid: false, errors: errors)
                throw err
            }

            if !rawData.otp.isValidOTP {
                errors.append(PrimerValidationError.invalidOTPCode(
                    message: "OTP is not valid.",
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

                await self.notifyDelegateOfValidationResult(isValid: false, errors: errors)
                throw err
            }

            await self.notifyDelegateOfValidationResult(isValid: true, errors: nil)
        }.value
    }

    @MainActor
    private func notifyDelegateOfValidationResult(isValid: Bool, errors: [Error]?) {
        self.isDataValid = isValid

        guard let rawDataManager else { return }
        rawDataManager.delegate?.primerRawDataManager?(
            rawDataManager,
            dataIsValid: isValid,
            errors: errors
        )
    }
}
// swiftlint:enable function_body_length
