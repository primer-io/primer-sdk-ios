//
//  QRCodePaymentInteractorFactory.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@available(iOS 15.0, *)
struct QRCodePaymentInteractorFactory: Factory, @unchecked Sendable {
  typealias Product = ProcessQRCodePaymentInteractor
  typealias Params = String

  private let repository: QRCodeRepository

  init(repository: QRCodeRepository) {
    self.repository = repository
  }

  func create(with paymentMethodType: String) async throws -> ProcessQRCodePaymentInteractor {
    ProcessQRCodePaymentInteractorImpl(repository: repository, paymentMethodType: paymentMethodType)
  }
}
