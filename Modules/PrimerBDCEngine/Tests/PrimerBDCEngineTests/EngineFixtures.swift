//
//  EngineFixtures.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable @_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

extension EngineFiles {
    static let emptyModule = Data([0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00])

    static func stub(wasm: Data = emptyModule) -> EngineFiles {
        EngineFiles(
            celWrapperJS: """
            let wasm_bindgen = async (buffer) => {
                await WebAssembly.instantiate(buffer);
                globalThis.__instantiated = true;
            };
            """,
            stateProcessorJS: """
            var StateProcessor = {
                createStateProcessor: async (schema, context) => {
                    if (schema === 'throw') throw new Error('bad schema');
                    const instantiated = globalThis.__instantiated === true;
                    return {
                        initialize: async (state) => ({ call: 'initialize', schema, sdkType: context.sdk.type, state, instantiated }),
                        applyEvent: async (state, event) => ({ call: 'applyEvent', state, event }),
                        applyResult: async (state, actionId, outcome, data) => ({ call: 'applyResult', actionId, outcome, data }),
                    };
                },
                probesToRun: async (items) => items.map((item) => ({ key: item.id, probe: 'canOpenURL', params: {} })),
                checkClientRequirements: async () => ({ satisfied: true, unmet: [] }),
            };
            """,
            celWrapperWASM: wasm
        )
    }
}

extension BDCClient {
    static var stub: BDCClient { BDCClient(capabilities: SDKCapabilities(), context: .stub) }
}

extension SDKContext {
    static var stub: SDKContext {
        SDKContext(
            sdk: SDK(type: "IOS_NATIVE", version: "1.0", integrationType: "DROP_IN", paymentHandling: "AUTO"),
            device: SDKDevice(
                platform: "IOS",
                type: nil,
                make: "Apple",
                model: "iPhone",
                modelIdentifier: nil,
                platformVersion: "17.0",
                uniqueDeviceIdentifier: "test",
                locale: "en"
            ),
            app: SDKApp(identifier: "com.test"),
            session: SDKSession(checkoutSessionId: nil, clientSessionId: nil, customerId: nil),
            payment: SDKPayment(paymentMethodType: "PAYMENT_CARD"),
            merchant: SDKMerchant(primerAccountId: nil),
            analytics: SDKAnalytics(url: nil)
        )
    }
}
