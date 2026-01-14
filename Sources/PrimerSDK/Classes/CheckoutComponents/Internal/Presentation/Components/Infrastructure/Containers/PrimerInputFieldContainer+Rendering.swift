//
//  PrimerInputFieldContainer+Rendering.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Label
@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
    func makeLabel(_ label: String) -> some View {
        Text(label)
            .font(labelFont)
            .foregroundColor(labelForegroundColor)
            .frame(minHeight: PrimerComponentHeight.label)
    }
}

// MARK: - TextField Container
@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
    func makeTextFieldContainer() -> some View {
        HStack(spacing: PrimerSpacing.small(tokens: tokens), content: makeTextFieldContainerContent)
            .padding(.leading, styling?.padding?.leading ?? PrimerSpacing.medium(tokens: tokens))
            .padding(.trailing, styling?.padding?.trailing ?? PrimerSpacing.medium(tokens: tokens))
            .frame(height: styling?.fieldHeight ?? PrimerSize.xxlarge(tokens: tokens))
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
            .fill(styling?.backgroundColor ?? CheckoutColors.background(tokens: tokens))
    }

    func makeTextFieldContainerWarning() -> some View {
        let iconSize = PrimerSize.medium(tokens: tokens)
        return Image(systemName: "exclamationmark.triangle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
            .foregroundColor(CheckoutColors.iconNegative(tokens: tokens))
            .offset(x: hasError ? 0 : -10)
            .opacity(hasError ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasError)
    }
}

// MARK: - Error
@available(iOS 15.0, *)
extension PrimerInputFieldContainer {
    func makeErrorMessage(_ errorMessage: String) -> some View {
        Text(errorMessage)
            .font(errorMessageFont)
            .foregroundColor(errorMessageForegroundColor)
            .frame(height: errorMessageHeight)
            .offset(y: hasError ? 0 : -10)
            .opacity(hasError ? 1.0 : 0.0)
            .padding(.top, errorMessageTopPadding)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasError)
            .accessibility(config: AccessibilityConfiguration(
                identifier: AccessibilityIdentifiers.Error.messageContainer,
                label: errorMessage,
                traits: [.isStaticText]
            ))
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
