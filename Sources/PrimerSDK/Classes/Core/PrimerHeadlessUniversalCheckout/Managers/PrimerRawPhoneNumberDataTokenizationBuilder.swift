//
//  PrimerRawPhoneNumberDataTokenizationBuilder.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length
// swiftlint:disable type_name

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking

final class PrimerRawPhoneNumberDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {

    var rawData: PrimerRawData? {
        didSet {
            if let rawPhoneNumberInput = rawData as? PrimerPhoneNumberData {
                rawPhoneNumberInput.onDataDidChange = { [weak self] in
                    guard let self else { return }
                    Task { try? await self.validateRawData(rawPhoneNumberInput) }
                }
            }

            if let rawData {
                Task { try? await self.validateRawData(rawData) }
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

    private let apiClient: PrimerAPIClientProtocol

    // Android submits the shopper's own string too — the lookup is only a yes/no.
    private var approvedInput: String?

    private var validationTask: CancellableTask<Response.Body.PhoneMetadata.PhoneMetadataDataResponse>?

    required init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
        apiClient = PrimerAPIClient()
    }

    init(paymentMethodType: String, apiClient: PrimerAPIClientProtocol) {
        self.paymentMethodType = paymentMethodType
        self.apiClient = apiClient
    }

    func configure(withRawDataManager rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager) {
        self.rawDataManager = rawDataManager
    }

    func makeRequestBodyWithRawData(_ data: PrimerRawData) async throws -> Request.Body.Tokenization {
        guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType), let paymentMethodId = paymentMethod.id else {
            throw handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType))
        }

        guard let rawData = data as? PrimerPhoneNumberData else {
            throw handled(primerError: .invalidValue(key: "rawData"))
        }

        guard approvedInput == rawData.phoneNumber else {
            throw handled(primerError: .invalidValue(key: "phoneNumber"))
        }

        return Request.Body.Tokenization(
            paymentInstrument: OffSessionPaymentInstrument(
                paymentMethodConfigId: paymentMethodId,
                paymentMethodType: paymentMethodType,
                sessionInfo: InputPhonenumberSessionInfo(phoneNumber: rawData.phoneNumber)
            )
        )
    }

    func validateRawData(_ data: PrimerRawData) async throws {
        guard let rawData = data as? PrimerPhoneNumberData else {
            let err = PrimerValidationError.invalidRawData()
            invalidate(with: err)
            throw handled(error: err)
        }

        let input = rawData.phoneNumber

        // New input supersedes any lookup still in flight, including when it is rejected below —
        // otherwise the old lookup lands afterwards and reports valid for a number that has gone.
        // Clearing first also means the cancelled task no longer sees itself as current.
        let superseded = validationTask
        validationTask = nil
        await superseded?.cancel(with: PrimerError.cancelled(paymentMethodType: paymentMethodType))

        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw invalidated(PrimerValidationError.invalidPhoneNumber(message: "Phone number cannot be blank."))
        }

        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw invalidated(PrimerError.invalidClientToken())
        }

        let task = CancellableTask {
            try await self.apiClient.getPhoneMetadata(
                clientToken: clientToken,
                paymentRequestBody: Request.Body.PhoneMetadata.PhoneMetadataDataRequest(phoneNumber: input)
            )
        }
        validationTask = task

        let response: Response.Body.PhoneMetadata.PhoneMetadataDataResponse
        do {
            response = try await task.wait()
        } catch {
            guard validationTask === task else { return }
            validationTask = nil
            throw invalidated(error.asPrimerError)
        }

        guard validationTask === task else { return }
        validationTask = nil

        // Android requires the parsed parts too, though neither platform submits them.
        guard response.isValid, response.countryCode != nil, response.nationalNumber != nil else {
            throw invalidated(PrimerValidationError.invalidPhoneNumber(message: "Phone number is not valid."))
        }

        approvedInput = input

        notifyDelegateOfValidationResult(isValid: true, errors: nil)
    }

    private func invalidate(with error: Error) {
        approvedInput = nil
        notifyDelegateOfValidationResult(isValid: false, errors: [error])
    }

    // Generic: `asPrimerError` would flatten a PrimerValidationError to PrimerError.unknown.
    private func invalidated<E: Error>(_ error: E) -> E {
        invalidate(with: error)
        return handled(error: error)
    }

    private func notifyDelegateOfValidationResult(isValid: Bool, errors: [Error]?) {
        isDataValid = isValid

        DispatchQueue.main.async { [weak self] in
            guard let self, let rawDataManager else { return }

            rawDataManager.delegate?.primerRawDataManager?(
                rawDataManager,
                dataIsValid: isValid,
                errors: errors
            )
        }
    }
}
// swiftlint:enable type_name
// swiftlint:enable function_body_length
