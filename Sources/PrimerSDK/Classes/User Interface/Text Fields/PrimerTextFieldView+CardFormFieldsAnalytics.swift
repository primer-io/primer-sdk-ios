//
//  PrimerTextFieldView+CardFormFieldsAnalytics.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

extension PrimerTextFieldView {

    internal func cardFormFieldDidBeginEditingEventWithObjectId(_ objectId: Analytics.Event.Property.ObjectId) -> Analytics.Event {
        Analytics.Event.ui(
            action: .focus,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
                url: nil),
            extra: nil,
            objectType: .input,
            objectId: objectId,
            objectClass: "\(Self.self)",
            place: .cardForm
        )
    }

    internal func cardFormFieldDidEndEditingEventWithObjectId(_ objectId: Analytics.Event.Property.ObjectId) -> Analytics.Event {
        Analytics.Event.ui(
            action: .blur,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
                url: nil),
            extra: nil,
            objectType: .input,
            objectId: objectId,
            objectClass: "\(Self.self)",
            place: .cardForm
        )
    }
}
