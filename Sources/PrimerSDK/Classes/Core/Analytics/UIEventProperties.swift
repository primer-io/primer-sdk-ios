//
//  UIEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerCore

struct UIEventProperties: AnalyticsEventProperties {

    var action: Analytics.Event.Property.Action
    var context: Analytics.Event.Property.Context?
    var extra: String?
    var objectType: Analytics.Event.Property.ObjectType
    var objectId: Analytics.Event.Property.ObjectId?
    var objectClass: String?
    var place: Analytics.Event.Property.Place
    var params: [String: String]?

    private enum CodingKeys: String, CodingKey {
        case action
        case context
        case extra
        case objectType
        case objectId
        case objectClass
        case place
        case params
    }

    init(
        action: Analytics.Event.Property.Action,
        context: Analytics.Event.Property.Context?,
        extra: String?,
        objectType: Analytics.Event.Property.ObjectType,
        objectId: Analytics.Event.Property.ObjectId?,
        objectClass: String?,
        place: Analytics.Event.Property.Place
    ) {
        self.action = action
        self.context = context
        self.extra = extra
        self.objectType = objectType
        self.objectId = objectId
        self.objectClass = objectClass
        self.place = place

        if let jsonData = try? JSONEncoder().encode(SDKProperties()),
           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments),
           let params = jsonObject as? [String: String] {
            self.params = params
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.action = try container.decode(Analytics.Event.Property.Action.self, forKey: .action)
        self.context = try container.decodeIfPresent(Analytics.Event.Property.Context.self, forKey: .context)
        self.extra = try container.decodeIfPresent(String.self, forKey: .extra)
        self.objectType = try container.decode(Analytics.Event.Property.ObjectType.self, forKey: .objectType)
        self.objectId = try container.decodeIfPresent(Analytics.Event.Property.ObjectId.self, forKey: .objectId)
        self.objectClass = try container.decodeIfPresent(String.self, forKey: .objectClass)
        self.place = try container.decode(Analytics.Event.Property.Place.self, forKey: .place)
        self.params = try container.decodeIfPresent([String: String].self, forKey: .params)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        try container.encodeIfPresent(context, forKey: .context)
        try container.encodeIfPresent(extra, forKey: .extra)
        try container.encode(objectType, forKey: .objectType)
        try container.encodeIfPresent(objectId, forKey: .objectId)
        try container.encodeIfPresent(objectClass, forKey: .objectClass)
        try container.encode(place, forKey: .place)
        try container.encode(params, forKey: .params)
    }
}
