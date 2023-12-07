//
//  NolPayPaymentComponent.swift
//  PrimerSDK
//
//  Created by Boris on 18.9.23..
//

import Foundation
#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
#endif

public enum NolPayPaymentCollectableData: PrimerCollectableData {
    case paymentData(cardNumber: String, mobileNumber: String)
}

public enum NolPayPaymentStep: PrimerHeadlessStep {
    case collectCardAndPhoneData
    case paymentRequested
}

public class NolPayPaymentComponent: PrimerHeadlessCollectDataComponent, PrimerHeadlessAnalyticsRecordable {
    public typealias T = NolPayPaymentCollectableData

#if canImport(PrimerNolPaySDK)
    private var nolPay: PrimerNolPay!
#endif
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    var phoneMetadataService = NolPayPhoneMetadataService()

    var tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol!

    var mobileNumber: String?
    var countryCode: String?
    var cardNumber: String?
    var nextDataStep: NolPayPaymentStep = .collectCardAndPhoneData

    public func updateCollectedData(collectableData: NolPayPaymentCollectableData) {
        switch collectableData {
        case let .paymentData(cardNumber, mobileNumber):
            nextDataStep = .collectCardAndPhoneData
            self.cardNumber = cardNumber
            self.mobileNumber = mobileNumber
        }

        validateData(for: collectableData)
    }

    func validateData(for data: NolPayPaymentCollectableData) {
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        var errors: [PrimerValidationError] = []
        
        recordEvent(
            type: .sdkEvent,
            name: NolPayAnalyticsConstants.PAYMENT_UPDATE_COLLECTED_DATA_METHOD,
            params: [
                NolPayAnalyticsConstants.CATEGORY_KEY: NolPayAnalyticsConstants.CATEGORY_VALUE
            ]
        )
        
        switch data {
        case .paymentData(cardNumber: let cardNumber,
                          mobileNumber: let mobileNumber):

            if cardNumber.isEmpty {
                errors.append(PrimerValidationError.invalidCardnumber(
                    message: "Card number is not valid.",
                    userInfo: [
                        "file": #file,
                        "class": "\(Self.self)",
                        "function": #function,
                        "line": "\(#line)"
                    ],
                    diagnosticsId: UUID().uuidString))
                ErrorHandler.handle(error: errors.last!)
            }

            phoneMetadataService.getPhoneMetadata(mobileNumber: mobileNumber) { [weak self] result in
                switch result {

                case let .success((validationStatus, countryCode, mobileNumber)):
                    switch validationStatus {

                    case .valid:
                        if errors.isEmpty {
                            self?.countryCode = countryCode
                            self?.mobileNumber = mobileNumber
                            self?.validationDelegate?.didUpdate(validationStatus: .valid, for: data)
                        } else {
                            self?.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
                        }

                    case .invalid(errors: let validationErrors):
                        errors += validationErrors
                        self?.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
                    default: break
                    }
                case .failure(let error):
                    self?.validationDelegate?.didUpdate(validationStatus: .error(error: error), for: data)
                }
            }
        }
    }

