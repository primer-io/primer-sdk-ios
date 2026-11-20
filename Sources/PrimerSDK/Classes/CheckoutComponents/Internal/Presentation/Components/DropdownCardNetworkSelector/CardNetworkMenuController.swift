//
//  CardNetworkMenuController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
final class CardNetworkMenuController: UIViewController {
  private let menu: UIHostingController<CardNetworkMenu>
  private let menuSize: CGSize
  private let layout: CardNetworkMenuLayout
  private weak var fieldView: UIView?
  private var window: UIWindow?

  init(menu: CardNetworkMenu, fieldView: UIView) {
    self.menu = UIHostingController(rootView: menu)
    menuSize = self.menu.sizeThatFits(in: UIView.layoutFittingExpandedSize)
    layout = CardNetworkMenuLayout(
      gap: PrimerSpacing.xsmall(tokens: menu.tokens),
      edgeInset: PrimerSpacing.large(tokens: menu.tokens),
      isRightToLeft: menu.layoutDirection == .rightToLeft
    )
    self.fieldView = fieldView
    super.init(nibName: nil, bundle: nil)
    overrideUserInterfaceStyle = fieldView.traitCollection.userInterfaceStyle
  }

  required init?(coder _: NSCoder) { nil }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    view.accessibilityViewIsModal = true
    let backdrop = UIView(frame: view.bounds)
    backdrop.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    backdrop.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
    view.addSubview(backdrop)
    menu.view.backgroundColor = .clear
    addChild(menu)
    view.addSubview(menu.view)
    menu.didMove(toParent: self)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard let fieldView else { return }
    menu.view.frame = layout.frame(
      below: view.convert(fieldView.bounds, from: fieldView as UICoordinateSpace),
      size: menuSize,
      in: view.bounds
    )
  }

  override func accessibilityPerformEscape() -> Bool {
    close()
    return true
  }

  func show() {
    guard let hostWindow = fieldView?.window, let scene = hostWindow.windowScene else { return }
    let window = UIWindow(windowScene: scene)
    window.windowLevel = UIWindow.Level(hostWindow.windowLevel.rawValue + 1)
    window.rootViewController = self
    window.alpha = 0
    window.isHidden = false
    self.window = window
    UIView.animate(withDuration: AnimationConstants.standardDuration) { window.alpha = 1 }
    UIAccessibility.post(notification: .screenChanged, argument: menu.view)
  }

  @objc func close() {
    guard let window else { return }
    self.window = nil
    UIView.animate(withDuration: AnimationConstants.standardDuration) {
      window.alpha = 0
    } completion: { _ in
      window.isHidden = true
    }
  }
}
