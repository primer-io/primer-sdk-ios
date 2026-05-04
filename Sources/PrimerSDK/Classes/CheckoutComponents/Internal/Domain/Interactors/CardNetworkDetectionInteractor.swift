//
//  CardNetworkDetectionInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol CardNetworkDetectionInteractor {
  var networkDetectionStream: AsyncStream<[CardNetwork]> { get }
  var binDataStream: AsyncStream<PrimerBinData> { get }
  func detectNetworks(for cardNumber: String) async
  func selectNetwork(_ network: CardNetwork) async
}

@available(iOS 15.0, *)
final class CardNetworkDetectionInteractorImpl: CardNetworkDetectionInteractor, LogReporter {

  private let repository: HeadlessRepository

  var networkDetectionStream: AsyncStream<[CardNetwork]> {
    repository.getNetworkDetectionStream()
  }

  var binDataStream: AsyncStream<PrimerBinData> {
    repository.getBinDataStream()
  }

  init(repository: HeadlessRepository) {
    self.repository = repository
  }

  func detectNetworks(for cardNumber: String) async {
    await repository.updateCardNumberInRawDataManager(cardNumber)
  }

  func selectNetwork(_ network: CardNetwork) async {
    await repository.selectCardNetwork(network)
  }
}
