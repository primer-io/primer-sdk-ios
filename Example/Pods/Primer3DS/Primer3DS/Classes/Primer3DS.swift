
import ThreeDS_SDK

@objc public protocol Primer3DSProtocol {
    @objc func initializeSDK(licenseKey: String, certificates: [Primer3DSCertificateProtocol]?) throws
    @objc func createTransaction(directoryServerId: String, protocolVersion: String) throws
    @objc func performChallenge(with threeDSecureAuthResponse: Primer3DSAuthenticationProtocol, urlScheme: String?, presentOn viewController: UIViewController, completion: @escaping (SDKAuthCompletionProtocol?, Error?) -> Void)
}

@objc public protocol Primer3DSCertificateProtocol {
    var encryptionKey: String { get }
    var rootCertificate: String { get }
}

@objc public protocol Primer3DSAuthenticationProtocol {
    var acsReferenceNumber: String? { get }
    var acsSignedContent: String? { get }
    var acsTransactionId: String? { get }
    var responseCode: ResponseCode { get }
    var transactionId: String? { get }
}

public class Primer3DS: NSObject, Primer3DSProtocol {
    
    public private(set) var environment: Environment
    private let sdk: ThreeDS2Service = ThreeDS2ServiceSDK()
    private var sdkCompletion: ((_ netceteraThreeDSCompletion: SDKAuthCompletion?, _ err: Error?) -> Void)?
    
    public init(environment: Environment = .production) {
        self.environment = environment
    }
    
    public func initializeSDK(licenseKey: String, certificates: [Primer3DSCertificateProtocol]? = nil) throws {
        do {
            let configBuilder = ThreeDS_SDK.ConfigurationBuilder()
            try configBuilder.license(key: licenseKey)
            
            if environment != .production {
                try configBuilder.log(to: .debug)
                
                let supportedSchemeIds: [String] = ["A999999999"]
                
                let scheme = Scheme(name: "test_scheme")
                scheme.ids = supportedSchemeIds
                
                for certificate in certificates ?? [] {
                    scheme.encryptionKeyValue = certificate.encryptionKey
                    scheme.rootCertificateValue = certificate.rootCertificate
                }
                
                scheme.logoImageName = "visa"
                
                try configBuilder.add(scheme)
            }

            let configParameters = configBuilder.configParameters()
            try sdk.initialize(configParameters,
                                           locale: nil,
                                           uiCustomization: nil)
            
        } catch {
            throw error
        }
    }
    
    var transaction: Transaction?
    
    public func createTransaction(directoryServerId: String, protocolVersion: String) throws {
        do {
            transaction = try sdk.createTransaction(directoryServerId: directoryServerId, messageVersion: protocolVersion)
        } catch {
            throw error
        }
    }
    
    public func performChallenge(with threeDSecureAuthResponse: Primer3DSAuthenticationProtocol, urlScheme: String?, presentOn viewController: UIViewController, completion: @escaping (SDKAuthCompletionProtocol?, Error?) -> Void) {
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
        let netceteraThreeDSCompletion = SDKAuthCompletion(sdkTransactionId: sdkTransactionId, transactionStatus: authenticationStatus.rawValue)
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
