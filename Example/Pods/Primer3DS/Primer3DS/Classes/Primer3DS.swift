
import ThreeDS_SDK

public class Primer3DS: NSObject, Primer3DSProtocol {
    
    public private(set) var environment: Environment
    private let sdk: ThreeDS2Service = ThreeDS2ServiceSDK()
    private var sdkCompletion: ((_ netceteraThreeDSCompletion: Primer3DSCompletion?, _ err: Error?) -> Void)?
    private var transaction: Transaction?
    
    public init(environment: Environment) {
        self.environment = environment
    }
    
    public func initializeSDK(licenseKey: String, certificates: [Primer3DSCertificate]? = nil) throws {
        do {
            let configBuilder = ThreeDS_SDK.ConfigurationBuilder()
            try configBuilder.license(key: licenseKey)
            
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
            try sdk.initialize(configParameters,
                                           locale: nil,
                                           uiCustomization: nil)
            
        } catch {
            throw error
        }
    }
    
    public func createTransaction(directoryServerId: String, protocolVersion: String) throws -> Primer3DSSDKGeneratedAuthData {
        do {
            transaction = try sdk.createTransaction(directoryServerId: directoryServerId, messageVersion: protocolVersion)
            let sdkAuthData = try transaction!.buildThreeDSecureAuthData()
            return sdkAuthData
        } catch {
            throw error
        }
    }
    
    public func performChallenge(with threeDSecureAuthResponse: Primer3DSServerAuthData, urlScheme: String?, presentOn viewController: UIViewController, completion: @escaping (Primer3DSCompletion?, Error?) -> Void) {
        guard let transaction = transaction else {
            completion(nil, NSError(domain: "Primer3DS", code: 100, userInfo: [NSLocalizedDescriptionKey: "Failed to find transaction"]))
            return
        }
        
        let challengeParameters = ChallengeParameters(
            threeDSServerTransactionID: threeDSecureAuthResponse.transactionId,
            acsTransactionID: threeDSecureAuthResponse.acsTransactionId,
            acsRefNumber: threeDSecureAuthResponse.acsReferenceNumber,
            acsSignedContent: threeDSecureAuthResponse.acsSignedContent)
        
        if let urlScheme = urlScheme, let transactionId = threeDSecureAuthResponse.transactionId, !transactionId.isEmpty {
            challengeParameters.setThreeDSRequestorAppURL(threeDSRequestorAppURL: "\(urlScheme)://appURL?transID=\(transactionId)")
        }
        
        sdkCompletion = { [weak self] (netceteraThreeDSCompletion, err) in
            if let err = err {
                completion(nil, err)
            } else if let netceteraThreeDSCompletion = netceteraThreeDSCompletion {
                completion(netceteraThreeDSCompletion, nil)
            } else {
                // Will never get in here! Assert an error.
            }
            
            self?.sdkCompletion = nil
        }
        
        do {
            try transaction.doChallenge(challengeParameters: challengeParameters,
                                        challengeStatusReceiver: self,
                                        timeOut: 60,
                                        inViewController: viewController)
            
        } catch {
            sdkCompletion = nil
            completion(nil, error)
        }
    }
    
}

extension Primer3DS: ChallengeStatusReceiver {
    
    public func completed(completionEvent: CompletionEvent) {
        let sdkTransactionId = completionEvent.getSDKTransactionID()
        let authenticationStatus = AuthenticationStatus(rawValue: completionEvent.getTransactionStatus())
        let netceteraThreeDSCompletion = AuthCompletion(sdkTransactionId: sdkTransactionId, transactionStatus: authenticationStatus.rawValue)
        sdkCompletion?(netceteraThreeDSCompletion, nil)
    }
    
    public func cancelled() {
        let err = NSError(domain: "Primer3DS", code: -4, userInfo: [NSLocalizedDescriptionKey: "3DS canceled"])
        sdkCompletion?(nil, err)
    }
    
    public func timedout() {
        let err = NSError(domain: "Primer3DS", code: -3, userInfo: [NSLocalizedDescriptionKey: "3DS timed out"])
        sdkCompletion?(nil, err)
    }
    
    public func protocolError(protocolErrorEvent: ProtocolErrorEvent) {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: "\(protocolErrorEvent.getErrorMessage())",
            "sdkTransactionId": "\(protocolErrorEvent.getSDKTransactionID())"
        ]
        
        let err = NSError(domain: "Primer3DS", code: -1, userInfo: userInfo)
        sdkCompletion?(nil, err)
    }
    
    public func runtimeError(runtimeErrorEvent: RuntimeErrorEvent) {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: "\(runtimeErrorEvent.getErrorMessage())"
        ]
        
        let err = NSError(domain: "Primer3DS", code: Int(runtimeErrorEvent.getErrorCode() ?? "-2") ?? -2, userInfo: userInfo)
        sdkCompletion?(nil, err)
    }
    
}

extension Transaction {
    func buildThreeDSecureAuthData() throws -> Primer3DSSDKGeneratedAuthData {
        let transactionParameters = try self.getAuthenticationRequestParameters()
        let sdkAppId = transactionParameters.getSDKAppID()
        let sdkTransactionId = transactionParameters.getSDKTransactionId()
        let sdkMaxTimeout = 10
        let sdkEncData = transactionParameters.getDeviceData()
        let sdkEphemeralKey = transactionParameters.getSDKEphemeralPublicKey()
        let sdkReferenceNumber = transactionParameters.getSDKReferenceNumber()
        
        return SDKAuthData(
            sdkAppId: sdkAppId,
            sdkTransactionId: sdkTransactionId,
            sdkTimeout: sdkMaxTimeout,
            sdkEncData: sdkEncData,
            sdkEphemPubKey: sdkEphemeralKey,
            sdkReferenceNumber: sdkReferenceNumber)
    }
}
