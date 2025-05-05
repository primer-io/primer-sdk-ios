//
//  NolPayPaymentComponent.swift
//  PrimerSDK
//
//  Created by Boris on 18.9.23..
//

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

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

public class NolPayPaymentComponent: PrimerHeadlessCollectDataComponent {
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
        if let tokenizationViewModel {
            return tokenizationViewModel
        }
        return PrimerAPIConfiguration.paymentMethodConfigViewModels
            .filter { $0.config.type == PrimerPaymentMethodType.nolPay.rawValue }
            .first as? NolPayTokenizationViewModel
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
        case .paymentData(let cardNumber, let mobileNumber):
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
        Analytics.Service.record(events: [sdkEvent])

        switch data {
        case .paymentData(cardNumber: let cardNumber,
                          mobileNumber: let mobileNumber):

            if cardNumber.isEmpty || !cardNumber.isNumeric {
                errors.append(PrimerValidationError.invalidCardnumber(
                    message: "Card number is not valid.",
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                ))
                ErrorHandler.handle(error: errors.last!)
            }

            phoneMetadataService.getPhoneMetadata(mobileNumber: mobileNumber) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success((let validationStatus, let countryCode, let mobileNumber)):
                    switch validationStatus {
                    case .valid:
                        if errors.isEmpty {
                            self.countryCode = countryCode
                            self.mobileNumber = mobileNumber
                            self.validationDelegate?.didUpdate(validationStatus: .valid, for: data)
                        } else {
                            self.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
                        }

                    case .invalid(errors: let validationErrors):
                        errors += validationErrors
                        self.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)

                    default: break
                    }
                case .failure(let error):
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
        Analytics.Service.record(events: [sdkEvent])

        switch nextDataStep {
        case .collectCardAndPhoneData:
            guard let cardNumber else {
                makeAndHandleInvalidValueError(forKey: "cardNumber")
                return
            }

            guard let mobileNumber else {
                makeAndHandleInvalidValueError(forKey: "mobileNumber")
                return
            }

            guard let countryCode else {
                makeAndHandleInvalidValueError(forKey: "countryCode")
                return
            }

            #if canImport(PrimerNolPaySDK)
            guard let nolPay else {
                makeAndHandleNolPayInitializationError()
                return
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
                    case .success(let success):
                        if success {
                            self.nextDataStep = .paymentRequested
                            self.stepDelegate?.didReceiveStep(step: self.nextDataStep)
                            completion?(.success(true))
                        } else {
                            let error = PrimerError.nolError(code: "unknown",
                                                             message: "Payment failed from unknown reason",
                                                             userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: error)
                            self.errorDelegate?.didReceiveError(error: error)
                            completion?(.failure(error))
                        }
                    case .failure(let error):
                        let error = PrimerError.nolError(code: error.errorCode,
                                                         message: error.description,
                                                         userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: error)
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
        Analytics.Service.record(events: [sdkEvent])

        guard let nolPaymentMethodOption = PrimerAPIConfiguration.current?.paymentMethods?
                .first(where: { $0.internalPaymentMethodType == .nolPay })?
                .options as? MerchantOptions,
              let nolPayAppId = nolPaymentMethodOption.appId
        else {
            makeAndHandleInvalidValueError(forKey: "nolPayAppId")
            return
        }

        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            errorDelegate?.didReceiveError(error: err)
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
                    case .success(let appSecret):
                        continuation.resume(returning: appSecret.sdkSecret)
                    case .failure(let error):
                        ErrorHandler.handle(error: error)
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        #else
        let error = PrimerError.missingSDK(
            paymentMethodType: PrimerPaymentMethodType.nolPay.rawValue,
            sdkName: "PrimerNolPaySDK",
            userInfo: .errorUserInfoDictionary(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        errorDelegate?.didReceiveError(error: error)
        #endif
    }
}

// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
