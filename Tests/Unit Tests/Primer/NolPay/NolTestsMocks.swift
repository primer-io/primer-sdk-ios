//
//  NolTestsMocks.swift
//  Debug App Tests
//
//  Created by Boris on 27.10.23..
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerNolPaySDK)
import XCTest
import PrimerNolPaySDK
@testable import PrimerSDK

//class MockPrimerNolPay: PrimerNolPayProtocol {
//
//    // Mock responses for the mock methods
//    var mockCardNumber: String = "1234567890123456"
//    var mockError: PrimerNolPayError = PrimerNolPayError(description: "Mock Error")
//    var mockBoolResponse: Bool = true
//    var mockOTPResponse: (String, String) = ("mockOTP", "mockToken")
//    var mockCards: [PrimerNolPayCard] = [PrimerNolPayCard(cardNumber: "1234567890123456", expiredTime: "12/34")]
//
//    required init(appId: String, isDebug: Bool, isSandbox: Bool, appSecretHandler: @escaping (String, String) async throws -> String) {
//    }
//
//    func scanNFCCard(completion: @escaping (Result<String, PrimerNolPayError>) -> Void) {
//        completion(.success(mockCardNumber))
//    }
//
//    func makeLinkingToken(for cardNumber: String, completion: @escaping (Result<String, PrimerNolPayError>) -> Void) {
//        completion(.success("mockLinkingToken"))
//    }
//
//    func sendLinkOTP(to mobileNumber: String, with countryCode: String, and token: String, completion: ((Result<Bool, PrimerNolPayError>) -> Void)?) {
//        completion?(.success(mockBoolResponse))
//    }
//
//    func linkCard(for otp: String, and linkToken: String, completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void) {
//        completion(.success(mockBoolResponse))
//    }
//
//    func sendUnlinkOTP(to mobileNumber: String, with countryCode: String, and cardNumber: String, completion: @escaping (Result<(String, String), PrimerNolPayError>) -> Void) {
//        completion(.success(mockOTPResponse))
//    }
//
//    func unlinkCard(with cardNumber: String, otp: String, and unlinkToken: String, completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void) {
//        completion(.success(mockBoolResponse))
//    }
//
//    func requestPayment(for cardNumber: String, and transactionNumber: String, completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void) {
//        completion(.success(mockBoolResponse))
//    }
//
//    func getAvailableCards(for mobileNumber: String, with countryCode: String, completion: @escaping (Result<[PrimerNolPayCard], PrimerNolPayError>) -> Void) {
//        if mockCards.count > 0 {
//            completion(.success(mockCards))
//        } else {
//            completion(.failure(PrimerNolPayError.nolPaySdkError(message: "Failed")))
//        }
//    }
//}

class MockPhoneMetadataService: NolPayPhoneMetadataProviding {
    var resultToReturn: Result<(PrimerValidationStatus, String?, String?), PrimerError>?

    func getPhoneMetadata(mobileNumber: String, completion: @escaping PhoneMetadataCompletion) {
        if let result = resultToReturn {
            completion(result)
        }
    }
}

class MockValidationDelegate: PrimerHeadlessValidatableDelegate {
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        validationsReceived = validationStatus
        if case let .invalid(errors) = validationStatus {
            validationErrorsReceived = errors
        }
        wasValidatedCalled = true
    }

    var validationsReceived: PrimerSDK.PrimerValidationStatus?
    var wasValidatedCalled = false
    var validationErrorsReceived: [PrimerValidationError] = []
}

class MockStepDelegate: PrimerHeadlessSteppableDelegate {
    var stepReceived: PrimerHeadlessStep?

    func didReceiveStep(step: PrimerHeadlessStep) {
        stepReceived = step
    }
}

class MockErrorDelegate: PrimerHeadlessErrorableDelegate {
    var errorReceived: Error?

    func didReceiveError(error: PrimerSDK.PrimerError) {
        errorReceived = error
    }
}

class MockNolPayTokenizationViewModel: NolPayTokenizationViewModel {

    // Mock response values
    var mockValidateError: Error?
    var mockTokenizationResult: Result<PrimerPaymentMethodTokenData, Error>?
    var mockAwaitUserInputResult: Result<Void, Error>?
    var mockPresentPaymentMethodUIResult: Result<Void, Error>?
    var mockHandleDecodedClientTokenResult: Result<String?, Error>?
    var mockPreTokenizationStepsResult: Result<Void, Error>?
    var mockTokenizationStepResult: Result<Void, Error>?
    var mockPostTokenizationStepsResult: Result<Void, Error>?
    var resultToReturn: Result<Bool, Error>?

    override func validate() throws {
        if let error = mockValidateError {
            throw error
        }
    }

    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        switch resultToReturn {
        case .success:
            return .value(Response.Body.Tokenization(analyticsId: "1",
                                                     id: "1",
                                                     isVaulted: false,
                                                     isAlreadyVaulted: false,
                                                     paymentInstrumentType: PaymentInstrumentType.unknown,
                                                     paymentMethodType: "NOL_PAY",
                                                     paymentInstrumentData: nil,
                                                     threeDSecureAuthentication: nil,
                                                     token: "123qwe",
                                                     tokenType: nil,
                                                     vaultData: nil))
        case .failure(let error):
            return .init(error: error)
        default:
            return super.tokenize() // fallback to the real implementation
        }
    }

    override func awaitUserInput() -> Promise<Void> {
        switch mockAwaitUserInputResult {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        default:
            return .value(()) // Default stubbed value
        }
    }

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        switch mockPresentPaymentMethodUIResult {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        default:
            return .value(()) // Default stubbed value
        }
    }

    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken, paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
        switch mockHandleDecodedClientTokenResult {
        case .success(let token):
            return .value(token)
        case .failure(let error):
            return .init(error: error)
        default:
            return .value(nil) // Default stubbed value
        }
    }

    override func performPreTokenizationSteps() -> Promise<Void> {
        switch mockPreTokenizationStepsResult {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        default:
            return .value(()) // Default stubbed value
        }
    }

    override func performTokenizationStep() -> Promise<Void> {
        switch mockTokenizationStepResult {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        default:
            return .value(()) // Default stubbed value
        }
    }

    override func performPostTokenizationSteps() -> Promise<Void> {
        switch mockPostTokenizationStepsResult {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        default:
            return .value(()) // Default stubbed value
        }
    }

    override func submitButtonTapped() {
        // No-op for mock
    }
}
#endif
