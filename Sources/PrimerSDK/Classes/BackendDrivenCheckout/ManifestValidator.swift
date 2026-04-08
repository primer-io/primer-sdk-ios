//
//  ManifestValidator.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import Security

enum ManifestValidator {
    static func isValid(_ manifest: SignedManifest, publicKeyB64s: [String]) -> Bool {
        let signatureB64 = manifest.signature
        
        for keyB64 in publicKeyB64s {
            if verify(signature: signatureB64, against: keyB64, in: manifest) {
                return true
            }
        }
        return false
    }
    
    private static func verify(signature: String, against key: String, in manifest: SignedManifest) -> Bool {
        guard
            let spkiData = Data(base64Encoded: key),
            let sigData = Data(base64Encoded: signature) else {
            return false
        }
    
        // Public keys in SPKI format have a 26-byte header that describes the key type.
        // Apple's Security framework expects the raw key without this header, so we strip it.
        let rawKey = spkiData.dropFirst(26)
        let attrs: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 256
        ]
        var err: Unmanaged<CFError>?
        let key = SecKeyCreateWithData(Data(rawKey) as CFData, attrs as CFDictionary, &err)
        
        guard let key else { return false }
        
        let msgCFData = manifest.manifest as CFData
        let sigCFData = sigData as CFData
        return SecKeyVerifySignature(key, .ecdsaSignatureMessageX962SHA256, msgCFData, sigCFData, &err)
    }
}
