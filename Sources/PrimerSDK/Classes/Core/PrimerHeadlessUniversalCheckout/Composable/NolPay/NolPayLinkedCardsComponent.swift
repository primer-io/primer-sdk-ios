//
//  NolPayLinkedCardsComponent.swift
//  PrimerSDK
//
//  Created by Boris on 15.9.23..
//

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

import UIKit
#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
#endif

public final class NolPayLinkedCardsComponent {
    #if canImport(PrimerNolPaySDK)
    var nolPay: PrimerNolPayProtocol?
    #endif
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?

    private var mobileNumber: String?
    private var countryCode: String?

    private let apiClient: PrimerAPIClientProtocol
    private let phoneMetadataService: NolPayPhoneMetadataServiceProtocol

    public convenience init() {
        self.init(apiClient: PrimerAPIClient(), phoneMetadataService: NolPayPhoneMetadataService())
    }

    init(apiClient: PrimerAPIClientProtocol, phoneMetadataService: NolPayPhoneMetadataServiceProtocol) {
        self.apiClient = apiClient
        self.phoneMetadataService = phoneMetadataService
    }

    public func getLinkedCardsFor(mobileNumber: String, completion: @escaping (Result<[PrimerNolPaymentCard], PrimerError>) -> Void) {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter() // Enter the dispatch group

        // Start the initial setup
        start { [weak self] result in
            defer {
                dispatchGroup.leave() // Leave the dispatch group when done
            }

            switch result {
            case .success:
                break
            case .failure(let error):
                self?.errorDelegate?.didReceiveError(error: error)
                completion(.failure(error))
                return
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            // This block is executed once the start function is complete
            self?.continueWithLinkedCardsFetch(mobileNumber: mobileNumber, completion: completion)
        }
    }

    func start(completion: @escaping (Result<Void, PrimerError>) -> Void) {
        guard let nolPaymentMethodOption = PrimerAPIConfiguration.current?.paymentMethods?
                .first(where: { $0.internalPaymentMethodType == .nolPay })?
                .options as? MerchantOptions,
              let nolPayAppId = nolPaymentMethodOption.appId
        else {
            let error = PrimerError.invalidValue(key: "nolPayAppId",
                                                 value: nil,
                                                 userInfo: .errorUserInfoDictionary(),
                                                 diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: error)
            errorDelegate?.didReceiveError(error: error)
            completion(.failure(error))
            return
        }

        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            errorDelegate?.didReceiveError(error: err)
            completion(.failure(err))
            return
        }

        let isSandbox = clientToken.env != "PRODUCTION"
        var isDebug = false
        #if DEBUG
        isDebug = PrimerLogging.shared.logger.logLevel == .debug
        #endif

        #if canImport(PrimerNolPaySDK)

        guard nolPay == nil else {
            completion(.success(()))
            return
        }

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
                        completion(.success(()))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                        let primerError = PrimerError.underlyingErrors(errors: [error],
                                                                       userInfo: .errorUserInfoDictionary(),
                                                                       diagnosticsId: UUID().uuidString)
                        completion(.failure(primerError))
                    }
                }
            }
        }
        #endif
    }

    func continueWithLinkedCardsFetch(mobileNumber: String,
                                      completion: @escaping (Result<[PrimerNolPaymentCard], PrimerError>) -> Void) {
        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.linkedCardsGetCardsMethod,
            params: ["category": "NOL_PAY"]
        )
        Analytics.Service.record(events: [sdkEvent])
        #if canImport(PrimerNolPaySDK)

        guard let nolPay else {
            let error = PrimerError.nolSdkInitError(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            errorDelegate?.didReceiveError(error: error)
            ErrorHandler.handle(error: error)
            completion(.failure(error))
            return
        }

        #endif

        phoneMetadataService.getPhoneMetadata(mobileNumber: mobileNumber) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success((let validationStatus, let countryCode, let mobileNumber)):
                switch validationStatus {
                case .valid:

                    guard let mobileNumber else {
                        let error = PrimerError.invalidValue(key: "mobileNumber",
                                                             value: nil,
                                                             userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: error)
                        self.errorDelegate?.didReceiveError(error: error)
                        completion(.failure(error))
                        return
                    }

                    guard let countryCode else {
                        let error = PrimerError.invalidValue(key: "countryCode",
                                                             value: nil,
                                                             userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: error)
                        self.errorDelegate?.didReceiveError(error: error)
                        completion(.failure(error))
                        return
                    }
                    #if canImport(PrimerNolPaySDK)
                    nolPay.getAvailableCards(for: mobileNumber, with: countryCode) { result in
                        switch result {
                        case .success(let cards):
                            completion(.success(PrimerNolPaymentCard.makeFrom(arrayOf: cards)))
                        case .failure(let error):
                            let error = PrimerError.nolError(code: error.errorCode,
                                                             message: error.description,
                                                             userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                            self.errorDelegate?.didReceiveError(error: error)
                            ErrorHandler.handle(error: error)
                            completion(.failure(error))
                        }
                    }
                    #endif

                case .invalid(errors: let validationErrors):
                    self.validationDelegate?.didUpdate(validationStatus: .invalid(errors: validationErrors), for: nil)

                    let err = PrimerError.underlyingErrors(errors: validationErrors,
                                                           userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
                    completion(.failure(err))

                default: break
                }
            case .failure(let error):
                self.errorDelegate?.didReceiveError(error: error)
                completion(.failure(error))
            }
        }
    }
}

// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
