//
//  SelectCountryScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

/// Default country selection screen for CheckoutComponents
@available(iOS 15.0, *)
struct SelectCountryScreen: View, LogReporter {
  let scope: PrimerSelectCountryScope
  let onDismiss: (() -> Void)?

  @Environment(\.designTokens) private var tokens
  @Environment(\.sizeCategory) private var sizeCategory  // Observes Dynamic Type changes
  @State private var countryState: PrimerSelectCountryState = .init()
  @FocusState private var isSearchFocused: Bool

  var body: some View {
    // NavigationView is deprecated but retained: NavigationStack requires iOS 16 and this module
    // supports iOS 15. The trailing item below uses the modern .toolbar API (valid on iOS 15).
    NavigationView {
      mainContent
    }
    .environment(\.primerSelectCountryScope, scope)
    .task {
      for await state in scope.state {
        countryState = state
      }
    }
  }

  private var mainContent: some View {
    VStack(spacing: 0) {
      searchBarSection
      countryListSection
    }
    .background(CheckoutColors.background(tokens: tokens))
    .navigationTitle(CheckoutComponentsStrings.selectCountryTitle)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        CheckoutHeaderButton(
          config: .closeButton(
            identifier: AccessibilityIdentifiers.SelectCountry.cancelButton,
            action: { onDismiss?() }
          )
        )
      }
    }
  }

  private var searchBarSection: some View {
    Group {
      if let customSearchBar = scope.searchBar {
        AnyView(customSearchBar(
          countryState.searchQuery,
          { query in
            scope.onSearch(query: query)
          }, CheckoutComponentsStrings.searchCountriesPlaceholder))
      } else {
        defaultSearchBar
      }
    }
  }

  private var defaultSearchBar: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundColor(CheckoutColors.iconPrimary(tokens: tokens))
        // Lets a tap on the icon reach the tap target behind it.
        .allowsHitTesting(false)

      TextField(
        CheckoutComponentsStrings.searchCountriesPlaceholder,
        text: Binding(
          get: { countryState.searchQuery },
          set: { scope.onSearch(query: $0) }
        ),
        prompt: Text(CheckoutComponentsStrings.searchCountriesPlaceholder)
          .font(PrimerFont.bodyLarge(tokens: tokens))
          .foregroundColor(CheckoutColors.textPlaceholder(tokens: tokens))
      )
      .textFieldStyle(PlainTextFieldStyle())
      .primerFieldTypography(.bodyLarge, tokens: tokens)
      .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      .tint(CheckoutColors.borderFocus(tokens: tokens))
      .focused($isSearchFocused)
      .accessibilityIdentifier(AccessibilityIdentifiers.SelectCountry.searchField)

      if !countryState.searchQuery.isEmpty {
        Button(
          action: {
            scope.onSearch(query: "")
          },
          label: {
            Image(systemName: "xmark")
              .foregroundColor(CheckoutColors.iconPrimary(tokens: tokens))
          })
        .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(.horizontal, PrimerSpacing.medium(tokens: tokens))
    // A minimum, as the field's font can outgrow the box at the largest text sizes.
    .frame(minHeight: PrimerComponentHeight.inputField(tokens: tokens))
    .focusesFieldOnTap { isSearchFocused = true }
    .background(CheckoutColors.inputBackground(tokens: tokens))
    .cornerRadius(PrimerRadius.small(tokens: tokens))
    .overlay(
      RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
        .strokeBorder(
          isSearchFocused ? CheckoutColors.borderFocus(tokens: tokens) : CheckoutColors.borderDefault(tokens: tokens),
          lineWidth: isSearchFocused ? PrimerBorderWidth.focused(tokens: tokens) : PrimerBorderWidth.standard(tokens: tokens)
        )
    )
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    .padding(.vertical, PrimerSpacing.xxlarge(tokens: tokens))
  }

  private var countryListSection: some View {
    Group {
      if countryState.isLoading {
        loadingView
      } else if countryState.filteredCountries.isEmpty {
        emptyStateView
      } else {
        countryListView
      }
    }
  }

  private var loadingView: some View {
    VStack {
      Spacer()
      ProgressView()
        .progressViewStyle(
          CircularProgressViewStyle(tint: CheckoutColors.loader(tokens: tokens))
        )
        .scaleEffect(PrimerScale.small)
        .accessibility(
          config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.Common.loadingIndicator,
            label: CheckoutComponentsStrings.a11yLoading
          ))
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder
  private var emptyStateView: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      Image(systemName: "globe")
        .font(PrimerFont.largeIcon(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))

      Text(CheckoutComponentsStrings.noCountriesFound)
        .primerTypography(.body, tokens: tokens)
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var countryListView: some View {
    List {
      ForEach(countryState.filteredCountries, id: \.code) { country in
        Group {
          if let customCountryItem = scope.countryItem {
            AnyView(
              customCountryItem(country) {
                selectCountry(country)
              })
          } else {
            CountryItemView(
              country: country,
              isSelected: country.code == countryState.selectedCountry?.code,
              onTap: {
                selectCountry(country)
              }
            )
          }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: PrimerSpacing.large(tokens: tokens), bottom: 0, trailing: PrimerSpacing.large(tokens: tokens)))
        .listRowSeparator(.hidden)
      }
    }
    .listStyle(PlainListStyle())
    .environment(\.defaultMinListRowHeight, PrimerComponentHeight.interactive)
    .primerClearListBackground()
    .safeAreaInset(edge: .bottom, spacing: 0) {
      Color.clear.frame(height: PrimerSpacing.large(tokens: tokens))
    }
  }

  private func selectCountry(_ country: PrimerCountry) {
    scope.onCountrySelected(countryCode: country.code, countryName: country.name)
    onDismiss?()
  }

}

/// Country item view
@available(iOS 15.0, *)
private struct CountryItemView: View {
  let country: PrimerCountry
  let isSelected: Bool
  let onTap: () -> Void

  @Environment(\.designTokens) private var tokens

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
        // Flag
        if let flag = country.flag {
          Text(flag)
            .primerTypography(.title2, tokens: tokens)
        }

        // Country name
        Text(country.name)
          .primerTypography(.bodyLarge, tokens: tokens)
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

        Spacer()

        // Selection indicator
        if isSelected {
          Image(systemName: "checkmark")
            .foregroundColor(CheckoutColors.iconPrimary(tokens: tokens))
        }
      }
      .padding(.horizontal, PrimerSpacing.medium(tokens: tokens))
      .frame(maxWidth: .infinity, minHeight: PrimerComponentHeight.interactive, alignment: .leading)
      .background(isSelected ? CheckoutColors.backgroundSecondary(tokens: tokens) : .clear)
      .cornerRadius(PrimerRadius.small(tokens: tokens))
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .accessibilityIdentifier(AccessibilityIdentifiers.SelectCountry.countryItem(country.code))
  }
}

@available(iOS 15.0, *)
extension View {
  /// `List` paints its own background on top of the sheet colour. Only iOS 16 can turn that off;
  /// on 15 the clear row backgrounds still remove most of it.
  @ViewBuilder
  func primerClearListBackground() -> some View {
    if #available(iOS 16.0, *) {
      scrollContentBackground(.hidden)
    } else {
      self
    }
  }
}
