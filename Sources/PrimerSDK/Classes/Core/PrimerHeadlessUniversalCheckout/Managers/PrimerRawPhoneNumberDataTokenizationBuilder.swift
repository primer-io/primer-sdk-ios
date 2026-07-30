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

    // The input the lookup approved. Like Android, the lookup is a yes/no — the shopper's own
    // string is what gets submitted, so both platforms send the same value.
    private var approvedInput: String?

    // One lookup per keystroke; the newest supersedes any still in flight.
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

        // Only submit a number the lookup approved, and only while it is still what's on screen.
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
        // Register before cancelling: the cancelled task resumes immediately, and if it still saw
        // itself as current it would report a verdict instead of standing down.
        let superseded = validationTask
        validationTask = task
        await superseded?.cancel(with: handled(primerError: .cancelled(paymentMethodType: paymentMethodType)))

        let response: Response.Body.PhoneMetadata.PhoneMetadataDataResponse
        do {
            response = try await task.wait()
        } catch {
            // A newer keystroke replaced us, so there is no verdict to report.
            guard validationTask === task else { return }
            validationTask = nil
            // asPrimerError also keeps InternalError out of merchant callbacks.
            throw invalidated(error.asPrimerError)
        }

        guard validationTask === task else { return }
        validationTask = nil

        // Android requires the parsed parts too before treating a number as valid, even though
        // neither platform submits them.
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

    // Generic so the concrete type survives: `asPrimerError` would turn a PrimerValidationError
    // into PrimerError.unknown, and wrapping in `underlyingErrors` hid types in monitoring.
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
