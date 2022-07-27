//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

import Foundation

struct Bank: Decodable {
    let id: String
    let name: String
    let iconUrlStr: String?
    lazy var iconUrl: URL? = {
        guard let iconUrlStr = iconUrlStr else { return nil }
        return URL(string: iconUrlStr)
    }()
    let disabled: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconUrlStr = "iconUrl"
        case disabled
    }
}
