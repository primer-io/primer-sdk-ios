//
//  PrimerHeadlessComposable.swift
//  PrimerSDK
//
//  Created by Boris on 13.9.23..
//

import Foundation

public protocol PrimerHeadlessComponent {
    var stepDelegate: PrimerHeadlessSteppableDelegate? { get set }
}

extension PrimerHeadlessComponent {
    func getViewModel<T>(
        with configType: String,
        viewModelType: T.Type = T.self
    ) -> T? where T: PaymentMethodTokenizationViewModel {
        return PrimerAPIConfiguration.paymentMethodConfigViewModels.filter({
            $0.config.type == configType
        }).first as? T
    }
}

public protocol PrimerCollectableData { }

public protocol PrimerHeadlessErrorableDelegate: AnyObject {
    func didReceiveError(error: PrimerError)
}

public protocol PrimerHeadlessValidatableDelegate: AnyObject {
    func didUpdate(validationStatus: PrimerValidationStatus, for data: PrimerCollectableData?)
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

public protocol PrimerHeadlessStep { }

public protocol PrimerHeadlessSteppableDelegate: AnyObject {
    func didReceiveStep(step: PrimerHeadlessStep)
}

public protocol PrimerHeadlessCollectDataComponent: PrimerHeadlessComponent {
    associatedtype T: PrimerCollectableData
    
    var validationDelegate: PrimerHeadlessValidatableDelegate? { get set }
    var errorDelegate: PrimerHeadlessErrorableDelegate? { get set }
    
    func updateCollectedData(collectableData: T)
    func submit()
    func start()
}

extension PrimerHeadlessCollectDataComponent {
    public func submit() {
        debugPrint("Override functionality if required")
    }
}

protocol PrimerHeadlessAnalyticsRecordable {
    func recordEvent(type: Analytics.Event.EventType, name: String, params: [String: String])
}

extension PrimerHeadlessAnalyticsRecordable {
    func recordEvent(
        type: Analytics.Event.EventType,
        name: String,
        params: [String: String]
    ) {
        let event = Analytics.Event(
            eventType: type,
            properties: SDKEventProperties(
                name: name,
                params: params
            )
        )
        Analytics.Service.record(events: [event])
    }
}
