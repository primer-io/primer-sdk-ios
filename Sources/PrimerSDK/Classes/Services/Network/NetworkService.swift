//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import Foundation

typealias ResultCallback<T> = (Result<T, Error>) -> Void

internal protocol NetworkService {
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping ResultCallback<T>)
}

#endif
