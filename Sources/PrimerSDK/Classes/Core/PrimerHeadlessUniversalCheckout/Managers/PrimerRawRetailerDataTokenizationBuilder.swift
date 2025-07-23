//
//  PrimerRawRetailerDataTokenizationBuilder.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 18/10/22.
//

// swiftlint:disable function_body_length

import Foundation

// MARK: MISSING_TESTS
final class PrimerRawRetailerDataTokenizationBuilder: PrimerRawDataTokenizationBuilderProtocol {

    var rawData: PrimerRawData? {
        didSet {
            if let rawRetailerData = self.rawData as? PrimerRetailerData {
                rawRetailerData.onDataDidChange = { [weak self] in
                    guard let self = self else { return }
                    _ = self.validateRawData(rawRetailerData)
                }
            }

            if let rawData = self.rawData {
                _ = self.validateRawData(rawData)
            }
        }
    }

    weak var rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
    var isDataValid: Bool = false
    var paymentMethodType: String
    var delegate: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate?

    var requiredInputElementTypes: [PrimerInputElementType] {
        [.retailer]
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
                return seal.reject(handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType)))
            }

            guard let rawData = data as? PrimerRetailerData else {
                return seal.reject(handled(primerError: .invalidValue(key: "rawData")))
            }

            let sessionInfo = RetailOutletTokenizationSessionRequestParameters(retailOutlet: rawData.id)

            let paymentInstrument = OffSessionPaymentInstrument(
                paymentMethodConfigId: paymentMethodId,
                paymentMethodType: paymentMethodType,
                sessionInfo: sessionInfo)

            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            seal.fulfill(requestBody)
        }
    }

    func makeRequestBodyWithRawData(_ data: PrimerRawData) async throws -> Request.Body.Tokenization {
        guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType), let paymentMethodId = paymentMethod.id else {
            throw handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethodType))
        }

        guard let rawData = data as? PrimerRetailerData else {
            throw handled(primerError: .invalidValue(key: "rawData"))
        }

        return Request.Body.Tokenization(
            paymentInstrument: OffSessionPaymentInstrument(
                paymentMethodConfigId: paymentMethodId,
                paymentMethodType: paymentMethodType,
                sessionInfo: RetailOutletTokenizationSessionRequestParameters(retailOutlet: rawData.id)
            )
        )
    }

    func validateRawData(_ data: PrimerRawData) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.global(qos: .userInteractive).async {
                var errors: [PrimerValidationError] = []

                guard let rawData = data as? PrimerRetailerData else {
                    let err = handled(error: PrimerValidationError.invalidRawData())
                    errors.append(err)
                    self.notifyDelegateOfValidationResult(isValid: false, errors: errors)

                    DispatchQueue.main.async { seal.reject(err) }

                    return
                }

                if rawData.id.isEmpty {
                    errors.append(PrimerValidationError.invalidRawData())
                }

                if !errors.isEmpty {
                    self.notifyDelegateOfValidationResult(isValid: false, errors: errors)

                    DispatchQueue.main.async {
                        seal.reject(handled(primerError: .underlyingErrors(errors: errors)))
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

    func validateRawData(_ data: PrimerRawData) async throws {
        var errors: [PrimerValidationError] = []

        guard let rawData = data as? PrimerRetailerData else {
            let err = PrimerValidationError.invalidRawData()
            errors.append(err)
            notifyDelegateOfValidationResult(isValid: false, errors: errors)
            throw handled(error: err)
        }

        if rawData.id.isEmpty {
            errors.append(PrimerValidationError.invalidRawData())
        }

        guard errors.isEmpty else {
            notifyDelegateOfValidationResult(isValid: false, errors: errors)
            throw handled(primerError: .underlyingErrors(errors: errors))
        }

        notifyDelegateOfValidationResult(isValid: true, errors: nil)
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
// swiftlint:enable function_body_length
