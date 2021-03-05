//
//  PrimerAPIClient.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 26/2/21.
//

import Foundation

class PrimerAPIClient {
    
    private let networkService: NetworkService
    
    // MARK: - Object lifecycle
    
    init(networkService: NetworkService = URLSessionStack()) {
        self.networkService = networkService
    }
    
    // MARK: - API Client logic
    
    func createAccount(createAccountRequestParams: CreateAccountRequestParams, completion: @escaping (_ result: Result<CreateAccountResponse, Error>) -> Void) {
        let endpoint = PrimerAPI.createAccount(createAccountRequestParams: createAccountRequestParams)
        networkService.request(endpoint) { (result: Result<CreateAccountResponse, NetworkServiceError>) in
            switch result {
            case .success(let createAccountResponse):
                completion(.success(createAccountResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func authorizeCheckout(completion: @escaping (_ result: Result<ClientTokenDecodable, Error>) -> Void) {
        let endpoint = PrimerAPI.authorizeCheckout
        networkService.request(endpoint) { (result: Result<ClientTokenDecodable, NetworkServiceError>) in
            switch result {
            case .success(let createAccountResponse):
                completion(.success(createAccountResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func listTransactions(completion: @escaping (_ result: Result<ClientTokenDecodable, Error>) -> Void) {
        let endpoint = PrimerAPI.listTransactions
        networkService.request(endpoint) { (result: Result<ClientTokenDecodable, NetworkServiceError>) in
            switch result {
            case .success(let createAccountResponse):
                completion(.success(createAccountResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
