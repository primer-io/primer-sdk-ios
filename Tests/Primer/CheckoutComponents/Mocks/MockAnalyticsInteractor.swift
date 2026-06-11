//
//  MockAnalyticsInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
actor MockAnalyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol {

    func trackEvent(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) async {}
}
