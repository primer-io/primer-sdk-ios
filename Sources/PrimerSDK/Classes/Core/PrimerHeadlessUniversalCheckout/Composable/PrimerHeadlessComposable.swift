//
//  PrimerHeadlessComposable.swift
//  PrimerSDK
//
//  Created by Boris on 13.9.23..
//

import Foundation

public protocol PrimerHeadlessComponent { }

public protocol PrimerCollectableData { }

public protocol PrimerHeadlessErrorableDelegate: AnyObject {
    func didReceiveError(error: Error)
}

public protocol PrimerHeadlessValidatableDelegate: AnyObject {
    func didValidate(validations: [Error], for data: PrimerCollectableData)
}

public protocol PrimerHeadlessStep { }

public protocol PrimerHeadlessStepableDelegate: AnyObject {
    func didReceiveStep(step: PrimerHeadlessStep)
}

public protocol PrimerHeadlessCollectDataComponent: PrimerHeadlessComponent {
    associatedtype T: PrimerCollectableData
    var errorDelegate: PrimerHeadlessErrorableDelegate? { get set }
    var validationDelegate: PrimerHeadlessValidatableDelegate? { get set }
    var stepDelegate: PrimerHeadlessStepableDelegate? { get set }
    func updateCollectedData(data: T)
    func submit()
    func start()
}
