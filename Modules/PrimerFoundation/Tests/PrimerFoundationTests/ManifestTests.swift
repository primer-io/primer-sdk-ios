//
//  ManifestTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class ManifestTests: XCTestCase {

    func testDecodeSignedManifest() throws {
        let innerManifestJSON = """
        {
            "stateProcessor": {
                "umd": { "sha256": "abc", "br": "https://example.com/sp.br" }
            },
            "cel": {
                "noModules": {
                    "js": { "sha256": "def", "br": "https://example.com/js.br" },
                    "wasm": { "sha256": "ghi", "br": "https://example.com/wasm" }
                }
            }
        }
        """

        let signedManifest = try makeSignedManifest(signature: "test-sig", manifestJSON: innerManifestJSON)
        XCTAssertEqual(signedManifest.signature, "test-sig")
        XCTAssertFalse(signedManifest.manifest.isEmpty)
    }

    func testDecodeManifest() throws {
        let json = """
        {
            "stateProcessor": {
                "umd": {
                    "sha256": "abc123",
                    "br": "https://example.com/state-processor.js.br"
                }
            },
            "cel": {
                "noModules": {
                    "js": {
                        "sha256": "def456",
                        "br": "https://example.com/cel.js.br"
                    },
                    "wasm": {
                        "sha256": "ghi789",
                        "br": "https://example.com/cel.wasm.br"
                    }
                }
            }
        }
        """

        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(json.utf8))

        XCTAssertEqual(manifest.stateProcessorContainer.sha256, "abc123")
        XCTAssertEqual(manifest.stateProcessorContainer.br, "https://example.com/state-processor.js.br")
        XCTAssertEqual(manifest.celWrapperJSURLContainer.sha256, "def456")
        XCTAssertEqual(manifest.celWrapperJSURLContainer.br, "https://example.com/cel.js.br")
        XCTAssertEqual(manifest.celWrapperWASMURLContainer.sha256, "ghi789")
        XCTAssertEqual(manifest.celWrapperWASMURLContainer.br, "https://example.com/cel.wasm.br")
    }

    func testDecodeManifestMissingFieldThrows() {
        let json = """
        {
            "stateProcessor": {
                "umd": { "sha256": "abc", "br": "https://example.com" }
            }
        }
        """

        XCTAssertThrowsError(try JSONDecoder().decode(Manifest.self, from: Data(json.utf8)))
    }

    private func makeSignedManifest(signature: String, manifestJSON: String) throws -> SignedManifest {
        let manifestData = Data(manifestJSON.utf8)
        let wrapper = ["signature": signature, "manifest": manifestData.base64EncodedString()]
        let data = try JSONSerialization.data(withJSONObject: wrapper)
        return try JSONDecoder().decode(SignedManifest.self, from: data)
    }
}
