//
//  BankSelectorScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default bank selector screen for CheckoutComponents.
/// Displays a searchable list of banks for redirect-based payment methods (iDEAL, Dotpay).
@available(iOS 15.0, *)
struct BankSelectorScreen: View, LogReporter {
  let scope: any PrimerBankSelectorScope

  @Environment(\.designTokens) private var tokens
  @State private var bankState: BankSelectorState = .init()

  var body: some View {
    VStack(spacing: 0) {
      headerSection
      contentSection
    }
    .frame(maxWidth: UIScreen.main.bounds.width)
    .navigationBarHidden(true)
    .background(CheckoutColors.background(tokens: tokens))
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.BankSelector.container,
        label: CheckoutComponentsStrings.bankSelectorTitle
      ))
    .onAppear {
      observeState()
    }
  }

  // MARK: - Header Section

  @MainActor
  private var headerSection: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      HStack {
        if scope.presentationContext.shouldShowBackButton {
          Button(
            action: {
              scope.onBack()
            },
            label: {
              HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                Image(systemName: RTLIcon.backChevron)
                  .font(PrimerFont.bodyMedium(tokens: tokens))
                Text(CheckoutComponentsStrings.backButton)
              }
              .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            }
          )
          .accessibility(
            config: AccessibilityConfiguration(
              identifier: AccessibilityIdentifiers.Common.backButton,
              label: CheckoutComponentsStrings.a11yBack,
              traits: [.isButton]
            ))
        }

        Spacer()

        if scope.dismissalMechanism.contains(.closeButton) {
          Button(
            CheckoutComponentsStrings.cancelButton,
            action: {
              scope.onCancel()
            }
          )
          .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
          .accessibility(
            config: AccessibilityConfiguration(
              identifier: AccessibilityIdentifiers.Common.closeButton,
              label: CheckoutComponentsStrings.a11yCancel,
              traits: [.isButton]
            ))
        }
      }

      Text(CheckoutComponentsStrings.bankSelectorTitle)
        .font(PrimerFont.titleXLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    .padding(.vertical, PrimerSpacing.large(tokens: tokens))
  }

  // MARK: - Content Section

  @MainActor
  @ViewBuilder
  private var contentSection: some View {
    switch bankState.status {
    case .loading:
      loadingView
    case .ready, .selected:
      bankListContent
    }
  }

  // MARK: - Loading View

  @MainActor
  private var loadingView: some View {
    VStack {
      Spacer()
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle())
        .scaleEffect(PrimerScale.large)
        .accessibility(
          config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.BankSelector.loadingIndicator,
            label: CheckoutComponentsStrings.a11yBankSelectorLoading
          ))
      Spacer()
    }
  }

  // MARK: - Bank List Content

  @MainActor
  private var bankListContent: some View {
    VStack(spacing: 0) {
      // Customizable search bar
      if let customSearchBar = scope.searchBarComponent {
        AnyView(customSearchBar())
      } else {
        searchBarSection
      }

      if bankState.filteredBanks.isEmpty, !bankState.searchQuery.isEmpty {
        // Customizable empty state (search results)
        if let customEmptyState = scope.emptyStateComponent {
          AnyView(customEmptyState())
        } else {
          searchEmptyStateView
        }
      } else if bankState.banks.isEmpty {
        noBanksAvailableView
      } else {
        bankListView
      }
    }
  }

  // MARK: - Search Bar

  @MainActor
  private var searchBarSection: some View {
    HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
      Image(systemName: "magnifyingglass")
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))

      TextField(
        CheckoutComponentsStrings.bankSelectorSearchPlaceholder,
        text: Binding(
          get: { bankState.searchQuery },
          set: { scope.search(query: $0) }
        )
      )
      .font(PrimerFont.body(tokens: tokens))
      .autocapitalization(.none)
      .disableAutocorrection(true)

      if !bankState.searchQuery.isEmpty {
        Button(action: { scope.search(query: "") }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        }
      }
    }
    .padding(PrimerSpacing.medium(tokens: tokens))
    .background(CheckoutColors.gray100(tokens: tokens))
    .cornerRadius(PrimerRadius.small(tokens: tokens))
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    .padding(.bottom, PrimerSpacing.medium(tokens: tokens))
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.BankSelector.searchBar,
        label: CheckoutComponentsStrings.a11yBankSelectorSearchLabel,
        hint: CheckoutComponentsStrings.a11yBankSelectorSearchHint
      ))
  }

  // MARK: - Bank List

  @MainActor
  private var bankListView: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(bankState.filteredBanks) { bank in
          bankRow(for: bank)
          Divider()
            .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        }
      }
    }
  }

  @MainActor
  @ViewBuilder
  private func bankRow(for bank: Bank) -> some View {
    if let customBankItem = scope.bankItemComponent {
      Button(action: { scope.selectBank(bank) }) {
        AnyView(customBankItem(bank))
      }
      .disabled(bank.isDisabled)
    } else {
      defaultBankRow(for: bank)
    }
  }

  @MainActor
  private func defaultBankRow(for bank: Bank) -> some View {
    Button(action: { scope.selectBank(bank) }) {
      HStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
        bankIcon(for: bank)

        Text(bank.name)
          .font(PrimerFont.body(tokens: tokens))
          .foregroundColor(
            bank.isDisabled
              ? CheckoutColors.textSecondary(tokens: tokens)
              : CheckoutColors.textPrimary(tokens: tokens)
          )

        Spacer()

        if bank.isDisabled {
          Text(CheckoutComponentsStrings.bankSelectorBankUnavailable)
            .font(PrimerFont.caption(tokens: tokens))
            .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        }
      }
      .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
      .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
      .contentShape(Rectangle())
    }
    .disabled(bank.isDisabled)
    .opacity(bank.isDisabled ? 0.5 : 1.0)
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.BankSelector.bankItem(bank.id),
        label: bank.isDisabled
          ? CheckoutComponentsStrings.a11yBankSelectorBankItemDisabled(bank.name)
          : bank.name,
        hint: bank.isDisabled
          ? nil
          : CheckoutComponentsStrings.a11yBankSelectorBankItemHint,
        traits: [.isButton]
      ))
  }

  @MainActor
  private func bankIcon(for bank: Bank) -> some View {
    Group {
      if let iconUrl = bank.iconUrl {
        AsyncImage(url: iconUrl) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
        } placeholder: {
          RoundedRectangle(cornerRadius: 4)
            .fill(CheckoutColors.gray100(tokens: tokens))
        }
      } else {
        RoundedRectangle(cornerRadius: 4)
          .fill(CheckoutColors.gray100(tokens: tokens))
      }
    }
    .frame(width: 32, height: 32)
    .clipShape(RoundedRectangle(cornerRadius: 4))
  }

  // MARK: - Empty States

  @MainActor
  private var searchEmptyStateView: some View {
    VStack {
      Spacer()
      Text(CheckoutComponentsStrings.bankSelectorEmptyState)
        .font(PrimerFont.body(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .multilineTextAlignment(.center)
        .accessibility(
          config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.BankSelector.emptyState,
            label: CheckoutComponentsStrings.a11yBankSelectorEmptyState
          ))
      Spacer()
    }
    .padding(PrimerSpacing.xlarge(tokens: tokens))
  }

  @MainActor
  private var noBanksAvailableView: some View {
    VStack {
      Spacer()
      Text(CheckoutComponentsStrings.bankSelectorNoBanksAvailable)
        .font(PrimerFont.body(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .multilineTextAlignment(.center)
      Spacer()
    }
    .padding(PrimerSpacing.xlarge(tokens: tokens))
  }

  // MARK: - State Observation

  private func observeState() {
    Task {
      for await state in scope.state {
        await MainActor.run {
          bankState = state
        }
      }
    }
  }
}
