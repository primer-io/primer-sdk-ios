//
//  DefaultPaymentMethodSelectionScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class DefaultPaymentMethodSelectionScope: PrimerPaymentMethodSelectionScope, ObservableObject, LogReporter {
    // MARK: - Properties

    @Published private var internalState = PrimerPaymentMethodSelectionState()

    public var state: AsyncStream<PrimerPaymentMethodSelectionState> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                for await value in $internalState.values {
                    continuation.yield(value)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public var dismissalMechanism: [DismissalMechanism] {
        checkoutScope?.dismissalMechanism ?? []
    }

    public var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? {
        checkoutScope?.selectedVaultedPaymentMethod
    }

    // MARK: - UI Customization Properties

    public var screen: PaymentMethodSelectionScreenComponent?
    public var container: ContainerComponent?
    public var paymentMethodItem: PaymentMethodItemComponent?
    public var categoryHeader: CategoryHeaderComponent?
    public var emptyStateView: Component?

    // MARK: - Private Properties

    private weak var checkoutScope: DefaultCheckoutScope?
    private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
    private var accessibilityAnnouncementService: AccessibilityAnnouncementService?

    // MARK: - Initialization

    init(
        checkoutScope: DefaultCheckoutScope,
        analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil
    ) {
        self.checkoutScope = checkoutScope
        self.analyticsInteractor = analyticsInteractor

        Task {
            await loadPaymentMethods()
            await loadVaultedPaymentMethods()
            await resolveAccessibilityService()
        }
    }

    // MARK: - Vaulted Payment Methods

    private func loadVaultedPaymentMethods() async {
        await refreshVaultedPaymentMethods()
    }

    /// Refreshes the vaulted payment methods list from the server
    func refreshVaultedPaymentMethods() async {
        do {
            guard let container = await DIContainer.current else { return }
            let repository = try await container.resolve(HeadlessRepository.self)
            let vaultedMethods = try await repository.fetchVaultedPaymentMethods()

            checkoutScope?.setVaultedPaymentMethods(vaultedMethods)
            syncSelectedVaultedPaymentMethod()
        } catch {
            logger.error(message: "[Vault] Failed to load vaulted payment methods: \(error.localizedDescription)")
        }
    }

    // MARK: - Accessibility Setup

    private func resolveAccessibilityService() async {
        do {
            guard let container = await DIContainer.current else { return }
            accessibilityAnnouncementService = try await container.resolve(AccessibilityAnnouncementService.self)
        } catch {
            // Failed to resolve AccessibilityAnnouncementService, accessibility announcements will be disabled
            logger.debug(message: "[A11Y] Failed to resolve AccessibilityAnnouncementService: \(error.localizedDescription)")
        }
    }

    // MARK: - Setup

    private func loadPaymentMethods() async {
        guard let checkoutScope else {
            internalState.error = CheckoutComponentsStrings.checkoutScopeNotAvailable
            return
        }

        for await checkoutState in checkoutScope.state {
            if case .ready = checkoutState {
                let paymentMethods = checkoutScope.availablePaymentMethods

                let mapper: PaymentMethodMapper
                do {
                    guard let container = await DIContainer.current else {
                        throw NSError(domain: "DIContainer", code: 1, userInfo: [NSLocalizedDescriptionKey: "DIContainer.current is nil"])
                    }
                    mapper = try await container.resolve(PaymentMethodMapper.self)
                } catch {
                    // Fallback to manual creation without surcharge data
                    let composablePaymentMethods = paymentMethods.map { method in
                        CheckoutPaymentMethod(
                            id: method.id,
                            type: method.type,
                            name: method.name,
                            icon: method.icon,
                            metadata: nil
                        )
                    }
                    internalState.paymentMethods = composablePaymentMethods
                    internalState.filteredPaymentMethods = composablePaymentMethods
                    break
                }

                let composablePaymentMethods = mapper.mapToPublic(paymentMethods)

                internalState.paymentMethods = composablePaymentMethods
                internalState.filteredPaymentMethods = composablePaymentMethods

                break
            } else if case let .failure(error) = checkoutState {
                internalState.error = error.localizedDescription
                break
            }
        }
    }

    // MARK: - Public Methods

    public func onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod) {
        internalState.selectedPaymentMethod = paymentMethod

        let selectionMessage = "\(paymentMethod.name) selected"
        accessibilityAnnouncementService?.announceStateChange(selectionMessage)
        logger.debug(message: "[A11Y] Payment method selected announcement: \(selectionMessage)")

        Task {
            await trackPaymentMethodSelection(paymentMethod.type)
        }

        let internalMethod = InternalPaymentMethod(
            id: paymentMethod.id,
            type: paymentMethod.type,
            name: paymentMethod.name,
            icon: paymentMethod.icon
        )

        checkoutScope?.handlePaymentMethodSelection(internalMethod)
    }

    private func trackPaymentMethodSelection(_ paymentMethodType: String) async {
        await analyticsInteractor?.trackEvent(.paymentMethodSelection, metadata: .payment(PaymentEvent(paymentMethod: paymentMethodType)))
    }

    public func onCancel() {
        checkoutScope?.onDismiss()
    }

    // MARK: - Vault Payment

    public func payWithVaultedPaymentMethod() async {
        guard let vaultedMethod = selectedVaultedPaymentMethod else {
            logger.warn(message: "[Vault] No vaulted payment method selected")
            return
        }

        if shouldRequireCvvInput(for: vaultedMethod), !internalState.requiresCvvInput {
            logger.info(message: "[Vault] CVV required for vaulted card payment, showing CVV input")
            internalState.requiresCvvInput = true
            // Collapse payment methods section to focus on CVV entry
            internalState.isPaymentMethodsExpanded = false
            return
        }

        if internalState.requiresCvvInput {
            await payWithVaultedPaymentMethodAndCvv(internalState.cvvInput)
            return
        }

        await executeVaultPayment(vaultedMethod: vaultedMethod, additionalData: nil)
    }

    public func payWithVaultedPaymentMethodAndCvv(_ cvv: String) async {
        guard let vaultedMethod = selectedVaultedPaymentMethod else {
            logger.warn(message: "[Vault] No vaulted payment method selected")
            return
        }

        logger.info(message: "[Vault] Starting payment with vaulted method: \(vaultedMethod.id) with CVV")

        let additionalData = PrimerVaultedCardAdditionalData(cvv: cvv)
        await executeVaultPayment(vaultedMethod: vaultedMethod, additionalData: additionalData)
    }

    public func updateCvvInput(_ cvv: String) {
        internalState.cvvInput = cvv
        let validationResult = validateCvv(cvv)
        internalState.isCvvValid = validationResult.isValid
        internalState.cvvError = validationResult.errorMessage
    }

    /// Validates CVV input and returns validation state with optional error message.
    /// - Parameter cvv: The CVV string to validate
    /// - Returns: Tuple with `isValid` flag and optional `errorMessage`
    private func validateCvv(_ cvv: String) -> (isValid: Bool, errorMessage: String?) {
        let cardNetwork = getCardNetworkFromSelectedVaultedMethod()
        let expectedLength = cardNetwork.validation?.code.length ?? 3

        // Empty input: not valid yet, but no error (user hasn't started typing)
        guard !cvv.isEmpty else {
            return (false, nil)
        }

        // Non-numeric characters: invalid with error
        guard cvv.allSatisfy(\.isNumber) else {
            return (false, CheckoutComponentsStrings.cvvInvalidError)
        }

        // Too many digits: invalid with error
        if cvv.count > expectedLength {
            return (false, CheckoutComponentsStrings.cvvInvalidError)
        }

        // Exact length: valid, no error
        if cvv.count == expectedLength {
            return (true, nil)
        }

        // Partial input (fewer digits): not yet valid, no error (user still typing)
        return (false, nil)
    }

    // MARK: - Vault Payment Helpers

    private func executeVaultPayment(
        vaultedMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod,
        additionalData: PrimerVaultedPaymentMethodAdditionalData?
    ) async {
        logger.info(message: "[Vault] Starting payment with vaulted method: \(vaultedMethod.id)")

        internalState.isVaultPaymentLoading = true

        await analyticsInteractor?.trackEvent(
            .paymentSubmitted,
            metadata: .payment(PaymentEvent(paymentMethod: vaultedMethod.paymentMethodType))
        )

        do {
            guard let container = await DIContainer.current else {
                throw PrimerError.unknown(message: "DIContainer.current is nil")
            }
            let interactor = try await container.resolve(SubmitVaultedPaymentInteractor.self)

            let result = try await interactor.execute(
                vaultedPaymentMethodId: vaultedMethod.id,
                paymentMethodType: vaultedMethod.paymentMethodType,
                additionalData: additionalData
            )

            internalState.isVaultPaymentLoading = false
            resetCvvState()
            checkoutScope?.handlePaymentSuccess(result)

        } catch {
            internalState.isVaultPaymentLoading = false
            // Clear CVV on error but keep CVV mode active for retry
            internalState.cvvInput = ""
            internalState.isCvvValid = false
            logger.error(message: "[Vault] Payment failed: \(error.localizedDescription)")

            let primerError = error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
            checkoutScope?.handlePaymentError(primerError)
        }
    }

    private func shouldRequireCvvInput(for vaultedMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) -> Bool {
        // Only cards can require CVV
        guard vaultedMethod.paymentInstrumentType == .paymentCard ||
              vaultedMethod.paymentInstrumentType == .cardOffSession else {
            return false
        }

        do {
            guard let container = DIContainer.currentSync else { return false }
            let configService = try container.resolveSync(ConfigurationService.self)
            return configService.captureVaultedCardCvv
        } catch {
            logger.error(message: "[Vault] Failed to resolve ConfigurationService: \(error.localizedDescription)")
            return false
        }
    }

    private func getCardNetworkFromSelectedVaultedMethod() -> CardNetwork {
        guard let vaultedMethod = selectedVaultedPaymentMethod else { return .unknown }

        let network = vaultedMethod.paymentInstrumentData.network ??
                     vaultedMethod.paymentInstrumentData.binData?.network ?? "Card"
        return CardNetwork(rawValue: network.uppercased()) ?? .unknown
    }

    private func resetCvvState() {
        internalState.requiresCvvInput = false
        internalState.cvvInput = ""
        internalState.isCvvValid = false
        internalState.cvvError = nil
    }

    public func showAllVaultedPaymentMethods() {
        logger.info(message: "[Vault] Navigating to all vaulted payment methods screen")
        checkoutScope?.updateNavigationState(.vaultedPaymentMethods)
    }

    public func showOtherWaysToPay() {
        logger.info(message: "[PaymentSelection] Expanding to show all payment methods")
        internalState.isPaymentMethodsExpanded = true
    }

    func collapsePaymentMethods() {
        logger.info(message: "[PaymentSelection] Collapsing payment methods section")
        internalState.isPaymentMethodsExpanded = false
    }

    public func searchPaymentMethods(_ query: String) {
        internalState.searchQuery = query

        if query.isEmpty {
            internalState.filteredPaymentMethods = internalState.paymentMethods
        } else {
            let lowercasedQuery = query.lowercased()
            internalState.filteredPaymentMethods = internalState.paymentMethods.filter { method in
                method.name.lowercased().contains(lowercasedQuery) ||
                    method.type.lowercased().contains(lowercasedQuery)
            }
        }
    }

    // MARK: - Vault Selection Update

    /// Syncs internal state with checkout scope's selected vaulted payment method.
    /// Called by DefaultCheckoutScope when selection changes.
    /// Source of truth is always `checkoutScope.selectedVaultedPaymentMethod`.
    func syncSelectedVaultedPaymentMethod() {
        let previousMethodId = internalState.selectedVaultedPaymentMethod?.id
        let newMethodId = checkoutScope?.selectedVaultedPaymentMethod?.id

        internalState.selectedVaultedPaymentMethod = checkoutScope?.selectedVaultedPaymentMethod

        // When switching to a different vaulted method, reset CVV state
        if previousMethodId != newMethodId {
            resetCvvState()
        }
    }

    // MARK: - Vault Delete

    /// Deletes a vaulted payment method and refreshes the list
    /// - Parameter method: The vaulted payment method to delete
    /// - Throws: Error if deletion fails
    public func deleteVaultedPaymentMethod(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) async throws {
        logger.info(message: "[Vault] Deleting vaulted payment method: \(method.id)")

        guard let container = await DIContainer.current else {
            throw PrimerError.unknown(message: "DIContainer.current is nil")
        }

        let repository = try await container.resolve(HeadlessRepository.self)
        try await repository.deleteVaultedPaymentMethod(method.id)

        logger.info(message: "[Vault] Successfully deleted payment method: \(method.id)")

        await refreshVaultedPaymentMethods()
    }

}
