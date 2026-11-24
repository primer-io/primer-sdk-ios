//
//  MockAnalyticsInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
@testable import PrimerSDK

@available(iOS 15.0, *)
actor MockAnalyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol {

    func trackEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {}

    func recordThreeDSOutcome(_ outcome: AnalyticsFunnelState.ThreeDSOutcome) async {}
}
