//
//  PrimerTextFieldView+CardFormFieldsAnalytics.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 07/06/22.
//



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


