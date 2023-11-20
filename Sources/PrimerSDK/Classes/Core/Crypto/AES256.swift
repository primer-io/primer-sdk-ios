//
//  AES256.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

import CommonCrypto
import Foundation

internal struct AES256 {

    private static var reportingService: String = {
        return "primer.reporting"
    }()
    private static var keyAccount: String = {
        return "aes256.key"
    }()
    private static var ivAccount: String = {
        return "aes256.iv"
    }()

    private var key: Data
    private var iv: Data

    init(key: Data, iv: Data) throws {
        guard key.count == kCCKeySizeAES256 else {
            throw Error.badKeyLength
        }
        guard iv.count == kCCBlockSizeAES128 else {
            throw Error.badInputVectorLength
        }

        try! Keychain.save(password: key, service: AES256.reportingService, account: AES256.keyAccount)
        try! Keychain.save(password: iv, service: AES256.reportingService, account: AES256.ivAccount)

        self.key = key
        self.iv = iv
    }

    init() {
        if UserDefaults.primerFramework.string(forKey: "launched") == nil {
            try? Keychain.deletePassword(service: AES256.reportingService, account: AES256.keyAccount)
        }

        UserDefaults.primerFramework.set("true", forKey: "launched")
        UserDefaults.primerFramework.synchronize()

        var aesKey = try? Keychain.readPassword(service: AES256.reportingService, account: AES256.keyAccount)
        if aesKey == nil {
            let password = String.randomString(length: 32)
            let salt = String.randomString(length: 16)
            aesKey = try? AES256.createKey(password: password.data(using: .utf8)!, salt: salt.data(using: .utf8)!)
            try! Keychain.save(password: aesKey!, service: AES256.reportingService, account: AES256.keyAccount)
        }

        var aesIv = try? Keychain.readPassword(service: AES256.reportingService, account: AES256.ivAccount)
        if aesIv == nil {
            aesIv = AES256.randomIv()
            try! Keychain.save(password: aesIv!, service: AES256.reportingService, account: AES256.ivAccount)
        }

        self.iv = aesIv!
        self.key = aesKey!
    }

    enum Error: Swift.Error {
        case keyGeneration(status: Int)
        case cryptoFailed(status: CCCryptorStatus)
        case badKeyLength
        case badInputVectorLength
    }

    func encrypt(_ digest: Data) throws -> Data {
        return try crypt(input: digest, operation: CCOperation(kCCEncrypt))
    }

    func decrypt(_ encrypted: Data) throws -> Data {
        return try crypt(input: encrypted, operation: CCOperation(kCCDecrypt))
    }

    private func crypt(input: Data, operation: CCOperation) throws -> Data {
        var outLength = Int(0)
        var outBytes = [UInt8](repeating: 0, count: input.count + kCCBlockSizeAES128)
        var status: CCCryptorStatus = CCCryptorStatus(kCCSuccess)

        input.withUnsafeBytes { rawBufferPointer in
            let encryptedBytes = rawBufferPointer.baseAddress!

            iv.withUnsafeBytes { rawBufferPointer in
                let ivBytes = rawBufferPointer.baseAddress!

                key.withUnsafeBytes { rawBufferPointer in
                    let keyBytes = rawBufferPointer.baseAddress!

                    status = CCCrypt(operation,
                                     CCAlgorithm(kCCAlgorithmAES128),            // algorithm
                                     CCOptions(kCCOptionPKCS7Padding),           // options
                                     keyBytes,                                   // key
                                     key.count,                                  // keylength
                                     ivBytes,                                    // iv
                                     encryptedBytes,                             // dataIn
                                     input.count,                                // dataInLength
                                     &outBytes,                                  // dataOut
                                     outBytes.count,                             // dataOutAvailable
                                     &outLength)                                 // dataOutMoved
                }
            }
        }

        guard status == kCCSuccess else {
            throw Error.cryptoFailed(status: status)
        }

        return Data(bytes: &outBytes, count: outLength)
    }

    static func createKey(password: Data, salt: Data) throws -> Data {
        let length = kCCKeySizeAES256
        var status = Int32(0)
        var derivedBytes = [UInt8](repeating: 0, count: length)

        password.withUnsafeBytes { rawBufferPointer in
            let passwordRawBytes = rawBufferPointer.baseAddress!
            let passwordBytes = passwordRawBytes.assumingMemoryBound(to: Int8.self)

            salt.withUnsafeBytes { rawBufferPointer in
                let saltRawBytes = rawBufferPointer.baseAddress!
                let saltBytes = saltRawBytes.assumingMemoryBound(to: UInt8.self)

                status = CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),                  // algorithm
                                              passwordBytes,                                // password
                                              password.count,                               // passwordLen
                                              saltBytes,                                    // salt
                                              salt.count,                                   // saltLen
                                              CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),   // prf
                                              10000,                                        // rounds
                                              &derivedBytes,                                // derivedKey
                                              length)                                       // derivedKeyLen
            }
        }

        guard status == 0 else {
            throw Error.keyGeneration(status: Int(status))
        }
        return Data(bytes: &derivedBytes, count: length)
    }

    static func randomIv() -> Data {
        return randomData(length: kCCBlockSizeAES128)
    }

    static func randomSalt() -> Data {
        return randomData(length: 8)
    }

    static func randomData(length: Int) -> Data {
        var data = Data(count: length)
        let status = data.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes)
        }
        assert(status == Int32(0))
        return data
    }
}
