//
//  PrimerInputFieldContainer+Rendering.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
  func makeLabel(_ label: String) -> some View {
    Text(label)
      .font(labelFont)
      .foregroundColor(labelForegroundColor)
      .frame(minHeight: PrimerComponentHeight.label)
  }
}

@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
  func makeTextFieldContainer() -> some View {
    HStack(spacing: PrimerSpacing.small(tokens: tokens), content: makeTextFieldContainerContent)
      .padding(.leading, PrimerSpacing.medium(tokens: tokens))
      .padding(.trailing, PrimerSpacing.medium(tokens: tokens))
      .frame(height: PrimerSize.xxlarge(tokens: tokens))
      .background(makeTextFieldContainerBackground())
  }

  func makeTextFieldContainerContent() -> some View {
    Group {
      textFieldBuilder()
      Spacer()
      rightComponent?()
      if hasError { makeTextFieldContainerWarning() }
    }
  }

  func makeTextFieldContainerBackground() -> some View {
    RoundedRectangle(cornerRadius: fieldCornerRadius)
      .strokeBorder(borderColor, lineWidth: textFieldContainerBackgroundLineWidth)
      .background(makeTextFieldContainerBackgroundBackground())
      .animation(AnimationConstants.focusAnimation, value: isFocused)
  }

  func makeTextFieldContainerBackgroundBackground() -> some View {
    RoundedRectangle(cornerRadius: fieldCornerRadius)
      .fill(CheckoutColors.background(tokens: tokens))
  }

  func makeTextFieldContainerWarning() -> some View {
    let iconSize = PrimerSize.medium(tokens: tokens)
    return Image(systemName: "exclamationmark.triangle.fill")
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: iconSize, height: iconSize)
      .foregroundColor(CheckoutColors.iconNegative(tokens: tokens))
  }
}

@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
  func makeErrorMessage(_ errorMessage: String) -> some View {
    // No standalone .accessibility(config:) here: the container combines label + field +
    // error into one element, so the error must fold into that element rather than compete
    // as a separate node. announceError below handles the transient VoiceOver notification.
    Text(errorMessage)
      .font(errorMessageFont)
      .foregroundColor(errorMessageForegroundColor)
      .fixedSize(horizontal: false, vertical: true)
      .frame(minHeight: errorMessageMinHeight)
      .padding(.top, errorMessageTopPadding)
      .onAppear {
        // Announce error to VoiceOver when error appears
        if hasError {
          announceError(errorMessage)
        }
      }
      .onChange(of: errorMessage) { newError in
        // Announce error when it changes
        if hasError {
          announceError(newError)
        }
      }
  }

  private func announceError(_ message: String) {
    Task { @MainActor in
      if let container = DIContainer.currentSync,
        let announcementService = try? container.resolveSync(AccessibilityAnnouncementService.self) {
        announcementService.announceError(message)
      }
    }
  }
}
