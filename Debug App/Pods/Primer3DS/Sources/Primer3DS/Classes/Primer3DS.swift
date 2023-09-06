#if canImport(UIKit)
#if canImport(ThreeDS_SDK)

import Foundation
import ThreeDS_SDK
import UIKit

public class Primer3DS: NSObject, Primer3DSProtocol {

    public static let version: String? = Bundle(identifier: "org.cocoapods.Primer3DS")?.infoDictionary?["CFBundleShortVersionString"] as? String
    public static let hardcodedVersion: String = "1.2.1"
    public static let threeDsSdkProvider: String = "NETCETERA"
    public static var threeDsSdkVersion: String? = Bundle(identifier: "com.netcetera.ThreeDS-SDK")?.infoDictionary?["CFBundleShortVersionString"] as? String
    
    public private(set) var environment: Environment
    public var is3DSSanityCheckEnabled: Bool = true
    public private(set) var isWeakValidationEnabled: Bool = true
    private var sdkCompletion: ((_ netceteraThreeDSCompletion: Primer3DSCompletion?, _ err: Primer3DSError?) -> Void)?
    private var transaction: Transaction?
    
    public static func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return ThreeDSSDKAppDelegate.shared.appOpened(url: url)
    }
    
    public static func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        return ThreeDSSDKAppDelegate.shared.appOpened(userActivity: userActivity)
    }
    
    public init(environment: Environment) {
        self.environment = environment
    }
    
    public func initializeSDK(licenseKey: String, certificates: [Primer3DSCertificate]? = nil, enableWeakValidation: Bool = true) throws {
        do {
            let configBuilder = ThreeDS_SDK.ConfigurationBuilder()
            try configBuilder.license(key: licenseKey)
            
            if enableWeakValidation {
                try configBuilder.weakValidationEnabled(true)
                self.isWeakValidationEnabled = true
            }
            
            if environment != .production {
                try configBuilder.log(to: .debug)
                
                let supportedSchemeIds: [String] = ["A999999999"]
                
                for certificate in certificates ?? [] {
                    let scheme = Scheme(name: certificate.cardScheme)
                    scheme.ids = supportedSchemeIds
                    scheme.encryptionKeyValue = certificate.encryptionKey
                    scheme.rootCertificateValue = certificate.rootCertificate
                    scheme.logoImageName = "visa"
                    try configBuilder.add(scheme)
                }
            }
            
            let configParameters = configBuilder.configParameters()
            try Primer3DSSDKProvider.shared.sdk.initialize(configParameters,
                                                           locale: nil,
                                                           uiCustomization: nil)
            
        } catch {
            let nsErr = error as NSError
            if nsErr.domain == "com.netcetera.ThreeDS-SDK" && nsErr.code == 1001 {
                // Continue
            } else {
                let err = Primer3DSError.initializationError(error: error, warnings: nil)
                throw err
            }
        }
        
        try self.verifyWarnings()
    }
    
    private func verifyWarnings() throws {
        if !is3DSSanityCheckEnabled { return }
        
        var sdkWarnings: [Warning] = []
        do {
            sdkWarnings = try Primer3DSSDKProvider.shared.sdk.getWarnings()
            
        } catch {
            let err = Primer3DSError.initializationError(error: error, warnings: nil)
            throw err
        }

        let sdkWarningMessages = sdkWarnings.compactMap({ $0.getMessage() })
        
        if !sdkWarningMessages.isEmpty {
            let message = "[\(sdkWarningMessages.joined(separator: " | "))]"
            let err = Primer3DSError.initializationError(error: nil, warnings: message)
            throw err
        }
    }
    
    public func createTransaction(directoryServerId: String, supportedThreeDsProtocolVersions: [String]) throws -> SDKAuthResult {
        guard let maxSupportedThreeDsProtocolVersion = getMaxValidSupportedThreeDSVersion(supportedThreeDsProtocolVersions) else {
            let err = Primer3DSError.unsupportedProtocolVersion(supportedProtocols: supportedThreeDsProtocolVersions)
            throw err
        }
        
        do {
            transaction = try Primer3DSSDKProvider.shared.sdk.createTransaction(
                directoryServerId: directoryServerId,
                messageVersion: maxSupportedThreeDsProtocolVersion)
            let authData = try transaction!.buildThreeDSecureAuthData()
            return SDKAuthResult(authData: authData, maxSupportedThreeDsProtocolVersion: maxSupportedThreeDsProtocolVersion)
            
        } catch {
            let err = Primer3DSError.failedToCreateTransaction(error: error)
            throw err
        }
    }
    
    public func performChallenge(
        threeDSAuthData: Primer3DSServerAuthData,
        threeDsAppRequestorUrl: URL?,
        presentOn viewController: UIViewController,
        completion: @escaping (Primer3DSCompletion?, Error?) -> Void
    ) {
        guard let transaction = transaction else {
            let err = Primer3DSError.unknown(description: "Failed to find transaction")
            completion(nil, err)
            return
        }
        
        let challengeParameters = ChallengeParameters(
            threeDSServerTransactionID: threeDSAuthData.transactionId,
            acsTransactionID: threeDSAuthData.acsTransactionId,
            acsRefNumber: threeDSAuthData.acsReferenceNumber,
            acsSignedContent: threeDSAuthData.acsSignedContent)
        
        if let threeDsAppRequestorUrl = threeDsAppRequestorUrl, let transactionId = threeDSAuthData.transactionId, !transactionId.isEmpty {
            let queryItems = [URLQueryItem(name: "transID", value: transactionId)]
            if var urlComps = URLComponents(url: threeDsAppRequestorUrl, resolvingAgainstBaseURL: false) {
                urlComps.queryItems = queryItems
                if let url = urlComps.url {
                    challengeParameters.setThreeDSRequestorAppURL(threeDSRequestorAppURL: url.absoluteString)
                }
            }
        }
                
        sdkCompletion = { [weak self] (netceteraThreeDSCompletion, err) in
            if let err = err {
                completion(nil, err)
            } else if let netceteraThreeDSCompletion = netceteraThreeDSCompletion {
                completion(netceteraThreeDSCompletion, nil)
            } else {
                precondition(false, "Should always receive a completion or an error")
            }
            
            self?.sdkCompletion = nil
        }
        
        do {
            try transaction.doChallenge(challengeParameters: challengeParameters,
                                        challengeStatusReceiver: self,
                                        timeOut: 60,
                                        inViewController: viewController)
            
        } catch {
            if let transaction = self.transaction {
                try? transaction.close()
            }
            
            let err = Primer3DSError.challengeFailed(error: error)
            completion(nil, err)
            sdkCompletion = nil
            self.cleanup()
        }
    }
        
    internal func getMaxValidSupportedThreeDSVersion(_ supportedThreeDsVersions: [String]) -> String? {
        let uniqueSupportedThreeDsVersions = supportedThreeDsVersions.unique
        let sdkSupportedProtocolVersions = uniqueSupportedThreeDsVersions.filter({ $0.compareWithVersion("2.3") == .orderedAscending && ($0.compareWithVersion("2.1") == .orderedDescending || $0.compareWithVersion("2.1") == .orderedSame) })
        let orderedSdkSupportedProtocolVersions = sdkSupportedProtocolVersions.sorted(by: { $0.compare($1, options: .numeric) == .orderedDescending })
        return orderedSdkSupportedProtocolVersions.first
    }
    
    public func cleanup() {
        try? Primer3DSSDKProvider.shared.sdk.cleanup()
    }
}

