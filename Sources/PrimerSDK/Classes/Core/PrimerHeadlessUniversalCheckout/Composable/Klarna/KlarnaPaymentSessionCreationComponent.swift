//
//  KlarnaPaymentSessionCreationComponent.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 06.11.2023.
//

import Foundation

public enum KlarnaPaymentSessionCreation: PrimerHeadlessStep {
    case paymentSessionCreated(clientToken: String, paymentCategories: [PrimerKlarnaPaymentCategory])
}

enum KlarnaPaymentSessionCreationComponentError {
    case missingConfiguration
    case invalidClientToken
    case createPaymentSessionFailed(error: Error)
}

public class KlarnaPaymentSessionCreationComponent: PrimerHeadlessComponent {
    // MARK: - API
    private let apiClient: PrimerAPIClientProtocol
    
    // MARK: - Delegates
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    
    // MARK: - Init
    init() {
        self.apiClient = PrimerAPIClient()
    }
}

// MARK: - Create session
public extension KlarnaPaymentSessionCreationComponent {
    func createSession(sessionType: KlarnaSessionType) {
        guard
            let paymentMethodConfigId = PrimerAPIConfiguration.current?.paymentMethods?.first(where: {
                $0.name == PrimerPaymentMethodType.klarna.rawValue
            })?.id
        else {
            self.handleError(error: .missingConfiguration)
            return
        }
        
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            self.handleError(error: .invalidClientToken)
            return
        }
        
        let orderItems = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.lineItems?.compactMap({
            try? $0.toOrderItem()
        })
        
        let totalAmount = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.totalOrderAmount
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        let createPaymentSessionAPIRequest = Request.Body.Klarna.CreatePaymentSession(
            paymentMethodConfigId: paymentMethodConfigId,
            sessionType: sessionType,
            localeData: settings.localeData,
            description: nil,
            redirectUrl: settings.paymentMethodOptions.urlScheme,
            totalAmount: totalAmount,
            orderItems: orderItems
        )
        
        self.apiClient.createKlarnaPaymentSession(
            clientToken: clientToken,
            klarnaCreatePaymentSessionAPIRequest: createPaymentSessionAPIRequest
        ) { [weak self] (result) in
            switch result {
            case .success(let success):
                self?.handleSuccess(success: success)
                
            case .failure(let failure):
                self?.handleError(error: .createPaymentSessionFailed(error: failure.primerError))
            }
        }
    }
}

// MARK: - Private
private extension KlarnaPaymentSessionCreationComponent {
    func handleSuccess(success: Response.Body.Klarna.CreatePaymentSession) {
        let step = KlarnaPaymentSessionCreation.paymentSessionCreated(
            clientToken: success.clientToken,
            paymentCategories: success.categories.map { PrimerKlarnaPaymentCategory(response: $0) }
        )
        self.stepDelegate?.didReceiveStep(step: step)
    }
    
    func handleError(error: KlarnaPaymentSessionCreationComponentError) {
        var primerError: PrimerError
        
        let userInfo: [String: String] = [
            "file": #file,
            "class": "\(Self.self)",
            "function": #function,
            "line": "\(#line)"
        ]
        
        switch error {
        case .missingConfiguration:
            primerError = PrimerError.missingPrimerConfiguration(
                userInfo: userInfo,
                diagnosticsId: UUID().uuidString
            )
           
        case .invalidClientToken:
            primerError = PrimerError.invalidClientToken(
                userInfo: userInfo,
                diagnosticsId: UUID().uuidString
            )
            
        case .createPaymentSessionFailed(let error):
            primerError = PrimerError.failedToCreateSession(
                error: error,
                userInfo: userInfo,
                diagnosticsId: UUID().uuidString
            )
        }
        
        self.errorDelegate?.didReceiveError(error: primerError)
    }
}
