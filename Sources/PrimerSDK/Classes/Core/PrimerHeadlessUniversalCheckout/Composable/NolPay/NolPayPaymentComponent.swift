//
//  NolPayPaymentComponent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

import PrimerFoundation
import UIKit

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

public final class NolPayPaymentComponent: PrimerHeadlessCollectDataComponent {
    public typealias CollectableDataType = NolPayPaymentCollectableData
    public typealias CardStepType = NolPayPaymentStep

    #if canImport(PrimerNolPaySDK)
    var nolPay: PrimerNolPayProtocol?
    #endif
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?

    private let apiClient: PrimerAPIClientProtocol
    private var phoneMetadataService: NolPayPhoneMetadataServiceProtocol
    private var tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol?

    // Computed property to fetch the tokenizationViewModel dynamically
    private var resolvedTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol? {
        tokenizationViewModel ??
            PrimerAPIConfiguration.paymentMethodConfigViewModels
            .first(where: { $0.config.type == PrimerPaymentMethodType.nolPay.rawValue }) as? NolPayTokenizationViewModel
    }

    var mobileNumber: String?
    var countryCode: String?
    var cardNumber: String?
    public var nextDataStep: NolPayPaymentStep = .collectCardAndPhoneData

    public convenience init() {
        self.init(
            apiClient: PrimerAPIClient(),
            phoneMetadataService: NolPayPhoneMetadataService(),
            tokenizationViewModel: nil
        )
    }

    init(
        apiClient: PrimerAPIClientProtocol,
        phoneMetadataService: NolPayPhoneMetadataServiceProtocol,
        tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol?
    ) {
        self.apiClient = apiClient
        self.phoneMetadataService = phoneMetadataService
        self.tokenizationViewModel = tokenizationViewModel
    }

    public func updateCollectedData(collectableData: CollectableDataType) {
        switch collectableData {
        case let .paymentData(cardNumber, mobileNumber):
            nextDataStep = .collectCardAndPhoneData
            self.cardNumber = cardNumber
            self.mobileNumber = mobileNumber
        }

        validateData(for: collectableData)
    }

    private func validateData(for data: NolPayPaymentCollectableData) {
        validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        var errors: [PrimerValidationError] = []
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.paymentUpdateCollectedDataMethod,
            params: ["category": "NOL_PAY"]
        )
        Analytics.Service.fire(events: [sdkEvent])

        switch data {
        case let .paymentData(cardNumber: cardNumber,
                          mobileNumber: mobileNumber):

            if cardNumber.isEmpty || !cardNumber.isNumeric {
                errors.append(handled(error: PrimerValidationError.invalidCardnumber(message: "Card number is not valid.")))
            }

            phoneMetadataService.getPhoneMetadata(mobileNumber: mobileNumber) { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success((validationStatus, countryCode, mobileNumber)):
                    switch validationStatus {
                    case .valid:
                        if errors.isEmpty {
                            self.countryCode = countryCode
                            self.mobileNumber = mobileNumber
                            self.validationDelegate?.didUpdate(validationStatus: .valid, for: data)
                        } else {
                            self.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
                        }

                    case let .invalid(errors: validationErrors):
                        errors += validationErrors
                        self.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)

                    default: break
                    }
                case let .failure(error):
                    self.validationDelegate?.didUpdate(validationStatus: .error(error: error), for: data)
                }
            }
        }
    }

    public func submit() {
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.paymentSubmitDataMethod,
            params: ["category": "NOL_PAY"]
        )
        Analytics.Service.fire(events: [sdkEvent])

        switch nextDataStep {
        case .collectCardAndPhoneData:
            guard let cardNumber else {
                return makeAndHandleInvalidValueError(forKey: "cardNumber")
            }

            guard let mobileNumber else {
                return makeAndHandleInvalidValueError(forKey: "mobileNumber")
            }

            guard let countryCode else {
                return makeAndHandleInvalidValueError(forKey: "countryCode")
            }

            #if canImport(PrimerNolPaySDK)
            guard let nolPay else {
                return makeAndHandleNolPayInitializationError()
            }
            #endif

            guard let tokenizationViewModel = resolvedTokenizationViewModel as? NolPayTokenizationViewModel else {
                return
            }
            tokenizationViewModel.nolPayCardNumber = cardNumber
            tokenizationViewModel.mobileNumber = mobileNumber
            tokenizationViewModel.mobileCountryCode = countryCode

            tokenizationViewModel.triggerAsyncAction = { (transactionNumber: String, completion: ((Result<Bool, Error>) -> Void)?) in
                #if canImport(PrimerNolPaySDK)

                nolPay.requestPayment(for: cardNumber, and: transactionNumber) { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case let .success(success):
                        if success {
                            self.nextDataStep = .paymentRequested
                            self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                            completion?(.success(true))
                        } else {
                            let error = handled(primerError: .nolError(code: "unknown", message: "Payment failed from unknown reason"))
                            self.errorDelegate?.didReceiveError(error: error)
                            completion?(.failure(error))
                        }
                    case let .failure(error):
                        let error = handled(primerError: .nolError(code: error.errorCode, message: error.description))
                        self.errorDelegate?.didReceiveError(error: error)
                        completion?(.failure(error))
                    }
                }
                #endif
            }
            tokenizationViewModel.start()

        default:
            break
        }
    }

    public func start() {
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.paymentStartMethod,
            params: ["category": "NOL_PAY"]
        )
        Analytics.Service.fire(events: [sdkEvent])

        guard let nolPaymentMethodOption = PrimerAPIConfiguration.current?.paymentMethods?
                .first(where: { $0.internalPaymentMethodType == .nolPay })?
                .options as? MerchantOptions,
              let nolPayAppId = nolPaymentMethodOption.appId
        else {
            return makeAndHandleInvalidValueError(forKey: "nolPayAppId")
        }

        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            errorDelegate?.didReceiveError(error: handled(primerError: .invalidClientToken()))
            return
        }

        let isSandbox = clientToken.env != "PRODUCTION"
        var isDebug = false
        #if DEBUG
        isDebug = PrimerLogging.shared.logger.logLevel == .debug
        #endif

        #if canImport(PrimerNolPaySDK)
        nolPay = PrimerNolPay(appId: nolPayAppId, isDebug: isDebug, isSandbox: isSandbox) { sdkId, deviceId in

            let requestBody = await Request.Body.NolPay.NolPaySecretDataRequest(nolSdkId: deviceId,
                                                                                nolAppId: sdkId,
                                                                                phoneVendor: "Apple",
                                                                                phoneModel: UIDevice.modelIdentifier!)

            return try await withCheckedThrowingContinuation { continuation in
                self.apiClient.fetchNolSdkSecret(clientToken: clientToken, paymentRequestBody: requestBody) { result in
                    switch result {
                    case let .success(appSecret): continuation.resume(returning: appSecret.sdkSecret)
                    case let .failure(error): continuation.resume(throwing: handled(error: error))
                    }
                }
            }
        }
        #else
        let error = handled(primerError: .missingSDK(paymentMethodType: PrimerPaymentMethodType.nolPay.rawValue, sdkName: "PrimerNolPaySDK"))
        errorDelegate?.didReceiveError(error: handled(primerError: error))
        #endif
    }
}

// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
