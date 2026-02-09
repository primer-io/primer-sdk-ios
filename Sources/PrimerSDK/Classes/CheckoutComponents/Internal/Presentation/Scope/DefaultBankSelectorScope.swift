//
//  DefaultBankSelectorScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

/// Default implementation of PrimerBankSelectorScope that handles the bank
/// selection payment flow (iDEAL, Dotpay).
@available(iOS 15.0, *)
@MainActor
public final class DefaultBankSelectorScope: PrimerBankSelectorScope, ObservableObject, LogReporter {

  // MARK: - Public Properties

  public private(set) var presentationContext: PresentationContext

  public var dismissalMechanism: [DismissalMechanism] {
    checkoutScope?.dismissalMechanism ?? []
  }

  public var state: AsyncStream<BankSelectorState> {
    AsyncStream { continuation in
      let task = Task { @MainActor in
        for await _ in $internalState.values {
          continuation.yield(internalState)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  // MARK: - UI Customization Properties

  public var screen: BankSelectorScreenComponent?
  public var bankItemComponent: BankItemComponent?
  public var searchBarComponent: Component?
  public var emptyStateComponent: Component?

  // MARK: - Private Properties

  private weak var checkoutScope: DefaultCheckoutScope?
  private let interactor: ProcessBankSelectorPaymentInteractor
  private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
  private let paymentMethodType: String

  @Published private var internalState = BankSelectorState()

  // MARK: - Initialization

  init(
    checkoutScope: DefaultCheckoutScope,
    presentationContext: PresentationContext = .fromPaymentSelection,
    interactor: ProcessBankSelectorPaymentInteractor,
    paymentMethodType: String,
    analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil
  ) {
    self.checkoutScope = checkoutScope
    self.presentationContext = presentationContext
    self.interactor = interactor
    self.paymentMethodType = paymentMethodType
    self.analyticsInteractor = analyticsInteractor
  }

  // MARK: - PrimerPaymentMethodScope Methods

  public func start() {
    logger.debug(message: "Bank selector scope started for \(paymentMethodType)")
    internalState.status = .loading

    Task {
      await fetchBanks()
    }
  }

  public func submit() {
    if let bank = internalState.selectedBank {
      selectBank(bank)
    }
  }

  public func cancel() {
    logger.debug(message: "Bank selector cancelled")
    checkoutScope?.onDismiss()
  }

  // MARK: - Bank Selection Actions

  public func search(query: String) {
    internalState.searchQuery = query

    if query.isEmpty {
      internalState.filteredBanks = internalState.banks
    } else {
      let normalizedQuery = query.lowercased().folding(
        options: .diacriticInsensitive,
        locale: nil
      )
      internalState.filteredBanks = internalState.banks.filter { bank in
        bank.name.lowercased().folding(
          options: .diacriticInsensitive,
          locale: nil
        ).contains(normalizedQuery)
      }
    }
  }

  public func selectBank(_ bank: Bank) {
    guard !bank.isDisabled else {
      logger.debug(message: "Attempted to select disabled bank: \(bank.id)")
      return
    }

    logger.debug(message: "Bank selected: \(bank.name) (\(bank.id))")
    internalState.selectedBank = bank
    internalState.status = .selected(bank)

    checkoutScope?.startProcessing()

    Task {
      await analyticsInteractor?.trackEvent(
        .paymentSubmitted,
        metadata: .payment(PaymentEvent(paymentMethod: paymentMethodType))
      )

      await performPayment(bank: bank)
    }
  }

  // MARK: - Navigation Methods

  public func onBack() {
    if presentationContext.shouldShowBackButton {
      checkoutScope?.checkoutNavigator.navigateBack()
    }
  }

  public func onCancel() {
    checkoutScope?.onDismiss()
  }

  // MARK: - Private Methods

  private func fetchBanks() async {
    await analyticsInteractor?.trackEvent(
      .paymentMethodSelection,
      metadata: .payment(PaymentEvent(paymentMethod: paymentMethodType))
    )

    do {
      let banks = try await interactor.fetchBanks(paymentMethodType: paymentMethodType)

      internalState.banks = banks
      internalState.filteredBanks = banks
      internalState.status = .ready

      logger.debug(message: "Loaded \(banks.count) banks for \(paymentMethodType)")
    } catch {
      logger.error(message: "Failed to fetch banks: \(error.localizedDescription)")
      let primerError =
        error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
      checkoutScope?.handlePaymentError(primerError)
    }
  }

  private func performPayment(bank: Bank) async {
    do {
      let result = try await interactor.execute(
        bankId: bank.id,
        paymentMethodType: paymentMethodType
      )

      checkoutScope?.handlePaymentSuccess(result)
    } catch {
      logger.error(message: "Bank selector payment failed: \(error.localizedDescription)")
      let primerError =
        error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
      checkoutScope?.handlePaymentError(primerError)
    }
  }
}
