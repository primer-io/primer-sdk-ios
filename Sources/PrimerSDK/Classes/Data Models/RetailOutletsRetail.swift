//
//  ListItem.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 18/10/22.
//

import Foundation

@objc public final class RetailOutletsRetail: NSObject, Codable {

    // MARK: - Public Properties

    /// The identifier of the list item
    public let id: String

    /// The name of the list item.
    /// Generally utilized at the UI level
    public let name: String

    /// The url of the image resource associated to the list item
    public let iconUrl: URL?

    /// The state of the list item.
    /// Default value: `false`.
    /// Utilized at UI level
    public let disabled: Bool

    enum CodingKeys: CodingKey {
        case id
        case name
        case iconUrl
        case disabled
    }

    public init(id: String, name: String, iconUrl: URL?, disabled: Bool) {
        self.id = id
        self.name = name
        self.iconUrl = iconUrl
        self.disabled = disabled
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        iconUrl = try container.decodeIfPresent(URL.self, forKey: .iconUrl)
        disabled = try container.decode(Bool.self, forKey: .disabled)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(iconUrl, forKey: .iconUrl)
        try container.encode(disabled, forKey: .disabled)
    }
}
