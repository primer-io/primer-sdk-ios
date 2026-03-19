//
//  BackendDrivenCheckoutViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerBDCCore
import PrimerFoundation
import UIKit

@MainActor
final class BackendDrivenCheckoutViewModel: PaymentMethodTokenizationViewModel {
    
    private var orchestrator: PrimerStepOrchestrator?
    private let manifestRepository = ManifestRepository()
    
    override func start() {
        Task { @MainActor in
            do {
                PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
                let manifest = try await manifestRepository.fetchManifest()
                orchestrator = PrimerStepOrchestrator(manifest: manifest)
                let response: ClientSessionInstructionResponse = try await request(.pay(paymentMethod: config))
                try await processClientInstruction(response)
                let categories = config.paymentMethodManagerCategories ?? []
                uiManager.dismissOrShowResultScreen(type: .success, paymentMethodManagerCategories: categories, withMessage: nil)
            } catch {
                Analytics.Service.fire(event: .message(message: "BDC Failed: \(error)", messageType: .error, severity: .error))
                let categories = config.paymentMethodManagerCategories ?? []
                let message = error.localizedDescription
                uiManager.dismissOrShowResultScreen(type: .failure, paymentMethodManagerCategories: categories, withMessage: message)
            }
        }
    }
    
    override func validate() throws {
        if PrimerAPIConfigurationModule.decodedJWTToken?.isValid != true {
            throw handled(primerError: .invalidClientToken())
        }
    }
    
    @MainActor
    private func processClientInstruction(_ response: ClientSessionInstructionResponse) async throws  {
        switch response.clientInstruction.type {
        case let .wait(response):
            let delay = response.pollDelayMilliseconds ?? 0
            try await Task.sleep(nanoseconds: UInt64(delay) * 1000_000)
            try await processClientInstruction(request(.expandClientSession))
        case let .execute(response):
            let delay = response.pollDelayMilliseconds ?? 0
            try await Task.sleep(nanoseconds: UInt64(delay) * 1000_000)
            try await startBackendDrivenCheckout(with: response)
            try await processClientInstruction(request(.expandClientSession))
        case let .end(response):
            if PrimerSettings.current.paymentHandling == .auto {
                await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(response.payload)
            }
        }
    }
    
    private func startBackendDrivenCheckout(with response: ClientInstructionExecuteResponse) async throws {
        let rawSchema = try response.schema.jsonString
        let initialState = response.parameters
        try await orchestrator?.start(rawSchema: rawSchema, context: generateContext(), initialState: initialState)
    }
    
    private func request<T: Decodable>(_ endpoint: BackendDrivenCheckoutEndpoint) async throws -> T {
        try await defaultNetworkService.request(endpoint)
    }
    
    private func generateContext() -> SDKContext {
        let apiConfiguration = PrimerAPIConfigurationModule.apiConfiguration
        let analyticsUrl = PrimerAPIConfigurationModule.decodedJWTToken?.analyticsUrlV2
        let checkoutSessionId = PrimerInternal.shared.checkoutSessionId

        return SDKContext(
            sdk: SDK(),
            device: SDKDevice(),
            app: SDKApp(identifier: Bundle.primerFrameworkIdentifier),
            session: SDKSession(configuration: apiConfiguration, sessionId: checkoutSessionId),
            payment: SDKPayment(paymentMethodType: config.type),
            merchant: SDKMerchant(primerAccountId: apiConfiguration?.primerAccountId),
            analytics: SDKAnalytics(url: analyticsUrl)
        )
    }
}

enum BackendDrivenCheckoutError: LocalizedError {
    case missingPayload
    
    var errorDescription: String? {
        switch self {
        case .missingPayload: "Missing payload"
        }
    }
}

private extension SDK {
    init() {
        self.init(
            type: PrimerSource.defaultSourceType,
            version: VersionUtils.releaseVersionNumber,
            integrationType: PrimerSource.defaultSourceType,
            paymentHandling: PrimerSettings.current.paymentHandling.rawValue
        )
    }
}

private extension SDKSession {
    init(configuration: PrimerAPIConfiguration?, sessionId: String?) {
        self.init(
            checkoutSessionId: sessionId,
            clientSessionId: configuration?.clientSession?.clientSessionId,
            customerId: configuration?.clientSession?.customer?.id
        )
    }
}

private extension SDKDevice {
    init() {
        let device = Device()
        self.init(
            type: UIDevice.deviceTypeName,
            make: "Apple",
            model: device.modelName,
            modelIdentifier: device.modelIdentifier,
            platformVersion: device.platformVersion,
            uniqueDeviceIdentifier: device.uniqueDeviceIdentifier,
            locale: device.locale
        )
    }
}

private extension UIDevice {
    static var isIPad: Bool {  UIDevice.current.userInterfaceIdiom == .pad }
    static var isIPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    static var deviceTypeName: String? { isIPad ? "tablet" : isIPhone ? "phone" : nil }
}
