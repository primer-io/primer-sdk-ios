//
//  EngineFiles.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import CryptoKit
import Foundation
@_spi(PrimerInternal) import PrimerFoundation

struct EngineFiles {
    enum LoadError: Error {
        case badUrl
        case sha256Mismatch
    }

    let celWrapperJS: String
    let stateProcessorJS: String
    let celWrapperWASM: Data
}

struct EngineFilesDownloader {
    private let urlSession: URLSession

    init(urlSession: URLSession = .engineFiles) {
        self.urlSession = urlSession
    }

    func download(_ manifest: Manifest) async throws -> EngineFiles {
        let celWrapperJS = try await urlSession.data(for: manifest.celWrapperJSURLContainer)
        let stateProcessorJS = try await urlSession.data(for: manifest.stateProcessorContainer)
        let celWrapperWASM = try await urlSession.data(for: manifest.celWrapperWASMURLContainer)
        return EngineFiles(
            celWrapperJS: String(decoding: celWrapperJS, as: UTF8.self),
            stateProcessorJS: String(decoding: stateProcessorJS, as: UTF8.self),
            celWrapperWASM: celWrapperWASM
        )
    }
}

extension URLSession {
    fileprivate static let engineFiles: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 20_000_000)
        return URLSession(configuration: configuration)
    }()

    fileprivate func data(for container: BrotliContainer) async throws -> Data {
        guard let url = URL(string: container.br) else { throw EngineFiles.LoadError.badUrl }
        let (data, _) = try await data(for: URLRequest(url: url))
        let computedSHA256 = Data(SHA256.hash(data: data)).base64EncodedString()
        guard computedSHA256 == container.sha256 else { throw EngineFiles.LoadError.sha256Mismatch }
        return data
    }
}
