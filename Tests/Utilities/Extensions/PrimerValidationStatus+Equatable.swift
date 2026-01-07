//
//  PrimerValidationStatus+Equatable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

extension PrimerValidationStatus: @retroactive Equatable {

    public static func == (lhs: PrimerValidationStatus, rhs: PrimerValidationStatus) -> Bool {
        switch (lhs, rhs) {
        case (.validating, .validating):
            return true
        case (.valid, .valid):
            return true
        case let (.invalid(errorsLHS), .invalid(errorsRHS)):
            return errorsLHS == errorsRHS
        case let (.error(errorLHS), .error(errorRHS)):
            return errorLHS.errorCode == errorRHS.errorCode
        default:
            return false
        }
    }
}

extension PrimerValidationError: @retroactive Equatable {
    public static func == (lhs: PrimerValidationError, rhs: PrimerValidationError) -> Bool {
        switch (lhs, rhs) {
        case let (.invalidCardholderName(message1, id1), .invalidCardholderName(message2, id2)),
             let (.invalidCardnumber(message1, id1), .invalidCardnumber(message2, id2)),
             let (.invalidCvv(message1, id1), .invalidCvv(message2, id2)),
             let (.invalidExpiryDate(message1, id1), .invalidExpiryDate(message2, id2)),
             let (.invalidPostalCode(message1, id1), .invalidPostalCode(message2, id2)),
             let (.invalidFirstName(message1, id1), .invalidFirstName(message2, id2)),
             let (.invalidLastName(message1, id1), .invalidLastName(message2, id2)),
             let (.invalidAddress(message1, id1), .invalidAddress(message2, id2)),
             let (.invalidState(message1, id1), .invalidState(message2, id2)),
             let (.invalidCountry(message1, id1), .invalidCountry(message2, id2)),
             let (.invalidPhoneNumber(message1, id1), .invalidPhoneNumber(message2, id2)),
             let (.invalidOTPCode(message1, id1), .invalidOTPCode(message2, id2)),
             let (.invalidCardType(message1, id1), .invalidCardType(message2, id2)):
            return message1 == message2 && id1 == id2
        case let (.invalidRawData(id1), .invalidRawData(id2)),
             let (.banksNotLoaded(id1), .banksNotLoaded(id2)),
             let (.sessionNotCreated(id1), .sessionNotCreated(id2)),
             let (.invalidPaymentCategory(id1), .invalidPaymentCategory(id2)),
             let (.paymentAlreadyFinalized(id1), .paymentAlreadyFinalized(id2)):
            return id1 == id2
        case let (.vaultedPaymentDataMismatch(type1, validType1, id1),
              .vaultedPaymentDataMismatch(type2, validType2, id2)):
            return type1 == type2 && validType1 == validType2 && id1 == id2
        case let (.invalidBankId(bankId1, diagnosticsId: id1),
              .invalidBankId(bankId2, diagnosticsId: id2)):
            return bankId1 == bankId2 && id1 == id2
        default:
            return false
        }
    }
}
