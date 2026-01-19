//
//  LogPayloadBuilder.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import UIKit

struct LogPayloadBuilder {
    // MARK: - Constants

    private enum Constants {
        static let unknownValue = "Unknown"
        static let statusInfo = "info"
        static let statusError = "error"
        static let serviceIosSdk = "ios-sdk"
        static let sourceLambda = "lambda"
        static let flowTypeCheckoutComponents = "checkout_components"
        static let intentCheckout = "checkout"
        static let intentVault = "vault"
        static let intentUnknown = "unknown"
    }

    // MARK: - Public Methods

    func buildInfoPayload(
        message: String,
        event: String,
        initDurationMs: Int?,
        sessionData: LoggingSessionContext.SessionData
    ) throws -> LogPayload {
        let logMessageObject = LogMessageObject(
            message: message,
            status: Constants.statusInfo,
            primer: Self.buildPrimerIdentifiers(sessionData: sessionData),
            deviceInfo: Self.buildDeviceInfoMetadata(),
            event: event,
            initDurationMs: initDurationMs,
            appMetadata: Self.buildAppMetadata(),
            sessionMetadata: Self.buildSessionMetadata(sessionData: sessionData)
        )

        let jsonMessage = try Self.encodeToJSONString(logMessageObject)
        return Self.buildLogPayload(jsonMessage: jsonMessage, sessionData: sessionData)
    }

    func buildErrorPayload(
        message: String,
        errorMessage: String?,
        errorStack: String?,
        sessionData: LoggingSessionContext.SessionData
    ) throws -> LogPayload {
        let logMessageObject = LogMessageObject(
            message: message,
            status: Constants.statusError,
            primer: Self.buildPrimerIdentifiers(sessionData: sessionData),
            deviceInfo: Self.buildDeviceInfoMetadata(),
            errorMessage: errorMessage,
            errorStack: errorStack,
            appMetadata: Self.buildAppMetadata(),
            sessionMetadata: Self.buildSessionMetadata(sessionData: sessionData)
        )

        let jsonMessage = try Self.encodeToJSONString(logMessageObject)
        return Self.buildLogPayload(jsonMessage: jsonMessage, sessionData: sessionData)
    }

    // MARK: - Private Helpers - Metadata Building

    private static func buildDDTags(sessionData: LoggingSessionContext.SessionData) -> String {
        "env:\(sessionData.environment.rawValue),version:\(sessionData.sdkVersion)"
    }

    private static func buildAppMetadata() -> AppMetadata {
        AppMetadata(
            appName: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Constants.unknownValue,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? Constants.unknownValue,
            bundleId: Bundle.main.bundleIdentifier ?? Constants.unknownValue
        )
    }

    private static func buildPaymentIntent() -> String {
        switch PrimerInternal.shared.intent {
        case .checkout: Constants.intentCheckout
        case .vault: Constants.intentVault
        case .none: Constants.intentUnknown
        }
    }

    private static func buildAvailablePaymentMethods() -> [String] {
        PrimerAPIConfiguration.current?.paymentMethods?
            .compactMap { $0.internalPaymentMethodType?.rawValue } ?? []
    }

    private static func buildSessionMetadata(sessionData: LoggingSessionContext.SessionData) -> SessionMetadata {
        SessionMetadata(
            flowType: Constants.flowTypeCheckoutComponents,
            paymentIntent: buildPaymentIntent(),
            features: buildAvailablePaymentMethods(),
            integrationType: sessionData.integrationType?.rawValue
        )
    }

    private static func buildPrimerIdentifiers(
        sessionData: LoggingSessionContext.SessionData
    ) -> LogMessageObject.PrimerIdentifiers {
        LogMessageObject.PrimerIdentifiers(
            checkoutSessionId: sessionData.checkoutSessionId,
            clientSessionId: sessionData.clientSessionId,
            primerAccountId: sessionData.primerAccountId,
            customerId: PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.customer?.id
        )
    }

    private static func buildLogPayload(
        jsonMessage: String,
        sessionData: LoggingSessionContext.SessionData
    ) -> LogPayload {
        LogPayload(
            message: jsonMessage,
            hostname: sessionData.hostname,
            service: Constants.serviceIosSdk,
            ddsource: Constants.sourceLambda,
            ddtags: buildDDTags(sessionData: sessionData)
        )
    }

    // MARK: - Private Helpers - Device Information

    private static func buildDeviceInfoMetadata() -> DeviceInfoMetadata {
        DeviceInfoMetadata(
            model: UIDevice.modelIdentifier ?? Constants.unknownValue,
            osVersion: UIDevice.current.systemVersion,
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier,
            networkType: Connectivity.networkType.rawValue
        )
    }

    private static func encodeToJSONString<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys]

        let data = try encoder.encode(value)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw LoggingError.encodingFailed
        }
        return jsonString
    }
}

// MARK: - Errors

enum LoggingError: Error {
    case encodingFailed
}
