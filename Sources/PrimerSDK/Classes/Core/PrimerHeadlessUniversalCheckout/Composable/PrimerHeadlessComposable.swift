//
//  PrimerHeadlessComposable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public protocol PrimerCollectableData { }

public protocol PrimerHeadlessStep { }

public protocol PrimerHeadlessErrorableDelegate: AnyObject {
    func didReceiveError(error: PrimerError)
}

public protocol PrimerHeadlessValidatableDelegate: AnyObject {
    func didUpdate(validationStatus: PrimerValidationStatus, for data: PrimerCollectableData?)
}

public protocol PrimerHeadlessSteppableDelegate: AnyObject {
    func didReceiveStep(step: PrimerHeadlessStep)
}

protocol PrimerHeadlessAnalyticsRecordable {
    func recordEvent(type: Analytics.Event.EventType, name: String, params: [String: String])
}

@objc public protocol PrimerHeadlessStartable: AnyObject {
    func start()
}

@objc public protocol PrimerHeadlessSubmitable: AnyObject {
    func submit()
}

public enum PrimerValidationStatus {
    case validating
    case valid
    case invalid(errors: [PrimerValidationError])
    case error(error: PrimerError)
}

public protocol PrimerHeadlessCollectDataComponent<Data, Step>: PrimerHeadlessStartable, PrimerHeadlessSubmitable {
    associatedtype Data: PrimerCollectableData
    associatedtype Step: PrimerHeadlessStep
    var errorDelegate: PrimerHeadlessErrorableDelegate? { get set }
    var validationDelegate: PrimerHeadlessValidatableDelegate? { get set }
    var stepDelegate: PrimerHeadlessSteppableDelegate? { get set }
    var nextDataStep: Step { get }
    func updateCollectedData(collectableData: Data)
    func submit()
    func start()
    func makeAndHandleInvalidValueError(forKey key: String)
    func makeAndHandleNolPayInitializationError()
}

extension PrimerHeadlessCollectDataComponent {
    public func makeAndHandleInvalidValueError(forKey key: String) {
        errorDelegate?.didReceiveError(error: handled(primerError: .invalidValue(key: key)))
    }

    public func handleReceivedError(error: PrimerError) {
        PrimerDelegateProxy.primerDidFailWithError(handled(primerError: error), data: nil) { _ in }
        errorDelegate?.didReceiveError(error: error)
    }

    public func makeAndHandleNolPayInitializationError() {
        errorDelegate?.didReceiveError(error: handled(primerError: .nolSdkInitError()))
    }

}

extension PrimerHeadlessAnalyticsRecordable {
    func recordEvent(
        type: Analytics.Event.EventType,
        name: String,
        params: [String: String]
    ) {
        let event = Analytics.Event.sdk(name: name, params: params)
        Analytics.Service.record(events: [event])
    }
}
