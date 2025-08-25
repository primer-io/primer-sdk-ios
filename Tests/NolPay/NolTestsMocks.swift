//
//  NolTestsMocks.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK
@testable import PrimerSDK
import XCTest

final class MockPrimerNolPay: PrimerNolPayProtocol {
    // Mock responses for the mock methods
    var mockCards: [PrimerNolPayCard] = [PrimerNolPayCard(cardNumber: "1234567890123456", expiredTime: "12/34")]

    required init(appId: String, isDebug: Bool, isSandbox: Bool, appSecretHandler: @escaping (String, String) async throws -> String) {}

    var scanNFCCardResult: Result<String, PrimerNolPayError>?
    func scanNFCCard(completion: @escaping (Result<String, PrimerNolPayError>) -> Void) {
        guard let scanNFCCardResult else {
            completion(.failure(PrimerNolPayError(description: "Unknown error")))
            return
        }
        completion(scanNFCCardResult)
    }

    var makeLinkingTokenResult: Result<String, PrimerNolPayError>?
    func makeLinkingToken(for cardNumber: String, completion: @escaping (Result<String, PrimerNolPayError>) -> Void) {
        guard let result = makeLinkingTokenResult else {
            completion(.failure(PrimerNolPayError(description: "Unknown error")))
            return
        }
        completion(result)
    }

    var sendLinkOTPResult: Result<Bool, PrimerNolPayError>?
    func sendLinkOTP(to mobileNumber: String, with countryCode: String, and token: String, completion: ((Result<Bool, PrimerNolPayError>) -> Void)?) {
        guard let result = sendLinkOTPResult else {
            completion?(.failure(PrimerNolPayError(description: "Unknown error")))
            return
        }
        completion?(result)
    }

    var linkCardResult: Result<Bool, PrimerNolPayError>?
    func linkCard(for otp: String, and linkToken: String, completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void) {
        guard let result = linkCardResult else {
            completion(.failure(PrimerNolPayError(description: "Unknown error")))
            return
        }
        completion(result)
    }

    var sendUnlinkOTPResult: Result<(String, String), PrimerNolPayError>?
    func sendUnlinkOTP(
        to mobileNumber: String,
        with countryCode: String,
        and cardNumber: String,
        completion: @escaping (Result<(String, String), PrimerNolPayError>)
            -> Void
    ) {
        guard let result = sendUnlinkOTPResult else {
            completion(.failure(PrimerNolPayError(description: "Unknown error")))
            return
        }
        completion(result)
    }

    var unlinkCardResult: Result<Bool, PrimerNolPayError>?
    func unlinkCard(with cardNumber: String, otp: String, and unlinkToken: String, completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void) {
        guard let result = unlinkCardResult else {
            completion(.failure(PrimerNolPayError(description: "Unknown error")))
            return
        }
        completion(result)
    }

    var requestPaymentResult: Result<Bool, PrimerNolPayError>?
    func requestPayment(for cardNumber: String, and transactionNumber: String, completion: @escaping (Result<Bool, PrimerNolPayError>) -> Void) {
        guard let result = requestPaymentResult else {
            completion(.failure(PrimerNolPayError(description: "Unknown error")))
            return
        }
        completion(result)
    }

    var getAvailableCardsResult: Result<[PrimerNolPayCard], PrimerNolPayError>?
    func getAvailableCards(
        for mobileNumber: String,
        with countryCode: String,
        completion: @escaping (Result<[PrimerNolPayCard], PrimerNolPayError>) -> Void
    ) {
        guard let result = getAvailableCardsResult else {
            completion(.failure(PrimerNolPayError(description: "Unknown error")))
            return
        }
        completion(result)
    }
}

class MockPhoneMetadataService: NolPayPhoneMetadataServiceProtocol {
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
        if case .invalid(let errors) = validationStatus {
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
    var validateResult: Result<Void, Error>?
    override func validate() throws {
        guard let result = validateResult else {
            throw PrimerError.unknown()
        }

        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    var mockTokenizationResult: Result<PrimerPaymentMethodTokenData, Error>?
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        guard let result = mockTokenizationResult else {
            return .init(error: PrimerError.unknown())
        }

        switch result {
        case .success(let tokenData):
            return .value(tokenData)
        case .failure(let error):
            return .init(error: error)
        }
    }

    var awaitUserInputResult: Result<Void, Error>?

    override func awaitUserInput() -> Promise<Void> {
        guard let result = awaitUserInputResult else {
            return .init(error: PrimerError.unknown())
        }

        switch result {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        }
    }

    var presentPaymentMethodUserInterfaceResult: Result<Void, Error>?

    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        guard let result = presentPaymentMethodUserInterfaceResult else {
            return .init(error: PrimerError.unknown())
        }

        switch result {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        }
    }

    var handleDecodedClientTokenResult: Result<String?, Error>?

    override func handleDecodedClientTokenIfNeeded(_ decodedJWTToken: DecodedJWTToken,
                                                   paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<String?> {
        guard let result = handleDecodedClientTokenResult else {
            return .init(error: PrimerError.unknown())
        }

        switch result {
        case .success(let token):
            return .value(token)
        case .failure(let error):
            return .init(error: error)
        }
    }

    var performPreTokenizationStepsResult: Result<Void, Error>?

    override func performPreTokenizationSteps() -> Promise<Void> {
        guard let result = performPreTokenizationStepsResult else {
            return .init(error: PrimerError.unknown())
        }

        switch result {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        }
    }

    var performTokenizationStepResult: Result<Void, Error>?

    override func performTokenizationStep() -> Promise<Void> {
        guard let result = performTokenizationStepResult else {
            return .init(error: PrimerError.unknown())
        }

        switch result {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        }
    }

    var performPostTokenizationStepsResult: Result<Void, Error>?

    override func performPostTokenizationSteps() -> Promise<Void> {
        guard let result = performPostTokenizationStepsResult else {
            return .init(error: PrimerError.unknown())
        }

        switch result {
        case .success:
            return .value(())
        case .failure(let error):
            return .init(error: error)
        }
    }

    var onStartCalled: (() -> Void)?
    override func start() {
        onStartCalled?()
    }

    var onSubmitButtonTappedCalled: (() -> Void)?
    override func submitButtonTapped() {
        onSubmitButtonTappedCalled?()
    }
}
#endif