extension Primer3DS: ChallengeStatusReceiver {
    
    public func completed(completionEvent: CompletionEvent) {
        let sdkTransactionId = completionEvent.getSDKTransactionID()
        let authenticationStatus = AuthenticationStatus(rawValue: completionEvent.getTransactionStatus())
        
        if authenticationStatus == .y {
            let netceteraThreeDSCompletion = AuthCompletion(sdkTransactionId: sdkTransactionId, transactionStatus: authenticationStatus.rawValue)
            sdkCompletion?(netceteraThreeDSCompletion, nil)
        } else {
            let err = Primer3DSError.invalidChallengeStatus(status: authenticationStatus.rawValue, sdkTransactionId: sdkTransactionId)
            sdkCompletion?(nil, err)
        }
        
        self.cleanup()
    }
    
    public func protocolError(protocolErrorEvent: ProtocolErrorEvent) {
        let errorMessage = protocolErrorEvent.getErrorMessage()
        
        let err = Primer3DSError.protocolError(
            description: errorMessage.getErrorDescription(),
            code: errorMessage.getErrorCode(),
            type: errorMessage.getErrorMessageType(),
            component: errorMessage.getErrorComponent(),
            transactionId: errorMessage.getTransactionID(),
            protocolVersion: errorMessage.getMessageVersionNumber(),
            details: errorMessage.getErrorDetail())
        sdkCompletion?(nil, err)
        self.cleanup()
    }
    
    public func runtimeError(runtimeErrorEvent: RuntimeErrorEvent) {
        let err = Primer3DSError.runtimeError(
            description: runtimeErrorEvent.getErrorMessage(),
            code: runtimeErrorEvent.getErrorCode())
        sdkCompletion?(nil, err)
        self.cleanup()
    }
    
    public func timedout() {
        let err = Primer3DSError.timeOut
        sdkCompletion?(nil, err)
        self.cleanup()
    }
    
    public func cancelled() {
        let err = Primer3DSError.cancelled
        sdkCompletion?(nil, err)
        self.cleanup()
    }
}

#endif
#endif
