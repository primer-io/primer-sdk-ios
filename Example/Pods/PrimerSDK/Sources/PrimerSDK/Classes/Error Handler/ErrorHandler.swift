//
//  ErrorHandler.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

#if canImport(UIKit)

import Foundation

internal class ErrorHandler {

    static var shared = ErrorHandler()

    // swiftlint:disable cyclomatic_complexity function_body_length
    func handle(error: Error) -> Bool {
        log(logLevel: .error, title: "ERROR!", message: error.localizedDescription, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)

        if let networkServiceError = error as? NetworkServiceError {
            switch networkServiceError {
            default:
                break
            }

        } else if let primerError = error as? PrimerError {
            switch primerError {
            case .generic:
                break
            case .clientTokenNull:
                break
            case .customerIDNull:
                break
            case .clientTokenExpired:
                break
            case .payPalSessionFailed:
                break
            case .vaultFetchFailed:
                break
            case .vaultDeleteFailed:
                break
            case .vaultCreateFailed:
                break
            case .directDebitSessionFailed:
                break
            case .configFetchFailed:
                break
            case .tokenizationPreRequestFailed:
                break
            case .tokenizationRequestFailed:
                break
            case .threeDSFailed:
                break
            case .failedToLoadSession:
                break
            case .missingURLScheme:
                break
            case .requestFailed:
                break
            case .userCancelled:
                break
            case .amountCannotBeNullForNonPendingOrderItems:
                break
            case .amountShouldBeNullForPendingOrderItems:
                break
            case .currencyMissing:
                break
            case .amountMissing:
                break
            case .billingAddressMissing:
                break
            case .billingAddressCityMissing:
                break
            case .billingAddressPostalCodeMissing:
                break
            case .billingAddressCountryCodeMissing:
                break
            case .orderIdMissing:
                break
            case .billingAddressAddressLine1Missing:
                break
            case .userDetailsMissing:
                break
            case .userDetailsAddressMissing:
                break
            case .userDetailsCityMissing:
                break
            case .userDetailsAddressLine1Missing:
                break
            case .userDetailsPostalCodeMissing:
                break
            case .userDetailsCountryCodeMissing:
                break
            case .dataMissing:
                break
            case .directoryServerIdMissing:
                break
            case .threeDSSDKKeyMissing:
                break
            default:
                break
            }

        } else if let klarnaException = error as? KlarnaException {
            switch klarnaException {
            default:
                break
            }

        } else {
            let nsError = error as NSError
        }

        return false
    }

}

#endif
