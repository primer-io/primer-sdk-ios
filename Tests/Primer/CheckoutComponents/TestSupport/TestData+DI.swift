//
//  TestData+DI.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
extension TestData {

    // MARK: - Dependency Injection

    enum DI {
        static let defaultValue = "default"
        static let fallbackValue = "fallback"
        static let resolvedValue = "resolved_value"
        static let envResolvedValue = "env_resolved"
        static let resolveTestValue = "resolve_test"
        static let defaultIdentifier = "default"
        static let fallbackIdentifier = "fallback"
        static let fromContainerIdentifier = "from-container"
        static let cachedPrefix = "cached-"
        static let protocolFallbackValue = "protocol_fallback"
        static let observableDefaultValue = "observable_default"
        static let envFallbackValue = "env_fallback"
        static let fallbackValueAlternate = "fallback_value"
    }

    // MARK: - DI Container

    enum DIContainer {
        enum Timing {
            static let oneSecondNanoseconds: UInt64 = 1_000_000_000
            static let oneMillisecondNanoseconds: UInt64 = 1_000_000
        }

        enum Duration {
            static let oneMs: TimeInterval = 0.001
            static let twoMs: TimeInterval = 0.002
            static let threeMs: TimeInterval = 0.003
            static let fiveMs: TimeInterval = 0.005
            static let tenMs: TimeInterval = 0.010
        }

        enum Factory {
            static let testIdPrefix = "test-"
            static let syncIdPrefix = "sync-"
            static let voidIdPrefix = "void-"
            static let syncVoidIdPrefix = "sync-void-"
            static let asyncSyncIdPrefix = "async-sync-"
            static let defaultMultiplier = 10
            static let largeMultiplier = 100
            static let factoryName1 = "factory-1"
            static let factoryName2 = "factory-2"
            static let namedClosure = "named-closure"
            static let closureTestId = "closure-test"
        }

        enum Values {
            static let expectedValue = 42
            static let multiplier3 = 3
            static let multiplier4 = 4
            static let multiplier5 = 5
            static let multiplier7 = 7
        }
    }

}
