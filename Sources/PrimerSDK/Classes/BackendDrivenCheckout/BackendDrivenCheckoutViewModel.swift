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
    private var hasCancelled = false
    private let manifestRepository = ManifestRepository()
    
    override func start() {
        Task { @MainActor in
            defer { config.tokenizationViewModel = nil }
            do {
                hasCancelled = false
                PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: nil, message: nil)
                
                let manifest = try await manifestRepository.fetchManifest(publicKeyB64s: publicKeyB64s)
                orchestrator = PrimerStepOrchestrator(manifest: manifest, context: generateContext())
                orchestrator?.onCancelled = { [weak self] in self?.handleCancelled() }
                let response: ClientSessionInstructionResponse = try await request(.pay(paymentMethod: config))
                
                logBDCStarted()
                try await processClientInstruction(response)
                let categories = config.paymentMethodManagerCategories ?? []
                uiManager.dismissOrShowResultScreen(type: .success, paymentMethodManagerCategories: categories, withMessage: nil)
            } catch {
                await handleError(error)
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
        guard !hasCancelled else { throw Error.cancellationError }
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
            switch response.payload.checkoutOutcome {
            case .complete: await handleBDCComplete(response)
            case .failure: await handleBDCFailure(response)
            case .determineFromPaymentStatus, .none: break //TODO:
            }

        }
    }
    
    private func handleBDCComplete(_ response: ClientInstructionEndResponse) async {
        if PrimerSettings.current.paymentHandling == .auto {
            await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(response.payload)
        }
    }
    
    private func handleBDCFailure(_ response: ClientInstructionEndResponse) async {
        guard let payment = response.payload.payment, let paymentId = payment.id else {
            return await handleError(PrimerError.unknown(message: "Payment or paymentId was nil"))
        }
        await handleError(PrimerError.paymentFailed(
            paymentMethodType: config.type,
            paymentId: paymentId,
            orderId: payment.orderId,
            status: payment.status,
        ))
    }
    
    private func handleError(_ error: Swift.Error) async {
        Analytics.Service.fire(event: .message(message: "BDC Failed: \(error)", messageType: .error, severity: .error))
        if let error = error as? Error, error == .cancellationError {
            return
        } else if let error = error as? PrimerErrorProtocol {
            let decision = await PrimerDelegateProxy.primerDidFailWithError(error, data: paymentCheckoutData)
            switch decision.type {
            case let .fail(message): handleFailureFlow(errorMessage: message)
            }
        }
    }
    
    private func logBDCStarted() {
        let event = Analytics.Event.message(
            message: "BDC flow started.",
            messageType: .backendDrivenCheckoutStarted,
            severity: .info,
            context: ["trustedKeyFingerprints": publicKeyB64s.map(\.fingerprint)]
        )
        Analytics.Service.fire(event: event)
    }
    
    private func startBackendDrivenCheckout(with response: ClientInstructionExecuteResponse) async throws {
        let rawSchema = try response.schema.jsonString
        let initialState = response.parameters
        try await orchestrator?.start(rawSchema: rawSchema, initialState: initialState)
    }
    
    private func request<T: Decodable>(_ endpoint: BackendDrivenCheckoutEndpoint) async throws -> T {
        try await defaultNetworkService.request(endpoint)
    }
    
    private func handleCancelled() {
        Task {
            hasCancelled = true
            await handleError(PrimerError.cancelled(paymentMethodType: config.type))
        }
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

private extension BackendDrivenCheckoutViewModel {
    var publicKeyB64s: [String] {
        [
            "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEUM5exrePPsIdkWFL6IjKdYmEDoEHBZkoBvrApQpmDEhQ7IisLTCiP0byqN+5B5V60QjAj4I/Bw292h8gPGZyOg==",
            "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAERA0j68aAYtwMDagEx2FY+CBbm2+MAYviARSMxWHt1Qt8wGyVvLJ2FqIvg4m2pKfb7GqUwzuJRD/gaOrO2ZJulQ==",
            "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEp7v1KpNTWcI9yJSoZYGvRxsPtciT99P2YDpISVLyD6BDD8xqJ11A8v2/elOEPaSxx5hConszht1cOlPp9YdTsA=="
        ]
    }
        
    enum Error: Swift.Error {
        case cancellationError
    }
}

import CryptoKit

private extension String {
    var fingerprint: String? {
        guard let keyBytes = Data(base64Encoded: self) else { return nil }
        return SHA256.hash(data: keyBytes)
            .map { String(format: "%02x", $0) }
            .joined(separator: "")
    }
}

private extension SDK {
    init() {
        self.init(
            type: PrimerSource.defaultSourceType,
            version: VersionUtils.releaseVersionNumber,
            integrationType: PrimerInternal.shared.sdkIntegrationType?.rawValue ?? "unknown",
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

private struct BDCContextParams: Encodable {
    let trustedKeyFingerprints: [String]
}
