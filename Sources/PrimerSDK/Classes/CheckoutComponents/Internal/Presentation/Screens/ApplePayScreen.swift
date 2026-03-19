//
//  ApplePayScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
import SwiftUI

@available(iOS 15.0, *)
struct ApplePayScreen: View {
  @ObservedObject private var scope: DefaultApplePayScope
  private let presentationContext: PresentationContext

  init(
    scope: DefaultApplePayScope, presentationContext: PresentationContext = .fromPaymentSelection
  ) {
    self.scope = scope
    self.presentationContext = presentationContext
  }

  var body: some View {
    VStack(spacing: 0) {
      makeNavigationBar()
      makeContent()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(Color(.systemBackground))
  }

  private func makeNavigationBar() -> some View {
    HStack {
      if presentationContext.shouldShowBackButton {
        Button(action: scope.onBack) {
          Image(systemName: RTLIcon.backChevron)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.primary)
        }
        .padding(.leading, 16)
      }

      Spacer()

      Text("Apple Pay")
        .font(.headline)

      Spacer()

      Button(action: scope.onDismiss) {
        Image(systemName: "xmark")
          .font(.system(size: 17, weight: .medium))
          .foregroundColor(.secondary)
      }
      .padding(.trailing, 16)
    }
    .frame(height: 56)
    .background(Color(.systemBackground))
  }

  @ViewBuilder
  private func makeContent() -> some View {
    if scope.structuredState.isAvailable {
      makeAvailableContent()
    } else {
      makeUnavailableContent()
    }
  }

  private func makeAvailableContent() -> some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "apple.logo")
        .font(.system(size: 60))
        .foregroundColor(.primary)

      Text("Pay securely with Apple Pay")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      Spacer()

      if scope.structuredState.isLoading {
        makeLoadingView()
      } else {
        makeApplePayButton()
      }

      Spacer()
        .frame(height: 32)
    }
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  private func makeApplePayButton() -> some View {
    if let customButton = scope.applePayButton {
      AnyView(customButton(scope.submit))
        .frame(height: 50)
        .padding(.horizontal, 16)
    } else {
      scope.PrimerApplePayButton(action: scope.submit)
        .frame(height: 50)
        .padding(.horizontal, 16)
    }
  }

  private func makeLoadingView() -> some View {
    HStack(spacing: 12) {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle())

      Text("Processing...")
        .font(.body)
        .foregroundColor(.secondary)
    }
    .frame(height: 50)
  }

  private func makeUnavailableContent() -> some View {
    VStack(spacing: 16) {
      Spacer()

      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundColor(.orange)

      Text("Apple Pay Unavailable")
        .font(.headline)

      if let error = scope.structuredState.availabilityError {
        Text(error)
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 32)
      }

      Spacer()

      if presentationContext.shouldShowBackButton {
        Button(action: scope.onBack) {
          Text("Choose Another Payment Method")
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.accentColor)
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
      }

      Spacer()
        .frame(height: 32)
    }
  }
}

#if DEBUG
  @available(iOS 15.0, *)
  struct ApplePayScreen_Previews: PreviewProvider {
    static var previews: some View {
      Text("Apple Pay Screen Preview")
    }
  }
#endif
