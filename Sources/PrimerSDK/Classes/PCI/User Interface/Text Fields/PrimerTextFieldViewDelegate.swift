//
//  PrimerTextFieldViewDelegate.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 21/05/2024.
//

import Foundation

/// The PrimerTextFieldViewDelegate protocol can be used to retrieve information about the text input.
/// PrimerCardNumberFieldView, PrimerExpiryDateFieldView, PrimerCVVFieldView & PrimerCardholderNameFieldView
/// all have a delegate of PrimerTextFieldViewDelegate type.
public protocol PrimerTextFieldViewDelegate: AnyObject {
    /// Will return true if valid, false if invalid, nil if it cannot be detected yet.
    /// It is applied on all PrimerTextFieldViews.
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?)
    /// Will return the card network (e.g. Visa) detected, unknown if the network cannot be detected.
    /// Only applies on PrimerCardNumberFieldView
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork?)
    /// Will return a the validation error on the text input.
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error)

    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView)

    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool

    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool

    func primerTextFieldViewDidEndEditing(_ primerTextFieldView: PrimerTextFieldView)
}

public extension PrimerTextFieldViewDelegate {
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {}
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView,
                             didDetectCardNetwork cardNetwork: CardNetwork?) {}
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView,
                             validationDidFailWithError error: Error) {}
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {}
    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool { return true }
    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool { return true }
    func primerTextFieldViewDidEndEditing(_ primerTextFieldView: PrimerTextFieldView) {}
}
