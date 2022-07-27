//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import UIKit

extension PrimerTextFieldView {
    
    internal func cardFormFieldDidBeginEditingEventWithObjectId(_ objectId: Analytics.Event.Property.ObjectId) -> Analytics.Event {
        
        Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .focus,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
                    url: nil),
                extra: nil,
                objectType: .input,
                objectId: objectId,
                objectClass: "\(Self.self)",
                place: .cardForm))
    }

    internal func cardFormFieldDidEndEditingEventWithObjectId(_ objectId: Analytics.Event.Property.ObjectId) -> Analytics.Event {
        
        Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .blur,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
                    url: nil),
                extra: nil,
                objectType: .input,
                objectId: objectId,
                objectClass: "\(Self.self)",
                place: .cardForm))
    }
}

#endif
