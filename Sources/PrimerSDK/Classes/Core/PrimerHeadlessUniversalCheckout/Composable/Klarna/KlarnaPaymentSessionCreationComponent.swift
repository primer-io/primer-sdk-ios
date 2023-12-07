//
//  KlarnaPaymentSessionCreationComponent.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 06.11.2023.
//

import Foundation

public enum KlarnaPaymentSessionCollectableData: PrimerCollectableData {
    case customerAccountInfo(accountUniqueId: String,
                             accountRegistrationDate: String,
                             accountLastModified: String)
}

public enum KlarnaPaymentSessionCreation: PrimerHeadlessStep {
    case paymentSessionCreated(clientToken: String, paymentCategories: [PrimerKlarnaPaymentCategory])
}

enum KlarnaPaymentSessionCreationComponentError {
    case missingConfiguration
    case invalidClientToken
    case createPaymentSessionFailed
}

public class KlarnaPaymentSessionCreationComponent: PrimerHeadlessCollectDataComponent, PrimerHeadlessAnalyticsRecordable {
    // MARK: - ViewModel
    private var tokenizationViewModel: KlarnaHeadlessTokenizationViewModel?
    
    // MARK: - Settings
    private(set) var settings: PrimerSettingsProtocol?
    
    // MARK: - Properties
    private(set) var sessionType: KlarnaSessionType?
    private(set) var customerAccountInfo: PrimerKlarnaCustomerAccountInfo?
    
    // MARK: - Delegates
    public weak var errorDelegate: PrimerHeadlessErrorableDelegate?
    public weak var stepDelegate: PrimerHeadlessSteppableDelegate?
    public weak var validationDelegate: PrimerHeadlessValidatableDelegate?
    
    // MARK: - CollectableData
    public typealias T = KlarnaPaymentSessionCollectableData
    
    // MARK: - Init
    init() {
        self.tokenizationViewModel = self.getTokenizationViewModel(
            paymentType: .klarna,
            viewModelType: KlarnaHeadlessTokenizationViewModel.self
        )
    }
}

// MARK: - Start
public extension KlarnaPaymentSessionCreationComponent {
    func start() {
        self.recordEvent(
            type: .sdkEvent,
            name: KlarnaAnalyticsEvents.CREATE_SESSION_START_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE,
            ]
        )
        
        guard
            let paymentMethod = PrimerAPIConfiguration.current?.paymentMethods?.first(where: {
                $0.name == "Klarna"
            })
        else {
            self.handleError(error: .missingConfiguration)
            return
        }
        
        tokenizationViewModel?.klarnaPaymentSessionCreated = { [weak self] (session) in
            if let session = session {
                self?.handleSuccess(success: session)
            } else {
                self?.handleError(error: .createPaymentSessionFailed)
            }
        }
        
        if let customerAccountInfo = customerAccountInfo {
            tokenizationViewModel?.setAttachment(attachment: .init(body: .init(customerAccountInfo: [
                .init(
                    uniqueAccountIdenitfier: customerAccountInfo.accountUniqueId,
                    acountRegistrationDate: customerAccountInfo.accountRegistrationDate.toString(),
                    accountLastModified: customerAccountInfo.accountLastModified.toString(),
                    appId: (paymentMethod.options as? MerchantOptions)?.appId
                )
            ])))
        }
       
        tokenizationViewModel?.start()
    }
}

// MARK: - Update
public extension KlarnaPaymentSessionCreationComponent {
    func updateCollectedData(collectableData: KlarnaPaymentSessionCollectableData) {
        recordEvent(
            type: .sdkEvent, 
            name: KlarnaAnalyticsEvents.CREATE_SESSION_UPDATE_COLLECTED_DATA_METHOD,
            params: [
                KlarnaAnalyticsEvents.CATEGORY_KEY: KlarnaAnalyticsEvents.CATEGORY_VALUE
            ]
        )
        
        switch collectableData {
        case .customerAccountInfo(let accountUniqueId, let accountRegistrationDate, let accountLastModified):
            self.customerAccountInfo = .init(
                accountUniqueId: accountUniqueId, 
                accountRegistrationDate: accountRegistrationDate.toDate(),
                accountLastModified: accountLastModified.toDate()
            )
        }
        
        self.handleDataUpdates(data: collectableData)
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
            
        case .createPaymentSessionFailed:
            primerError = PrimerError.failedToCreateSession(
                error: nil,
                userInfo: userInfo,
                diagnosticsId: UUID().uuidString
            )
        }
        
        self.errorDelegate?.didReceiveError(error: primerError)
    }
    
    func handleDataUpdates(data: KlarnaPaymentSessionCollectableData) {
        self.validationDelegate?.didUpdate(validationStatus: .validating, for: data)
        
        var errors: [PrimerValidationError] = []
        
        switch data {
        case .customerAccountInfo(let accountUniqueId, let accountRegistrationDateString, let accountLastModifiedString):
            let trimmedAccountUniqueId = accountUniqueId.trimmingCharacters(in: .whitespacesAndNewlines)
            if accountUniqueId.count == 0 || accountUniqueId.count > 24 || trimmedAccountUniqueId.count == 0 {
                errors.append(.invalidAccountUniqueId(
                    message: "Invalid customer account unique id",
                    userInfo: self.getValidationErrorUserInfo(line: "\(#line)"),
                    diagnosticsId: UUID().uuidString)
                )
            }
            
            if let accountRegistrationDate = accountRegistrationDateString.toDate() {
                if accountRegistrationDate > Date() {
                    errors.append(.invalidAccountRegistrationDate(
                        message: "Invalid customer account registration date",
                        userInfo: self.getValidationErrorUserInfo(line: "\(#line)"),
                        diagnosticsId: UUID().uuidString)
                    )
                    
                    break
                }
                
                if let accountLastModified = accountLastModifiedString.toDate() {
                    if accountLastModified > Date() || accountLastModified < accountRegistrationDate {
                        errors.append(.invalidAccountLastModified(
                            message: "Invalid customer account last modified date",
                            userInfo: self.getValidationErrorUserInfo(line: "\(#line)"),
                            diagnosticsId: UUID().uuidString)
                        )
                    }
                } else {
                    errors.append(.invalidAccountLastModified(
                        message: "Customer account last modified date not available",
                        userInfo: self.getValidationErrorUserInfo(line: "\(#line)"),
                        diagnosticsId: UUID().uuidString)
                    )
                }
            } else {
                errors.append(.invalidAccountRegistrationDate(
                    message: "Customer account registration date is not available",
                    userInfo: self.getValidationErrorUserInfo(line: "\(#line)"),
                    diagnosticsId: UUID().uuidString)
                )
            }
        }
        
        if errors.count > 0 {
            self.validationDelegate?.didUpdate(validationStatus: .invalid(errors: errors), for: data)
        } else {
            self.validationDelegate?.didUpdate(validationStatus: .valid, for: data)
        }
    }
}

// MARK: - Helpers
private extension KlarnaPaymentSessionCreationComponent {
    func getValidationErrorUserInfo(line: String) -> [String: String] {
        return [
            "file": #file,
            "class": "\(Self.self)",
            "function": #function,
            "line": line
        ]
    }
}
