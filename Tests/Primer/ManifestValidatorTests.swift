//
//  ManifestValidatorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerBDCCore
@testable import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class ManifestValidatorTests: XCTestCase {
    
    private let legitimateKey = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEmarsunMditLOwMr3NugAaf6xaNSgtBPoZf1R1Bjq6EthaRX/kzarOuf/tcbJfbyh878s7m60T2WH2QrngtCY4w=="
    private let illegitimateKey = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE0LeXXUd9fxKXoF78HkUjvHZwuO0d1UmVdUUZ+7MmrzmdlnuXojsZjALZVg23I2j+uz0rbzskaM9hhjAcfnK9Rw=="
    private let signature = "MEUCIEqNE3tD6tEQxNuD2fqmBDt7z6RO2SIRqqI/GCnxxnRSAiEA5LUE2Kr1L15vae3P8Xo3FawnvlAluojXy5gXfg751MA="
    private let manifestData = Data(#"{"stateProcessor":{"umd":{"sha256":"abc","url":"https://example.com"}}}"#.utf8)

    func testValidSignatureWithCorrectKey() {
        XCTAssertTrue(
            ManifestValidator.isValid(
                makeSignedManifest(),
                publicKeyB64s: [legitimateKey]
            )
        )
    }

    func testValidSignatureWithCorrectKeyAmongMultiple() {
        XCTAssertTrue(
            ManifestValidator.isValid(
                makeSignedManifest(),
                publicKeyB64s: [illegitimateKey, legitimateKey]
            )
        )
    }

    func testValidSignatureWithWrongKey() {
        XCTAssertFalse(
            ManifestValidator.isValid(
                makeSignedManifest(),
                publicKeyB64s: [illegitimateKey]
            )
        )
    }

    func testTamperedManifestData() {
        XCTAssertFalse(
            ManifestValidator.isValid(
                SignedManifest(signature: signature, manifest: Data("tampered".utf8)),
                publicKeyB64s: [legitimateKey]
            )
        )
    }

    func testEmptyPublicKeysArray() {
        XCTAssertFalse(
            ManifestValidator.isValid(
                makeSignedManifest(),
                publicKeyB64s: []
            )
        )
    }

    func testInvalidBase64Signature() {
        XCTAssertFalse(
            ManifestValidator.isValid(
                SignedManifest(signature: "not-valid-base64", manifest: manifestData),
                publicKeyB64s: [legitimateKey]
            )
        )
    }

    func testInvalidBase64PublicKey() {
        XCTAssertFalse(
            ManifestValidator.isValid(
                makeSignedManifest(),
                publicKeyB64s: ["not-valid-base64"]
            )
        )
    }

    func testEmptySignature() {
        XCTAssertFalse(
            ManifestValidator.isValid(
                SignedManifest(signature: "", manifest: manifestData),
                publicKeyB64s: [legitimateKey]
            )
        )
    }

    func testEmptyManifestData() {
        XCTAssertFalse(
            ManifestValidator.isValid(
                SignedManifest(signature: signature, manifest: Data()),
                publicKeyB64s: [legitimateKey]
            )
        )
    }
}

private extension ManifestValidatorTests {
    func makeSignedManifest() -> SignedManifest {
        SignedManifest(
            signature: signature,
            manifest: manifestData
        )
    }
}
