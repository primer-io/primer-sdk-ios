//
//  EngineFilesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import CryptoKit
@testable import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class EngineFilesTests: XCTestCase {

    private var urlSession: URLSession!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        urlSession = URLSession(configuration: configuration)
    }

    override func tearDown() {
        StubURLProtocol.responses = [:]
        urlSession = nil
        super.tearDown()
    }

    func testDownloadsEveryFileNamedByTheManifest() async throws {
        StubURLProtocol.responses = [
            "https://cdn.test/cel.js.br": Data("cel".utf8),
            "https://cdn.test/sp.js.br": Data("processor".utf8),
            "https://cdn.test/cel.wasm.br": Data([0, 1, 2])
        ]

        let files = try await EngineFilesDownloader(urlSession: urlSession).download(manifest())

        XCTAssertEqual(files.celWrapperJS, "cel")
        XCTAssertEqual(files.stateProcessorJS, "processor")
        XCTAssertEqual(files.celWrapperWASM, Data([0, 1, 2]))
    }

    func testRejectsAFileThatDoesNotMatchItsHash() async throws {
        StubURLProtocol.responses = [
            "https://cdn.test/cel.js.br": Data("tampered".utf8),
            "https://cdn.test/sp.js.br": Data("processor".utf8),
            "https://cdn.test/cel.wasm.br": Data([0, 1, 2])
        ]
        let manifest = try manifest(celJSHash: sha256(Data("cel".utf8)))

        do {
            _ = try await EngineFilesDownloader(urlSession: urlSession).download(manifest)
            XCTFail("Expected the hash check to fail")
        } catch {
            XCTAssertEqual(error as? EngineFiles.LoadError, .sha256Mismatch)
        }
    }

    private func manifest(celJSHash: String? = nil) throws -> Manifest {
        func container(_ url: String, hash: String? = nil) -> [String: String] {
            ["br": url, "sha256": hash ?? sha256(StubURLProtocol.responses[url] ?? Data())]
        }
        let json: [String: Any] = [
            "stateProcessor": ["umd": container("https://cdn.test/sp.js.br")],
            "cel": [
                "noModules": [
                    "js": container("https://cdn.test/cel.js.br", hash: celJSHash),
                    "wasm": container("https://cdn.test/cel.wasm.br")
                ]
            ]
        ]
        return try JSONDecoder().decode(Manifest.self, from: JSONSerialization.data(withJSONObject: json))
    }

    private func sha256(_ data: Data) -> String {
        Data(SHA256.hash(data: data)).base64EncodedString()
    }
}

private final class StubURLProtocol: URLProtocol {
    static var responses: [String: Data] = [:]

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let data = Self.responses[url.absoluteString] else {
            client?.urlProtocol(self, didFailWithError: URLError(.fileDoesNotExist))
            return
        }
        client?.urlProtocol(self, didReceive: URLResponse(), cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
