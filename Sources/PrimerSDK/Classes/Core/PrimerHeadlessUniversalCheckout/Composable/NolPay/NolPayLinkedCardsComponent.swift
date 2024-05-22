//
//  NolPayLinkedCardsComponent.swift
//  PrimerSDK
//
//  Created by Boris on 15.9.23..
//

// swiftlint:disable function_body_length

import UIKit
#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
#endif

public class NolPayLinkedCardsComponent {

    #if canImport(PrimerNolPaySDK)
    var nolPay: PrimerNolPayProtocol?
    #endif
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    var mobileNumber: String?
    var countryCode: String?
    var phoneMetadataService: NolPayPhoneMetadataProviding?

    let apiClient: PrimerAPIClientProtocol

    public convenience init() {
        self.init(apiClient: PrimerAPIClient())
    }

    init(apiClient: PrimerAPIClientProtocol) {
        self.apiClient = apiClient
    }

    public func getLinkedCardsFor(mobileNumber: String, completion: @escaping (Result<[PrimerNolPaymentCard], PrimerError>) -> Void) {

        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()  // Enter the dispatch group

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

    private func start(completion: @escaping (Result<Void, PrimerError>) -> Void) {
        guard let nolPaymentMethodOption = PrimerAPIConfiguration.current?.paymentMethods?
                .first(where: { $0.internalPaymentMethodType == .nolPay})?
                .options as? MerchantOptions,
              let appId = nolPaymentMethodOption.appId
        else {
            let error = PrimerError.invalidValue(key: "Nol AppID",
                                                 value: nil,
                                                 userInfo: .errorUserInfoDictionary(),
                                                 diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: error)
            self.errorDelegate?.didReceiveError(error: error)
            return
        }

        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            return
        }

        let isSandbox = clientToken.env != "PRODUCTION"
        var isDebug = false
        #if DEBUG
        isDebug =  PrimerLogging.shared.logger.logLevel == .debug
        #endif

        #if canImport(PrimerNolPaySDK)

        guard nolPay == nil
        else {
            completion(.success(()))
            return
        }

        nolPay = PrimerNolPay(appId: appId, isDebug: isDebug, isSandbox: isSandbox) { sdkId, deviceId in

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
        phoneMetadataService = phoneMetadataService ?? NolPayPhoneMetadataService()
        #endif

    }

    private func continueWithLinkedCardsFetch(mobileNumber: String,
                                              completion: @escaping (Result<[PrimerNolPaymentCard], PrimerError>) -> Void) {

        let sdkEvent = Analytics.Event.sdk(
            name: NolPayAnalyticsConstants.linkedCardsGetCardsMethod,
            params: [ "category": "NOL_PAY" ]
        )
        Analytics.Service.record(events: [sdkEvent])
        #if canImport(PrimerNolPaySDK)

        guard let nolPay = nolPay else {
            let error = PrimerError.nolError(code: "unknown",
                                             message: "error.description",
                                             userInfo: .errorUserInfoDictionary(),
                                             diagnosticsId: UUID().uuidString)
            self.errorDelegate?.didReceiveError(error: error)
            ErrorHandler.handle(error: error)
            completion(.failure(error))
            return
        }
        #endif

        phoneMetadataService?.getPhoneMetadata(mobileNumber: mobileNumber) { [weak self] result in
            switch result {

            case let .success((validationStatus, countryCode, mobileNumber)):
                switch validationStatus {

                case .valid:

                    guard let parsedMobileNumber = mobileNumber else {
                        let error = PrimerError.invalidValue(key: "mobileNumber",
                                                             value: nil,
                                                             userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: error)
                        self?.errorDelegate?.didReceiveError(error: error)
                        return
                    }

                    guard let countryCode = countryCode else {
                        let error = PrimerError.invalidValue(key: "countryCode",
                                                             value: nil,
                                                             userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: error)
                        self?.errorDelegate?.didReceiveError(error: error)
                        return
                    }
                    #if canImport(PrimerNolPaySDK)
                    nolPay.getAvailableCards(for: parsedMobileNumber, with: countryCode) { result in
                        switch result {

                        case .success(let cards):
                            completion(.success(PrimerNolPaymentCard.makeFrom(arrayOf: cards)))
                        case .failure(let error):
                            let error = PrimerError.nolError(code: error.errorCode,
                                                             message: error.description,
                                                             userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                            self?.errorDelegate?.didReceiveError(error: error)
                            ErrorHandler.handle(error: error)
                            completion(.failure(error))
                        }
                    }
                    #endif

                case .invalid(errors: let validationErrors):
                    self?.validationDelegate?.didUpdate(validationStatus: .invalid(errors: validationErrors), for: nil)
                default: break
                }
            case .failure(let error):
                self?.errorDelegate?.didReceiveError(error: error)
            }
        }
    }
}
// swiftlint:enable function_body_length
