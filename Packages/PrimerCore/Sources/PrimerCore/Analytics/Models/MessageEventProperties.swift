//
//  MessageEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct MessageEventProperties: AnalyticsEventProperties {

    public let message: String?
    public let messageType: Analytics.Event.Property.MessageType
    public let severity: Analytics.Event.Property.Severity
    public let diagnosticsId: String?
    public let context: [String: Any]?

    private enum CodingKeys: String, CodingKey {
        case message
        case messageType
        case severity
        case diagnosticsId
        case context
    }
    
    public init (
        message: String? = nil,
        messageType: Analytics.Event.Property.MessageType = .info,
        severity: Analytics.Event.Property.Severity = .info,
        diagnosticsId: String? = nil,
        context: [String: Any]? = nil
    ) {
        self.message = message
        self.messageType = messageType
        self.severity = severity
        self.diagnosticsId = diagnosticsId
        self.context = context
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.messageType = try container.decode(Analytics.Event.Property.MessageType.self, forKey: .messageType)
        self.severity = try container.decode(Analytics.Event.Property.Severity.self, forKey: .severity)
        self.diagnosticsId = try container.decodeIfPresent(String.self, forKey: .diagnosticsId)
        self.context = try container.decodeIfPresent([String: Any].self, forKey: .context)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encode(messageType, forKey: .messageType)
        try container.encode(severity, forKey: .severity)
        try container.encodeIfPresent(diagnosticsId, forKey: .diagnosticsId)
        try container.encodeIfPresent(context, forKey: .context)
    }
}
