//
//  LogPayload.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct LogPayload: Codable, Sendable {
    public let message: String
    public let hostname: String
    public let service: String
    public let ddsource: String
    public let ddtags: String

    public init(
        message: String,
        hostname: String,
        service: String = "ios-sdk",
        ddsource: String = "lambda",
        ddtags: String
    ) {
        self.message = message
        self.hostname = hostname
        self.service = service
        self.ddsource = ddsource
        self.ddtags = ddtags
    }
}

public struct DeviceInfoMetadata: Codable, Sendable {
    public let model: String
    public let osVersion: String
    public let locale: String
    public let timezone: String
    public let networkType: String

    public init(model: String, osVersion: String, locale: String, timezone: String, networkType: String) {
        self.model = model
        self.osVersion = osVersion
        self.locale = locale
        self.timezone = timezone
        self.networkType = networkType
    }
}

public struct AppMetadata: Codable, Sendable {
    public let appName: String
    public let appVersion: String
    public let bundleId: String

    public init(appName: String, appVersion: String, bundleId: String) {
        self.appName = appName
        self.appVersion = appVersion
        self.bundleId = bundleId
    }
}

public struct SessionMetadata: Codable, Sendable {
    public let flowType: String
    public let paymentIntent: String
    public let features: [String]

    public init(flowType: String, paymentIntent: String, features: [String]) {
        self.flowType = flowType
        self.paymentIntent = paymentIntent
        self.features = features
    }
}
