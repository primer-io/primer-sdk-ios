//
//  PrimerHeadlessComposable.swift
//  PrimerSDK
//
//  Created by Boris on 13.9.23..
//

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

public enum PrimerValidationStatus: Equatable {

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
}

extension PrimerHeadlessCollectDataComponent {
    public func makeAndHandleInvalidValueError(forKey key: String) {
        let error = PrimerError.invalidValue(key: key,
                                             value: nil,
                                             userInfo: .errorUserInfoDictionary(),
        diagnosticsId: UUID().uuidString)
        ErrorHandler.handle(error: error)
        self.errorDelegate?.didReceiveError(error: error)
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
