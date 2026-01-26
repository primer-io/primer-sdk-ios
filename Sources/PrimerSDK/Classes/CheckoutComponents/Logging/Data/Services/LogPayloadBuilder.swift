//
//  LogPayloadBuilder.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import UIKit

// MARK: - Protocol

protocol LogPayloadBuilding {
    func buildInfoPayload(
        message: String,
        event: String,
        userInfo: [String: Any]?,
        sessionData: LoggingSessionContext.SessionData
    ) throws -> LogPayload

    func buildErrorPayload(
        message: String,
        errorMessage: String?,
        diagnosticsId: String?,
        stack: String?,
        event: String?,
        userInfo: [String: Any]?,
        sessionData: LoggingSessionContext.SessionData
    ) throws -> LogPayload
}

// MARK: - Implementation

struct LogPayloadBuilder: LogPayloadBuilding {
    // MARK: - Constants

    private enum Constants {
        static let unknownValue = "Unknown"
        static let statusInfo = "info"
        static let statusError = "error"
        static let serviceIosSdk = "ios-sdk"
        static let sourceLambda = "lambda"
        static let intentCheckout = "checkout"
        static let intentVault = "vault"
        static let intentUnknown = "unknown"
        static let initDurationMsKey = "init_duration_ms"
    }

    // MARK: - Public Methods

    func buildInfoPayload(
        message: String,
        event: String,
        userInfo: [String: Any]?,
        sessionData: LoggingSessionContext.SessionData
    ) throws -> LogPayload {
        // Extract known keys from userInfo
        let initDurationMs = userInfo?[Constants.initDurationMsKey] as? Int

        // Build custom fields from remaining userInfo (excluding known keys)
        let customFields = Self.buildCustomFields(from: userInfo, excludingKeys: [Constants.initDurationMsKey])

        let logMessageObject = LogMessageObject(
            message: message,
            status: Constants.statusInfo,
            event: event,
            primer: Self.buildPrimerIdentifiers(sessionData: sessionData),
            initDurationMs: initDurationMs,
            deviceInfo: Self.buildDeviceInfoMetadata(),
            appMetadata: Self.buildAppMetadata(),
            sessionMetadata: Self.buildSessionMetadata(sessionData: sessionData)
        )

        let jsonMessage = try Self.encodeToJSONString(logMessageObject, customFields: customFields)
        return Self.buildLogPayload(jsonMessage: jsonMessage, sessionData: sessionData)
    }

    func buildErrorPayload(
        message: String,
        errorMessage: String?,
        diagnosticsId: String?,
        stack: String?,
        event: String?,
        userInfo: [String: Any]?,
        sessionData: LoggingSessionContext.SessionData
    ) throws -> LogPayload {
        // Build custom fields from userInfo
        let customFields = Self.buildCustomFields(from: userInfo, excludingKeys: [])

        let logMessageObject = LogMessageObject(
            message: message,
            status: Constants.statusError,
            event: event,
            primer: Self.buildPrimerIdentifiers(sessionData: sessionData),
            errorMessage: errorMessage,
            diagnosticsId: diagnosticsId,
            stack: stack,
            deviceInfo: Self.buildDeviceInfoMetadata(),
            appMetadata: Self.buildAppMetadata(),
            sessionMetadata: Self.buildSessionMetadata(sessionData: sessionData)
        )

        let jsonMessage = try Self.encodeToJSONString(logMessageObject, customFields: customFields)
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
            appId: Bundle.main.bundleIdentifier ?? Constants.unknownValue
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
            paymentIntent: buildPaymentIntent(),
            availablePaymentMethods: buildAvailablePaymentMethods(),
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

    private static func encodeToJSONString<T: Encodable>(
        _ value: T,
        customFields: [String: Any]? = nil
    ) throws -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys]

        let data = try encoder.encode(value)

        // If no custom fields, return as-is
        guard let customFields, !customFields.isEmpty else {
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw LoggingError.encodingFailed
            }
            return jsonString
        }

        // Merge custom fields at root level
        guard var dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LoggingError.encodingFailed
        }

        // Add custom fields as-is (merchants control their key format)
        for (key, value) in customFields {
            dictionary[key] = value
        }

        // Re-encode with sorted keys
        let mergedData = try JSONSerialization.data(
            withJSONObject: dictionary,
            options: [.sortedKeys]
        )

        guard let jsonString = String(data: mergedData, encoding: .utf8) else {
            throw LoggingError.encodingFailed
        }
        return jsonString
    }

    // MARK: - Private Helpers - UserInfo Processing

    private static func buildCustomFields(
        from userInfo: [String: Any]?,
        excludingKeys: [String]
    ) -> [String: Any]? {
        guard let userInfo, !userInfo.isEmpty else { return nil }

        let filteredEntries = userInfo.filter { !excludingKeys.contains($0.key) }
        guard !filteredEntries.isEmpty else { return nil }

        return filteredEntries
    }
}

// MARK: - Errors

enum LoggingError: Error {
    case encodingFailed
    case networkError
}
