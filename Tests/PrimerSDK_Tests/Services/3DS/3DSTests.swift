//
//  ThreeDSTests.swift
//  PrimerSDK_Tests
//
//  Created by Evangelos Pittas on 17/6/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
import ThreeDS_SDK
@testable import PrimerSDK

class ThreeDSTests: XCTestCase {
    
    var sut: Primer = Primer.shared
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func initializeThreeDSSDK(_ sdk: ThreeDSSDKProtocol, completion: @escaping (Error?) -> Void) {
        let threeDSService: ThreeDSServiceProtocol = ThreeDSService()
        threeDSService.initializeSDK(sdk) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let err):
                completion(err)
                let nsErr = err as NSError
                XCTAssert(false, "3DS SDK initialization failed with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
            }
        }
    }
    
    func testInitializeThreeDSSDK() throws {
        let sdk: ThreeDSSDKProtocol = NetceteraSDK()
        let expectation = XCTestExpectation(description: "3DS SDK initialized")
        
        initializeThreeDSSDK(sdk) { err in
            if let err = err {
                let nsErr = err as NSError
                XCTAssert(false, "3DS SDK initialization failed with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
            } else {
                XCTAssert(true)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testThreeDSSDKAuth() throws {
        let sdk: ThreeDSSDKProtocol = NetceteraSDK()
        let expectation = XCTestExpectation(description: "3DS SDK initial auth completed")
        
        initializeThreeDSSDK(sdk) { err in
            if let err = err {
                let nsErr = err as NSError
                XCTAssert(false, "3DS SDK initialization failed with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
            } else {
                let threeDSService: ThreeDSServiceProtocol = ThreeDSService()
                threeDSService.authenticateSdk(sdk: sdk, cardNetwork: .unknown, protocolVersion: .v1) { result in
                    switch result {
                    case .success(let transaction):
                        do {
                            let sdkAuthData = try transaction.buildThreeDSecureAuthData()
                            XCTAssert(!sdkAuthData.sdkAppId.isEmpty, "SDK App ID cannot be empty")
                            XCTAssert(!sdkAuthData.sdkEncData.isEmpty, "SDK encrypted data cannot be empty")
                            XCTAssert(!sdkAuthData.sdkEphemPubKey.isEmpty, "SDK ephemeral key cannot be empty")
                            
                            if let _ = sdk as? NetceteraSDK {
                                XCTAssert(sdkAuthData.sdkReferenceNumber == ThreeDSConstants.netceteraSDKRef, "SDK Reference number is wrong \(sdkAuthData.sdkReferenceNumber)")
                            }
                            expectation.fulfill()
                        } catch {
                            let nsErr = error as NSError
                            XCTAssert(false, "3DS SDK initial auth failed with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
                        }
                        
                    case .failure(let err):
                        let nsErr = err as NSError
                        XCTAssert(false, "3DS SDK initial auth failed with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testThreeDSBeginRemoteAuth() throws {
        let expectation = XCTestExpectation(description: "3DS SDK Request Begin Auth")
        
        guard let paymentMethodData = ThreeDSConstants.paymentMethodJSON.data(using: .utf8) else {
            XCTAssert(false, "Failed to get data from JSON string")
            return
        }
        
        var paymentMethod: PaymentMethodToken!
        do {
            paymentMethod = try JSONParser().parse(PaymentMethodToken.self, from: paymentMethodData)
        } catch {
            let nsErr = error as NSError
            XCTAssert(false, "Failed to parse payment method with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
        }
        
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        
        var req = ThreeDS.BeginAuthRequest.demoAuthRequest
        req.amount = 0
        
        do {
            req.device = try JSONParser().parse(ThreeDS.SDKAuthData.self, from: ThreeDSConstants.sdkAuthResponseStr.data(using: .utf8)!)
        } catch {
            let nsErr = error as NSError
            XCTAssert(false, "Failed to parse payment method with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
        }
        
        let threeDSService = MockThreeDSService()
        threeDSService.response = ThreeDSConstants.beginAuthResponseStr.data(using: .utf8)!
        DependencyContainer.register(threeDSService as ThreeDSServiceProtocol)
        
        threeDSService.beginRemoteAuth(paymentMethodToken: paymentMethod, threeDSecureBeginAuthRequest: req) { result in
            switch result {
            case .success(let response):
                XCTAssert(response.token.paymentInstrumentData?.last4Digits == "0008", "last4Digits wasn't parsed correctly")
                XCTAssert(response.token.paymentInstrumentData?.expirationMonth == "02", "expirationMonth wasn't parsed correctly")
                XCTAssert(response.token.paymentInstrumentData?.expirationYear == "2022", "expirationYear wasn't parsed correctly")
                XCTAssert(response.token.paymentInstrumentData?.cardholderName == "John Snow", "cardholderName wasn't parsed correctly")
                
                XCTAssert(response.authentication.acsSignedContent?.isEmpty == false, "acsSignedContent wasn't parsed correctly")
                XCTAssert(response.authentication.acsReferenceNumber == "3ds_acs_provider", "acsReferenceNumber wasn't parsed correctly")
                XCTAssert(response.authentication.acsTransactionId == "acs_transaction_id", "acsTransactionId wasn't parsed correctly")
                XCTAssert(response.authentication.responseCode == .challenge, "acsTransactionId wasn't parsed correctly")
                
                expectation.fulfill()
            case .failure(let err):
                let nsErr = err as NSError
                XCTAssert(false, "Failed to parse payment method with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testThreeDSChallenge() throws {
        let expectation = XCTestExpectation(description: "3DS SDK Request Continue Auth")
        
        let sdk = NetceteraSDK()
        let threeDSService = MockThreeDSService()
        DependencyContainer.register(threeDSService as ThreeDSServiceProtocol)
        
        initializeThreeDSSDK(sdk) { err in
            if let err = err {
                let nsErr = err as NSError
                XCTAssert(false, "3DS SDK initialization failed with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
            } else {
                threeDSService.authenticateSdk(sdk: sdk, cardNetwork: .unknown, protocolVersion: .v1) { result in
                    switch result {
                    case .success(let transaction):
                        guard let paymentMethodData = ThreeDSConstants.paymentMethodJSON.data(using: .utf8) else {
                            XCTAssert(false, "Failed to get data from JSON string")
                            return
                        }
                        
                        var paymentMethod: PaymentMethodToken!
                        do {
                            paymentMethod = try JSONParser().parse(PaymentMethodToken.self, from: paymentMethodData)
                        } catch {
                            let nsErr = error as NSError
                            XCTAssert(false, "Failed to parse payment method with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
                        }
                        
                        let state = MockAppState()
                        DependencyContainer.register(state as AppStateProtocol)
                        
                        
                        var req = ThreeDS.BeginAuthRequest.demoAuthRequest
                        req.amount = 0
                        
                        do {
                            req.device = try JSONParser().parse(ThreeDS.SDKAuthData.self, from: ThreeDSConstants.sdkAuthResponseStr.data(using: .utf8)!)
                        } catch {
                            let nsErr = error as NSError
                            XCTAssert(false, "Failed to parse payment method with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
                        }
                        
                        threeDSService.response = ThreeDSConstants.beginAuthResponseStr.data(using: .utf8)!
                        threeDSService.beginRemoteAuth(paymentMethodToken: paymentMethod, threeDSecureBeginAuthRequest: req) { result in
                            switch result {
                            case .success(let response):
                                guard let authentication = response.authentication as? ThreeDS.Authentication else {
                                    let err = PrimerError.generic
                                    XCTAssert(false, "3DS Begin Remote Auth doesn't include the `auth` field.")
                                    return
                                }
                                
                                threeDSService.performChallenge(with: sdk, on: transaction, with: authentication, presentOn: UIViewController()) { result in
                                    switch result {
                                    case .success(let sdkAuthCompletion):
                                        XCTAssert(sdkAuthCompletion.sdkTransactionId == "transaction_id", "3DS SDK Challenge returned transaction id.")
                                        expectation.fulfill()
                                    case .failure(let err):
                                        let nsErr = err as NSError
                                        XCTAssert(false, "Failed to parse payment method with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
                                    }
                                }
                                
                                
                            case .failure(let err):
                                let nsErr = err as NSError
                                XCTAssert(false, "Failed to parse payment method with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
                            }
                        }
                        
                        
                    case .failure(let err):
                        let nsErr = err as NSError
                        XCTAssert(false, "Failed to parse payment method with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testThreeDSContinueRemoteAuth() throws {
        let expectation = XCTestExpectation(description: "3DS SDK Request Continue Auth")
        
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        
        let threeDSService = MockThreeDSService()
        threeDSService.response = ThreeDSConstants.continueAuthResponseStr.data(using: .utf8)!
        DependencyContainer.register(threeDSService as ThreeDSServiceProtocol)
        
        threeDSService.continueRemoteAuth(threeDSTokenId: "transaction_id") { result in
            switch result {
            case .success(let response):
                XCTAssert(response.token.paymentInstrumentData?.last4Digits == "0008", "last4Digits wasn't parsed correctly")
                XCTAssert(response.token.threeDSecureAuthentication?.responseCode == .authSuccess, "3DS wasn't successful")
                XCTAssert(response.token.threeDSecureAuthentication?.challengeIssued == true, "Challenge issued wasn't parsed correctly")
                XCTAssert(response.token.threeDSecureAuthentication?.protocolVersion == "2.1.0", "3DS protocol version wasn't parsed correctly")
                expectation.fulfill()
            case .failure(let err):
                let nsErr = err as NSError
                XCTAssert(false, "Failed to parse 3ds continue auth response with error: \(nsErr.domain):\(nsErr.code) [\(nsErr.localizedDescription)]")
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
}
