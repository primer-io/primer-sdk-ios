//
//  PMFComponentContainer.swift
//  PrimerSDK
//
//  Created by Evangelos on 3/11/22.
//

#if canImport(UIKit)

import Foundation

extension PMF.Component {
    
    class Container: Codable {
        
        var orientation: PMF.Screen.Orientation
        var components: [PMF.Component]
        
        private enum CodingKeys : String, CodingKey {
            case orientation, components
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            do {
                if let orientation = try container.decode(PMF.Screen.Orientation?.self, forKey: .orientation) {
                    self.orientation = orientation
                } else {
                    self.orientation = .vertical
                }
                
                if let components = try container.decode([PMF.Component]?.self, forKey: .components) {
                    self.components = components
                } else {
                    self.components = []
                }
            } catch {
                throw error
            }
            
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.orientation, forKey: .orientation)
            try container.encode(self.components, forKey: .components)
        }
    }
}

#endif
