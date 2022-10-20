//
//  ListItem.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 18/10/22.
//

#if canImport(UIKit)

import Foundation

@objc public class RetailOutletsRetail: NSObject, Codable {
    
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
}

#endif
