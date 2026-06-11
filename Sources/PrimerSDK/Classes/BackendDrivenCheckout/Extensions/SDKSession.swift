//
//  SDKSession.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

extension SDKSession {
    init(configuration: PrimerAPIConfiguration?, sessionId: String?) {
        self.init(
            checkoutSessionId: sessionId,
            clientSessionId: configuration?.clientSession?.clientSessionId,
            customerId: configuration?.clientSession?.customer?.id
        )
    }
}
