//
//  PrimerAchScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

@available(iOS 15.0, *)
public typealias AchScreenComponent = (any PrimerAchScope) -> any View

@available(iOS 15.0, *)
public typealias AchButtonComponent = (any PrimerAchScope) -> any View

@available(iOS 15.0, *)
@MainActor
public protocol PrimerAchScope: PrimerPaymentMethodScope where State == AchState {

  var state: AsyncStream<AchState> { get }

  var presentationContext: PresentationContext { get }

  var dismissalMechanism: [DismissalMechanism] { get }

  var bankCollectorViewController: UIViewController? { get }

  // MARK: - User Details Actions

  func updateFirstName(_ value: String)

  func updateLastName(_ value: String)

  func updateEmailAddress(_ value: String)

  func submitUserDetails()

  // MARK: - Mandate Actions

  func acceptMandate()

  func declineMandate()

  // MARK: - Navigation Methods

  func onBack()

  func onCancel()

  // MARK: - Screen-Level Customization

  var screen: AchScreenComponent? { get set }

  var userDetailsScreen: AchScreenComponent? { get set }

  var mandateScreen: AchScreenComponent? { get set }

  var submitButton: AchButtonComponent? { get set }
}
