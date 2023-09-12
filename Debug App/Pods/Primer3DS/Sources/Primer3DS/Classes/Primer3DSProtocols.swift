
#if canImport(UIKit)

import Foundation
import UIKit

@objc public protocol Primer3DSProtocol {
    @objc func initializeSDK(licenseKey: String, certificates: [Primer3DSCertificate]?, enableWeakValidation: Bool) throws
    @objc func createTransaction(directoryServerId: String, supportedThreeDsProtocolVersions: [String]) throws -> SDKAuthResult
    @objc func performChallenge(threeDSAuthData: Primer3DSServerAuthData,
                                threeDsAppRequestorUrl: URL?,
                                presentOn viewController: UIViewController,
                                completion: @escaping (Primer3DSCompletion?, Error?) -> Void)
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
