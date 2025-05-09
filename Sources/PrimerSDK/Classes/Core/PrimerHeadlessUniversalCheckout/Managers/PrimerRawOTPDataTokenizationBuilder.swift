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
            if let rawOTPInput = rawData as? PrimerOTPData {
                rawOTPInput.onDataDidChange = { [weak self] in
                    guard let self = self else { return }
                    _ = self.validateRawData(rawOTPInput)
                }
            }

            if let rawData = rawData {
                _ = validateRawData(rawData)
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

                    self.notifyDelegateOfValidationResult(isValid: false, errors: errors)

                    DispatchQueue.main.async {
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

    private func notifyDelegateOfValidationResult(isValid: Bool, errors: [Error]?) {
        isDataValid = isValid

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let rawDataManager = self.rawDataManager else { return }

            rawDataManager.delegate?.primerRawDataManager?(
                rawDataManager,
                dataIsValid: isValid,
                errors: errors
            )
        }
    }
}
// swiftlint:enable function_body_length
