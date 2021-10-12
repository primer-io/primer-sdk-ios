//
//  KlarnaServiceTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 22/02/2021.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class KlarnaServiceTests: XCTestCase {
    
    let endpoint = "https://us-central1-primerdemo-8741b.cloudfunctions.net"

    override func setUp() {
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
    }

    // MARK: createPaymentSession - Failure due to incomplete Primer initialization
    
    func test_create_klarna_payment_session_without_session_type() throws {
        let expectation = XCTestExpectation(description: "Create Klarna payment session | Failure: no country code")
        
        let settings = PrimerSettings(
            currency: .SEK,
            countryCode: .se
        )
        
        MockLocator.registerDependencies()
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let service = KlarnaService()
        service.createPaymentSession { (result) in
            switch result {
            case .failure(let err):
                if let klarnaErr = err as? KlarnaException, case KlarnaException.undefinedSessionType = klarnaErr {
                    XCTAssert(true)
                } else {
                    XCTAssert(false, "Test should have failed with error 'undefinedSessionType' but failed with: \(err)")
                }
                
            case .success(let urlString):
                XCTAssert(false, "Test should have failed with error 'undefinedSessionType' but succeeded with url: \(urlString)")

            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    func test_create_klarna_payment_session_without_config_fetched() throws {
        let expectation = XCTestExpectation(description: "Create Klarna payment session | Failure: no config id")
        
        MockLocator.registerDependencies()
        let state: AppStateProtocol = DependencyContainer.resolve()
        state.paymentMethodConfig = nil

        let service = KlarnaService()
        service.createPaymentSession { (result) in
            switch result {
            case .failure(let err):
                if let klarnaErr = err as? KlarnaException, case KlarnaException.noPaymentMethodConfigId = klarnaErr {
                    XCTAssert(true)
                } else {
                    XCTAssert(false, "Test should have failed with error 'noPaymentMethodConfigId' but failed with: \(err)")
                }
                
            case .success(let urlString):
                XCTAssert(false, "Test should have failed with error 'noPaymentMethodConfigId' but succeeded with url: \(urlString)")

            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }

    func test_create_klarna_payment_session_fail_no_client_token() throws {
        let expectation = XCTestExpectation(description: "Create Klarna payment session | Failure: No token")

        let state = MockAppState(decodedClientToken: nil)
        DependencyContainer.register(state as AppStateProtocol)

        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)

        let service = KlarnaService()

        service.createPaymentSession({ result in
            switch result {
            case .failure(let err):
                if let klarnaErr = err as? KlarnaException, case KlarnaException.noToken = klarnaErr {
                    XCTAssert(true)
                } else {
                    XCTAssert(false, "Test should have failed with error 'noToken' but failed with: \(err)")
                }
                
            case .success(let urlString):
                XCTAssert(false, "Test should have failed with error 'noToken' but succeeded with url: \(urlString)")

            }
            
            expectation.fulfill()
        })

        // Since no token is found, API call shouldn't be performed.
        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }
    
    func test_create_client_token_success() throws {
        let expectation = XCTestExpectation(description: "Create Klarna client token | Success")

        let sessionData = KlarnaSessionData(recurringDescription: "subscription", purchaseCountry: "SE", purchaseCurrency: "SEK", locale: "en-SE", orderAmount: 2000, orderLines: [], billingAddress: nil, tokenDetails: nil)
        let response = KlarnaCustomerTokenAPIResponse(customerTokenId: "token", sessionData: sessionData)
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)

        DependencyContainer.register(api as PrimerAPIClientProtocol)

        let service = KlarnaService()

        service.createKlarnaCustomerToken({ result in
            switch result {
            case .failure:
                XCTAssert(false, "Test should not get into the failure case.")
            case .success(let response):
                XCTAssertEqual(response.customerTokenId, response.customerTokenId)
            }

            expectation.fulfill()
        })

        XCTAssertEqual(api.isCalled, true)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_create_client_token_fail_invalid_response() throws {
        let expectation = XCTestExpectation(description: "Create Klarna client token | Failure: API call failed")

        let sessionData = KlarnaSessionData(recurringDescription: "subscription", purchaseCountry: "SE", purchaseCurrency: "SEK", locale: "en-SE", orderAmount: 2000, orderLines: [], billingAddress: nil, tokenDetails: nil)
        let response = KlarnaCustomerTokenAPIResponse(customerTokenId: "token", sessionData: sessionData)
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: true)

        MockLocator.registerDependencies()
        DependencyContainer.register(api as PrimerAPIClientProtocol)

        let service = KlarnaService()

        service.createKlarnaCustomerToken({ result in
            switch result {
            case .failure(let err):
                XCTAssertEqual(err as? KlarnaException, KlarnaException.failedApiCall)
            case .success:
                XCTAssert(false, "Test should get into the success case.")
            }

            expectation.fulfill()
        })

        XCTAssertEqual(api.isCalled, true)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_finalize_payment_session_success() throws {
        let expectation = XCTestExpectation(description: "Finalize Klarna payment session | Success")

        let sessionData = KlarnaSessionData(recurringDescription: "subscription", purchaseCountry: "SE", purchaseCurrency: "SEK", locale: "en-SE", orderAmount: 2000, orderLines: [], billingAddress: nil, tokenDetails: nil)
        let response = KlarnaCustomerTokenAPIResponse(customerTokenId: nil, sessionData: sessionData)
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)

        DependencyContainer.register(api as PrimerAPIClientProtocol)

        let service = KlarnaService()

        service.finalizePaymentSession({ result in
            switch result {
            case .failure:
                XCTAssert(false, "Test should not get into the failure case.")
            case .success(let res):
                XCTAssertEqual(res.sessionData.purchaseCountry, response.sessionData.purchaseCountry)
            }

            expectation.fulfill()
        })

        XCTAssertEqual(api.isCalled, true)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_finalize_payment_session_fail_invalid_response() throws {
        let expectation = XCTestExpectation(description: "Finalize Klarna payment session | Failure: API call failed")

        let sessionData = KlarnaSessionData(recurringDescription: "subscription", purchaseCountry: "SE", purchaseCurrency: "SEK", locale: "en-SE", orderAmount: 2000, orderLines: [], billingAddress: nil, tokenDetails: nil)
        let response = KlarnaCustomerTokenAPIResponse(customerTokenId: nil, sessionData: sessionData)
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: true)

        DependencyContainer.register(api as PrimerAPIClientProtocol)

        let service = KlarnaService()

        service.finalizePaymentSession({ result in
            switch result {
            case .failure(let err):
                XCTAssertEqual(err as? KlarnaException, KlarnaException.failedApiCall)
            case .success:
                XCTAssert(false, "Test should get into the success case.")
            }

            expectation.fulfill()
        })

        XCTAssertEqual(api.isCalled, true)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_finalize_payment_session_fail_no_client_token() throws {
        let expectation = XCTestExpectation(description: "Finalize Klarna payment session | Failure: No token")

        let state = MockAppState(decodedClientToken: nil)
        DependencyContainer.register(state as AppStateProtocol)

        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)

        let service = KlarnaService()

        service.finalizePaymentSession({ result in
            switch result {
            case .failure(let err):
                XCTAssertEqual(err as? KlarnaException, KlarnaException.noToken)
            case .success:
                XCTAssert(false, "Test should get into the failure case.")
            }
            expectation.fulfill()
        })

        // Since no token is found, API call shouldn't be performed.
        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }
}

extension KlarnaServiceTests: PrimerDelegate {
    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: "\(endpoint)/clientToken") else {
            return completion(nil, NetworkError.missingParams)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = CreateClientTokenRequest(customerId: "customer123")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return completion(nil, NetworkError.missingParams)
        }
        
        callApi(request, completion: { result in
            switch result {
            case .success(let data):
                do {
                    let token = (try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: String])["clientToken"]!
                    completion(token, nil)
                    
                } catch {
                    completion(nil, error)
                }
            case .failure(let err):
                completion(nil, err)
            }
        })
    }
    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
        
    }
    
    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        
    }
    
    func onCheckoutDismissed() {
        
    }
    
    func checkoutFailed(with error: Error) {
        
    }
    
    func callApi(_ req: URLRequest, completion: @escaping (_ result: Result<Data, Error>) -> Void) {
        URLSession.shared.dataTask(with: req, completionHandler: { (data, response, err) in

            if err != nil {
                completion(.failure(NetworkError.serverError))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            if (httpResponse.statusCode < 200 || httpResponse.statusCode > 399) {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            completion(.success(data))

        }).resume()
    }
    
    enum NetworkError: Error {
        case missingParams
        case unauthorised
        case timeout
        case serverError
        case invalidResponse
        case serializationError
    }
    
    struct CreateClientTokenRequest: Codable {
        let customerId: String
    }
    
}

#endif
