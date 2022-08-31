
#if canImport(UIKit)

import Foundation
import UIKit

@objc public protocol Primer3DSProtocol {
    @objc func initializeSDK(licenseKey: String, certificates: [Primer3DSCertificate]?) throws
    @objc func createTransaction(directoryServerId: String, protocolVersion: String) throws -> Primer3DSSDKGeneratedAuthData
    @objc func performChallenge(with threeDSecureAuthResponse: Primer3DSServerAuthData, urlScheme: String?, presentOn viewController: UIViewController, completion: @escaping (Primer3DSCompletion?, Error?) -> Void)
}

@objc public protocol Primer3DSCertificate {
    var cardScheme: String { get }
    var encryptionKey: String { get }
    var rootCertificate: String { get }
}

@objc public protocol Primer3DSSDKGeneratedAuthData {
    var sdkAppId: String { get }
    var sdkTransactionId: String { get }
    var sdkTimeout: Int { get }
    var sdkEncData: String { get }
    var sdkEphemPubKey: String { get }
    var sdkReferenceNumber: String { get }
}

@objc public protocol Primer3DSServerAuthData {
    var acsReferenceNumber: String? { get }
    var acsSignedContent: String? { get }
    var acsTransactionId: String? { get }
    var responseCode: String { get }
    var transactionId: String? { get }
}

@objc public protocol Primer3DSCompletion {
    var sdkTransactionId: String { get }
    var transactionStatus: String { get }
}

#endif
