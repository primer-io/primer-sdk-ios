//
//  3DSTypes.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(Primer3DS)
import Primer3DS
import PrimerNetworking

extension ThreeDS {

    public final class Cer: Primer3DSCertificate {

        public var cardScheme: String
        public var encryptionKey: String
        public var rootCertificate: String

        public init(cardScheme: String, rootCertificate: String, encryptionKey: String) {
            self.cardScheme = cardScheme
            self.rootCertificate = rootCertificate
            self.encryptionKey = encryptionKey
        }
    }

    public final class ServerAuthData: Primer3DSServerAuthData {

        public var acsReferenceNumber: String?
        public var acsSignedContent: String?
        public var acsTransactionId: String?
        public var responseCode: String
        public var transactionId: String?

        public init(
            acsReferenceNumber: String?,
            acsSignedContent: String?,
            acsTransactionId: String?,
            responseCode: String,
            transactionId: String?
        ) {
            self.acsReferenceNumber = acsReferenceNumber
            self.acsSignedContent = acsSignedContent
            self.acsTransactionId = acsTransactionId
            self.responseCode = responseCode
            self.transactionId = transactionId
        }
    }
}
#endif
