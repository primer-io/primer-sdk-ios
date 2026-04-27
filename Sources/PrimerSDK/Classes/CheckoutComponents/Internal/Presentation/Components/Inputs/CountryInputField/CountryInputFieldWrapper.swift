//
//  CountryInputFieldWrapper.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct CountryInputFieldWrapper: View, LogReporter {
  let scope: any CardFormFieldScopeInternal

  let label: String?
  let placeholder: String
  let styling: PrimerFieldStyling?

  var body: some View {
    CountryInputField(
      label: label,
      placeholder: placeholder,
      scope: scope,
      styling: styling
    )
  }
}
