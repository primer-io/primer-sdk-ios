//
//  StoredEvent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

enum StoredEvent: Codable {
    case sdk(Analytics.Event)
    case raw(RawAnalyticsEvent)
    
    var analyticsUrl: String? {
        switch self {
        case let .sdk(event): event.analyticsUrl
        case let .raw(event): event.analyticsUrl
        }
    }
    
    var localId: String {
        switch self {
        case let .sdk(event): event.localId
        case let .raw(event): event.localId
        }
    }
    
    var createdAt: Int {
        switch self {
        case let .sdk(event): event.createdAt
        case let .raw(event): event.createdAt
        }
    }
    
    init?(_ event: any AnalyticsEvent) {
        if let sdkEvent = event as? Analytics.Event {
            self = .sdk(sdkEvent)
        } else if let rawEvent = event as? RawAnalyticsEvent {
            self = .raw(rawEvent)
        } else {
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decodeIfPresent(Kind.self, forKey: .kind) ?? .sdk
        switch kind {
        case .sdk: self = .sdk(try Analytics.Event(from: decoder))
        case .raw: self = .raw(try RawAnalyticsEvent(from: decoder))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .sdk(event):
            try container.encode(Kind.sdk, forKey: .kind)
            try event.encode(to: encoder)
        case let .raw(event):
            try container.encode(Kind.raw, forKey: .kind)
            try event.encode(to: encoder)
        }
    }
}

extension StoredEvent: Equatable {
    static func == (lhs: StoredEvent, rhs: StoredEvent) -> Bool {
        lhs.localId == rhs.localId
    }
}

private extension StoredEvent {
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    private enum Kind: String, Codable {
        case sdk, raw
    }
}

extension Array where Element == StoredEvent {
    func partitioned() -> (sdk: [Analytics.Event], raw: [RawAnalyticsEvent]) {
        var sdk: [Analytics.Event] = []
        var raw: [RawAnalyticsEvent] = []
        for event in self {
            switch event {
            case let .sdk(e): sdk.append(e)
            case let .raw(e): raw.append(e)
            }
        }
        return (sdk, raw)
    }
}
