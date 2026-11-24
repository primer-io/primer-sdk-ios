//
//  BackendDrivenScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCUI
@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

@available(iOS 16.0, *)
struct BackendDrivenScreen: View {
  @ObservedObject var scope: DefaultBackendDrivenScope

  @Environment(\.designTokens) private var tokens

  var body: some View {
    SDUIView(
      onEvent: { [weak scope] in try await scope?.applyEvent($0) },
      onClose: { [weak scope] in scope?.cancel() },
      titleImage: scope.logo
    )
    .environment(\.sduiTokens, SDUITokens(tokens ?? DesignTokens()))
    .overlay { if scope.internalState == .paying { DefaultLoadingScreen() } }
    .task { scope.screenDidAppear() }
  }
}
