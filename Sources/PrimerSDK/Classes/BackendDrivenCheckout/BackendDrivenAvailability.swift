//
//  BackendDrivenAvailability.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

/// Which backend-driven methods this SDK can run, as the state processor settles it.
enum BackendDrivenAvailability {
    private static let lock = NSLock()
    private static var availableIds: Set<String> = []

    /// Methods that aren't backend-driven always are.
    static func isAvailable(_ method: PrimerPaymentMethod) -> Bool {
        guard method.isBackendDriven else { return true }
        guard let id = method.id else { return false }
        lock.lock()
        defer { lock.unlock() }
        return availableIds.contains(id)
    }

    /// Checks the configuration's backend-driven methods, for `isAvailable`. The method lists wait for it, 5 s at most.
    @MainActor
    static func settle(timeout: UInt64 = 5_000_000_000) async {
        let methods = PrimerAPIConfiguration.paymentMethodConfigs?.filter(\.isBackendDriven) ?? []
        guard !methods.isEmpty else { return reset() }
        do {
            apply(try await withTimeout(nanoseconds: timeout) { try await check(methods) }, to: methods)
        } catch {
            for method in methods {
                warn("\(method.type) could not be checked against this SDK's capabilities, so it will not be available in this checkout. \(error)")
            }
            reset()
        }
    }

    /// Keeps the methods whose verdict is met, and warns about the rest.
    static func apply(_ verdicts: ClientRequirementsVerdicts, to methods: [PrimerPaymentMethod]) {
        store(Set(methods.compactMap { availableId(of: $0, verdicts: verdicts) }))
    }

    static func reset() {
        store([])
    }
}

private extension BackendDrivenAvailability {
    @MainActor
    static func check(_ methods: [PrimerPaymentMethod]) async throws -> ClientRequirementsVerdicts {
        guard let manifestProvider = NetworkSignedManifestProvider.current else { throw PrimerError.invalidClientToken() }
        let engine = try await BDCEngineProvider.shared.engine(manifestProvider: manifestProvider)
        let items = methods.compactMap { method in
            method.id.map { ClientRequirementsItem(id: $0, type: method.type, clientRequirements: method.clientRequirements) }
        }
        let client = BDCClient(capabilities: .current, context: .checkout())
        return try await ClientRequirementsSettler(engine: engine).settle(items, client: client)
    }

    static func availableId(of method: PrimerPaymentMethod, verdicts: ClientRequirementsVerdicts) -> String? {
        guard let id = method.id, let verdict = verdicts[id] else {
            warn("\(method.type) is not in the checked configuration, so it will not be available in this checkout.")
            return nil
        }
        guard verdict.satisfied else {
            warn(
                "\(method.type) was filtered out because this integration does not meet its requirements. " +
                    "Please check the integration guide: \(guide)"
            )
            report(method, unmet: verdict.unmet)
            return nil
        }
        return id
    }

    static func report(_ method: PrimerPaymentMethod, unmet: [UnmetClientRequirement]) {
        let unmetJSON = (try? unmet.data()).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        Analytics.Service.fire(event: .message(
            message: "Client requirements not met for \(method.type)",
            messageType: .backendDrivenClientRequirementsNotMet,
            severity: .warning,
            context: ["paymentMethodType": method.type, "unmet": unmetJSON]
        ))
    }

    static var guide: String {
        PrimerInternal.shared.sdkIntegrationType == .headless
            ? "https://primer.io/docs/checkout/headless"
            : "https://primer.io/docs/checkout/drop-in"
    }

    static func store(_ ids: Set<String>) {
        lock.lock()
        availableIds = ids
        lock.unlock()
    }

    static func warn(_ message: String) {
        PrimerLogging.shared.logger.warn(message: message)
    }
}