    public func submit() {
        recordEvent(
            type: .sdkEvent,
            name: NolPayAnalyticsConstants.PAYMENT_SUBMIT_DATA_METHOD,
            params: [
                NolPayAnalyticsConstants.CATEGORY_KEY: NolPayAnalyticsConstants.CATEGORY_VALUE
            ]
        )

        switch nextDataStep {
        case .collectCardAndPhoneData:
            guard let cardNumber = cardNumber
            else {
                makeAndHandleInvalidValueError(forKey: "cardNumber")
                return
            }

            guard  let mobileNumber = mobileNumber
            else {
                makeAndHandleInvalidValueError(forKey: "mobileNumber")
                return
            }

            guard let countryCode = countryCode
            else {
                makeAndHandleInvalidValueError(forKey: "phoneCountryDiallingCode")
                return
            }

            guard
                let paymentMethod = getTokenizationViewModel(
                    paymentType: .nolPay,
                    viewModelType: NolPayTokenizationViewModel.self
                )
            else {
                return
            }
            self.tokenizationViewModel = paymentMethod
            paymentMethod.nolPayCardNumber = cardNumber
            paymentMethod.mobileNumber = mobileNumber
            paymentMethod.mobileCountryCode = countryCode

            paymentMethod.triggerAsyncAction = { (transactionNumber: String, completion: ((Result<Bool, Error>) -> Void)?)  in
    #if canImport(PrimerNolPaySDK)
                self.nolPay.requestPayment(for: cardNumber, and: transactionNumber) { result in
                    switch result {

                    case .success(let success):
                        if success {
                            self.nextDataStep = .paymentRequested
                            self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                            completion?(.success(true))
                        } else {
                            let error = PrimerError.nolError(code: "unknown",
                                                             message: "Payment failed from unknown reason",
                                                             userInfo: [
                                                                "file": #file,
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"
                                                             ],
                                                             diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: error)
                            completion?(.failure(error))
                        }
                    case .failure(let error):
                        let error = PrimerError.nolError(code: error.errorCode,
                                                         message: error.description,
                                                         userInfo: [
                                                            "file": #file,
                                                            "class": "\(Self.self)",
                                                            "function": #function,
                                                            "line": "\(#line)"
                                                         ],
                                                         diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: error)
                        completion?(.failure(error))
                    }
                }
    #endif
            }
            paymentMethod.start()

        default:
            break
        }
    }

    public func start() {
        recordEvent(
            type: .sdkEvent,
            name: NolPayAnalyticsConstants.PAYMENT_START_METHOD,
            params: [
                NolPayAnalyticsConstants.CATEGORY_KEY: NolPayAnalyticsConstants.CATEGORY_VALUE
            ]
        )

        guard let nolPaymentMethodOption = PrimerAPIConfiguration.current?.paymentMethods?.first(where: { $0.internalPaymentMethodType == .nolPay})?.options as? MerchantOptions,
              let appId = nolPaymentMethodOption.appId
        else {
            makeAndHandleInvalidValueError(forKey: "Nol AppID")
            return
        }

        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            return
        }

        let isSandbox = clientToken.env != "PRODUCTION"
        var isDebug = false
#if DEBUG
        isDebug =  PrimerLogging.shared.logger.logLevel == .debug
#endif

#if canImport(PrimerNolPaySDK)
        nolPay = PrimerNolPay(appId: appId, isDebug: isDebug, isSandbox: isSandbox) { sdkId, deviceId in

            let requestBody = await Request.Body.NolPay.NolPaySecretDataRequest(nolSdkId: deviceId,
                                                                                nolAppId: sdkId,
                                                                                phoneVendor: "Apple",
                                                                                phoneModel: UIDevice.modelIdentifier!)
            let client = PrimerAPIClient()

            if #available(iOS 13, *) {
                return try await withCheckedThrowingContinuation { continuation in
                    client.fetchNolSdkSecret(clientToken: clientToken, paymentRequestBody: requestBody) { result in
                        switch result {
                        case .success(let appSecret):
                            continuation.resume(returning: appSecret.sdkSecret)
                        case .failure(let error):
                            ErrorHandler.handle(error: error)
                            continuation.resume(throwing: error)
                        }
                    }
                }
            } else {
                assertionFailure("Nol pay SDK requires iOS 13")
                return ""
            }
        }
#else
        let error = PrimerError.missingSDK(
            paymentMethodType: PrimerPaymentMethodType.nolPay.rawValue,
            sdkName: "PrimerNolPaySDK",
            userInfo: ["file": #file,
                       "class": "\(Self.self)",
                       "function": #function,
                       "line": "\(#line)"],
            diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        errorDelegate?.didReceiveError(error: error)
#endif
    }

    // Helper method
    private func makeAndHandleInvalidValueError(forKey key: String) {
        let error = PrimerError.invalidValue(key: key, value: nil, userInfo: [
            "file": #file,
            "class": "\(Self.self)",
            "function": #function,
            "line": "\(#line)"
        ],
        diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        self.errorDelegate?.didReceiveError(error: error)
    }
}
