//
//  ClientRequirements.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

/// Verdicts by payment method id.
@_spi(PrimerInternal)
public typealias ClientRequirementsVerdicts = [String: ClientRequirementsCheck]

/// What the state processor checks requirements against.
@_spi(PrimerInternal)
public struct BDCClient: Encodable {
    public let capabilities: SDKCapabilities
    public let context: SDKContext

    public init(capabilities: SDKCapabilities, context: SDKContext) {
        self.capabilities = capabilities
        self.context = context
    }
}

/// A backend-driven method, as the state processor checks it.
@_spi(PrimerInternal)
public struct ClientRequirementsItem: Encodable, Equatable {
    public let id: String
    public let type: String
    /// As received; nil gets the processor's legacy defaults.
    public let clientRequirements: CodableValue?

    public init(id: String, type: String, clientRequirements: CodableValue?) {
        self.id = id
        self.type = type
        self.clientRequirements = clientRequirements
    }
}

@_spi(PrimerInternal)
public struct ClientRequirementsCheck: Decodable, Equatable {
    public let satisfied: Bool
    public let unmet: [UnmetClientRequirement]

    public init(satisfied: Bool, unmet: [UnmetClientRequirement] = []) {
        self.satisfied = satisfied
        self.unmet = unmet
    }
}

/// Strings rather than enums, so a new kind or reason still decodes.
@_spi(PrimerInternal)
public struct UnmetClientRequirement: Codable, Equatable {
    public let kind: String
    public let type: String?
    public let name: String
    public let required: String?
    public let available: String?
    public let reason: String

    public init(
        kind: String,
        type: String? = nil,
        name: String,
        required: String? = nil,
        available: String? = nil,
        reason: String
    ) {
        self.kind = kind
        self.type = type
        self.name = name
        self.required = required
        self.available = available
        self.reason = reason
    }
}
