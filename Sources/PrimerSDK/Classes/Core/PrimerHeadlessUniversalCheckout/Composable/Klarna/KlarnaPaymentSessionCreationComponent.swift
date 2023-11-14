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

public class KlarnaPaymentSessionCreationComponent: PrimerHeadlessComponent, PrimerHeadlessAnalyticsRecordable {
    // MARK: - API
    private let apiClient: PrimerAPIClientProtocol
    
    // MARK: - Settings
    private var settings: PrimerSettingsProtocol?
    
    // MARK: - Delegates
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    
    // MARK: - Init
    init() {
        self.apiClient = PrimerAPIClient()
    }
    
    // MARK: - Set
    func setSettings(settings: PrimerSettingsProtocol) {
        self.settings = settings
    }
}

// MARK: - Create session
public extension KlarnaPaymentSessionCreationComponent {
    func createSession(
        sessionType: KlarnaSessionType,
        customerAccountInfo: PrimerKlarnaCustomerAccountInfo?
    ) {
        self.recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.CREATE_SESSION_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE,
                KlarnaAnalyticsEvents.CREATE_SESSION_METHOD: sessionType.rawValue
            ]
        )
        
        guard
            let settings = settings,
            let paymentMethod = PrimerAPIConfiguration.current?.paymentMethods?.first(where: {
                $0.name == "Klarna"
            }),
            let paymentMethodConfigId = paymentMethod.id
        else {
            self.handleError(error: .missingConfiguration)
            return
        }
        
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            self.handleError(error: .invalidClientToken)
            return
        }
        
        var totalAmount: Int? = nil
        if sessionType == .hostedPaymentPage {
            totalAmount = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.totalOrderAmount
        }
        
        var attachment: Request.Body.Klarna.CreatePaymentSession.Attachment?
        if let customerAccountInfo = customerAccountInfo {
            attachment = .init(body: .init(customerAccountInfo: [
                .init(
                    uniqueAccountIdenitfier: customerAccountInfo.accountUniqueId,
                    acountRegistrationDate: customerAccountInfo.accountRegistrationDate.toString(),
                    accountLastModified: customerAccountInfo.accountLastModified.toString(),
                    appId: (paymentMethod.options as? MerchantOptions)?.appId
                )
            ]))
        }
        
        let createPaymentSessionAPIRequest = Request.Body.Klarna.CreatePaymentSession(
            paymentMethodConfigId: paymentMethodConfigId,
            sessionType: sessionType,
            localeData: settings.localeData,
            description: settings.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
            redirectUrl: settings.paymentMethodOptions.urlScheme,
            totalAmount: totalAmount,
            orderItems: nil, 
            attachment: attachment
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
