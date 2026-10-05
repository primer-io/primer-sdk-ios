//
//  ClientRequirements.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

enum ClientRequirements {
    private static var logger: PrimerLogger { PrimerLogging.shared.logger }

    @MainActor
    static func checkConfiguration() async {
        let methods = PrimerAPIConfiguration.paymentMethodConfigs
        guard let methods, methods.contains(where: \.isBackendDriven) else { return }
        
        let verdicts: ClientRequirementsVerdicts
        
        do {
            verdicts = try await check(methods.filter(\.isBackendDriven))
        } catch {
            logger.warn(message: "Client requirements check failed: \(error)")
            verdicts = [:]
        }
        
        for method in methods {
            guard let verdict = method.id.flatMap({ verdicts[$0] }), !verdict.satisfied else { continue }
            reportUnmet(verdict.unmet, for: method)
        }
        
        let available = methods.filter { method in
            !method.isBackendDriven || method.id.flatMap { verdicts[$0]?.satisfied } == true
        }
        
        let hidden = methods.filter { method in !available.contains { $0 === method } }.map(\.type)
        logger.info(message: "Client requirements checked, hidden: \(hidden)")
        PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods = available
    }

    @MainActor
    static func check(_ methods: [PrimerPaymentMethod]) async throws -> ClientRequirementsVerdicts {
        logger.info(message: "Client requirements: waiting for the state processor to load")
        let provider = NetworkSignedManifestProvider(token: PrimerAPIConfigurationModule.decodedJWTToken)
        let engine = try await BDCEngineProvider.shared.engine(manifestProvider: provider)
        let requirements = buildRequirements(from: methods)
        let client = BDCClient(capabilities: .current, context: .generate())
        logger.info(message: "Client requirements: asking the state processor about \(methods.map(\.type))")
        return try await engine.checkClientRequirements(items: requirements, client: client)
    }

    private static func reportUnmet(_ unmet: [UnmetClientRequirement], for method: PrimerPaymentMethod) {
        let data = try? unmet.data()
        let unmetJSON = data.flatMap { String(data: $0, encoding: .utf8) }
        guard let unmetJSON else { return }
        
        let message = "Client requirements not met for \(method.type)"
        let context: [String: String] = ["paymentMethodType": method.type, "unmet": unmetJSON]
        let type: Analytics.Event.Property.MessageType = .backendDrivenClientRequirementsNotMet
        let event: Analytics.Event = .message(message: message, messageType: type, severity: .warning, context: context)
        
        Analytics.Service.fire(event: event)
    }

    private static func buildRequirements(from methods: [PrimerPaymentMethod]) -> [PaymentMethodRequirements] {
        methods.compactMap { method -> PaymentMethodRequirements? in
            guard let id = method.id else { return nil }
            return PaymentMethodRequirements(
                id: id,
                type: method.type,
                clientRequirements: method.clientRequirements
            )
        }
    }
}
