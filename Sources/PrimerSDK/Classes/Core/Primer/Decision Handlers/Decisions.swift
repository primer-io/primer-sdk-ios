//
//  ErrorDecision.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 02/05/22.
//

import Foundation

// MARK: - ERROR DECISION

@objc public class PrimerErrorDecision: NSObject {

    public enum DecisionType {
        case fail(errorMessage: String?)
    }

    var type: DecisionType

    private init(type: DecisionType) {
        self.type = type
    }
}

public extension PrimerErrorDecision {

    static func fail(withErrorMessage message: String?) -> PrimerErrorDecision {
        PrimerErrorDecision(type: .fail(errorMessage: message))
    }
}

// MARK: - RESUME DECISION

public protocol PrimerResumeDecisionProtocol: NSObject {
    var type: PrimerResumeDecisionTypeProtocol { get set }
}

public protocol PrimerResumeDecisionTypeProtocol {}

@objc public class PrimerResumeDecision: NSObject, PrimerResumeDecisionProtocol {

    public enum DecisionType: PrimerResumeDecisionTypeProtocol {
        case succeed
        case fail(errorMessage: String?)
        case continueWithNewClientToken(_ newClientToken: String)
    }

    public var type: PrimerResumeDecisionTypeProtocol

    private init(type: DecisionType) {
        self.type = type
    }
}

public extension PrimerResumeDecision {

    static func succeed() -> PrimerResumeDecision {
        PrimerResumeDecision(type: .succeed)
    }

    static func fail(withErrorMessage message: String?) -> PrimerResumeDecision {
        PrimerResumeDecision(type: .fail(errorMessage: message))
    }

    static func continueWithNewClientToken(_ newClientToken: String) -> PrimerResumeDecision {
        PrimerResumeDecision(type: .continueWithNewClientToken(newClientToken))
    }
}

// MARK: - HUC RESUME DECISION
// swiftlint:disable:next type_name
@objc public class PrimerHeadlessUniversalCheckoutResumeDecision: NSObject, PrimerResumeDecisionProtocol {

    public enum DecisionType: PrimerResumeDecisionTypeProtocol {
        case continueWithNewClientToken(_ newClientToken: String)
        case complete
    }

    public var type: PrimerResumeDecisionTypeProtocol

    private init(type: DecisionType) {
        self.type = type
    }
}

public extension PrimerHeadlessUniversalCheckoutResumeDecision {

    static func continueWithNewClientToken(_ newClientToken: String) -> PrimerHeadlessUniversalCheckoutResumeDecision {
        PrimerHeadlessUniversalCheckoutResumeDecision(type: .continueWithNewClientToken(newClientToken))
    }

    static func complete() -> PrimerHeadlessUniversalCheckoutResumeDecision {
        PrimerHeadlessUniversalCheckoutResumeDecision(type: .complete)
    }
}

// MARK: - PAYMENT DECISION

@objc public class PrimerPaymentCreationDecision: NSObject {

    public enum DecisionType {
        case abort(errorMessage: String?)
        case `continue`
    }

    var type: DecisionType

    private init(type: DecisionType) {
        self.type = type
    }
}

public extension PrimerPaymentCreationDecision {

    static func abortPaymentCreation(withErrorMessage message: String? = nil) -> PrimerPaymentCreationDecision {
        PrimerPaymentCreationDecision(type: .abort(errorMessage: message))
    }

    static func continuePaymentCreation() -> PrimerPaymentCreationDecision {
        PrimerPaymentCreationDecision(type: .continue)
    }
}
