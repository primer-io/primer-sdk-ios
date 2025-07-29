//
//  PrimerValidationStatus+Equatable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

extension PrimerValidationStatus: Equatable {

    public static func == (lhs: PrimerValidationStatus, rhs: PrimerValidationStatus) -> Bool {
        switch (lhs, rhs) {
        case (.validating, .validating):
            return true
        case (.valid, .valid):
            return true
        case (.invalid(let errorsLHS), .invalid(let errorsRHS)):
            return errorsLHS == errorsRHS
        case (.error(let errorLHS), .error(let errorRHS)):
            return errorLHS.errorCode == errorRHS.errorCode
        default:
            return false
        }
    }
}

extension PrimerValidationError: Equatable {
    public static func == (lhs: PrimerValidationError, rhs: PrimerValidationError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCardholderName(let message1, let userInfo1, let id1), .invalidCardholderName(let message2, let userInfo2, let id2)),
             (.invalidCardnumber(let message1, let userInfo1, let id1), .invalidCardnumber(let message2, let userInfo2, let id2)),
             (.invalidCvv(let message1, let userInfo1, let id1), .invalidCvv(let message2, let userInfo2, let id2)),
             (.invalidExpiryDate(let message1, let userInfo1, let id1), .invalidExpiryDate(let message2, let userInfo2, let id2)),
             (.invalidPostalCode(let message1, let userInfo1, let id1), .invalidPostalCode(let message2, let userInfo2, let id2)),
             (.invalidFirstName(let message1, let userInfo1, let id1), .invalidFirstName(let message2, let userInfo2, let id2)),
             (.invalidLastName(let message1, let userInfo1, let id1), .invalidLastName(let message2, let userInfo2, let id2)),
             (.invalidAddress(let message1, let userInfo1, let id1), .invalidAddress(let message2, let userInfo2, let id2)),
             (.invalidState(let message1, let userInfo1, let id1), .invalidState(let message2, let userInfo2, let id2)),
             (.invalidCountry(let message1, let userInfo1, let id1), .invalidCountry(let message2, let userInfo2, let id2)),
             (.invalidPhoneNumber(let message1, let userInfo1, let id1), .invalidPhoneNumber(let message2, let userInfo2, let id2)),
             (.invalidRetailer(let message1, let userInfo1, let id1), .invalidRetailer(let message2, let userInfo2, let id2)),
             (.invalidOTPCode(let message1, let userInfo1, let id1), .invalidOTPCode(let message2, let userInfo2, let id2)),
             (.invalidCardType(let message1, let userInfo1, let id1), .invalidCardType(let message2, let userInfo2, let id2)):
            return message1 == message2 && userInfo1 == userInfo2 && id1 == id2
        case (.invalidRawData(let userInfo1, let id1), .invalidRawData(let userInfo2, let id2)),
             (.banksNotLoaded(let userInfo1, let id1), .banksNotLoaded(let userInfo2, let id2)),
             (.sessionNotCreated(let userInfo1, let id1), .sessionNotCreated(let userInfo2, let id2)),
             (.invalidPaymentCategory(let userInfo1, let id1), .invalidPaymentCategory(let userInfo2, let id2)),
             (.paymentAlreadyFinalized(let userInfo1, let id1), .paymentAlreadyFinalized(let userInfo2, let id2)):
            return userInfo1 == userInfo2 && id1 == id2
        case (.vaultedPaymentMethodAdditionalDataMismatch(let type1, let validType1, let userInfo1, let id1),
              .vaultedPaymentMethodAdditionalDataMismatch(let type2, let validType2, let userInfo2, let id2)):
            return type1 == type2 && validType1 == validType2 && userInfo1 == userInfo2 && id1 == id2
        case (.invalidBankId(let bankId1, userInfo: let userInfo1, diagnosticsId: let id1),
              .invalidBankId(let bankId2, userInfo: let userInfo2, diagnosticsId: let id2)):
            return bankId1 == bankId2 && userInfo1 == userInfo2 && id1 == id2
        default:
            return false
        }
    }
}
