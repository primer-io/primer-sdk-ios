//
//  ManifestValidator.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import Security

enum ManifestValidator {
    static func isValid(_ manifest: SignedManifest) -> Bool {
        let publicKeyB64 = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEMkeBFaS68rs8NwyCHXRNORJ70HvFw0eKm6uAdiEJaZ4M9ic9IV02lxiKbsxJ09Qjm69TJPKiQK9z8+8P499hmg=="
        let signatureB64 = manifest.signature
        
        guard
            let spkiData = Data(base64Encoded: publicKeyB64),
            let sigData = Data(base64Encoded: signatureB64) else {
            return false
        }
    
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
