//
//  ThreeDSObserverReport.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Keeps what one 3DS run reports to the observer, because the begin-auth response arrives in a callback.
final class ThreeDSObserverReport {

    private weak var observer: RequiredActionObserver?
    private var beginAuthOutcome: (responseCode: ThreeDS.ResponseCode, skippedReasonCode: String?)?
    private var challengeProtocolVersion: String?

    init(observer: RequiredActionObserver?) {
        self.observer = observer
    }

    func beginAuthResponded(with authentication: ThreeDSAuthenticationProtocol) {
        // A reason this SDK does not know decodes as the generic `Authentication`.
        let skippedReasonCode = (authentication as? ThreeDS.SkippedAPIResponse)?.skippedReasonCode.rawValue
            ?? (authentication as? ThreeDS.Authentication)?.skippedReasonCode
        beginAuthOutcome = (authentication.responseCode, skippedReasonCode)
        challengeProtocolVersion = (authentication as? ThreeDS.AppV2ChallengeAPIResponse)?.protocolVersion
    }

    func challengeShown(provider: String) async {
        await observer?.threeDSChallengeShown(provider: provider, protocolVersion: challengeProtocolVersion)
    }

    /// Without a challenge, the begin-auth outcome is the result.
    func noChallengeNeeded() async {
        guard let beginAuthOutcome else { return }
        await completed(beginAuthOutcome.responseCode, skippedReasonCode: beginAuthOutcome.skippedReasonCode)
    }

    func continued(with authentication: ThreeDS.Authentication?) async {
        guard let authentication else { return }
        await completed(authentication.responseCode, skippedReasonCode: authentication.skippedReasonCode)
    }

    private func completed(_ responseCode: ThreeDS.ResponseCode, skippedReasonCode: String?) async {
        guard [.authSuccess, .authFailed, .skipped].contains(responseCode) else { return }
        await observer?.threeDSCompleted(authenticationOutcome: responseCode.rawValue, skippedReasonCode: skippedReasonCode)
    }
}
