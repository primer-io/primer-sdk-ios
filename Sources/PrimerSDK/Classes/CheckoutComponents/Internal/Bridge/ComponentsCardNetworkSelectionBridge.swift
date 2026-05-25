//
//  ComponentsCardNetworkSelectionBridge.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
@_spi(PrimerInternal)
public final class ComponentsCardNetworkSelectionBridge: LogReporter {

  public struct NetworkDescriptor: Sendable {
    public let identifier: String
    public let displayName: String
    public let allowed: Bool
    public let allowsUserSelection: Bool
  }

  public struct State: Sendable {
    public let availableNetworks: [NetworkDescriptor]
    public let selectedIdentifier: String?
    public let isNetworkSelectable: Bool

    public static let empty = State(
      availableNetworks: [],
      selectedIdentifier: nil,
      isNetworkSelectable: false
    )
  }

  private let interactorResolver: () async -> CardNetworkDetectionInteractor?
  private let allowedNetworksProvider: () -> [String]?

  public init() {
    interactorResolver = {
      guard let container = await DIContainer.current else { return nil }
      return try? await container.resolve(CardNetworkDetectionInteractor.self)
    }
    allowedNetworksProvider = {
      PrimerAPIConfigurationModule.apiConfiguration?
        .clientSession?.paymentMethod?.orderedAllowedCardNetworks
    }
  }

  init(
    interactorResolver: @escaping () async -> CardNetworkDetectionInteractor?,
    allowedNetworksProvider: @escaping () -> [String]?
  ) {
    self.interactorResolver = interactorResolver
    self.allowedNetworksProvider = allowedNetworksProvider
  }

  public func setSelectedNetwork(_ network: CardNetwork) async throws {
    logger.debug(message: "[CardNetworkSelectionBridge] setSelectedNetwork(network=\(network.rawValue))")

    Analytics.Service.fire(event: Analytics.Event.sdk(
      name: "\(Self.self).\(#function)",
      params: ["category": "CARD_NETWORK_SELECTION"]
    ))

    guard let interactor = await interactorResolver() else {
      logger.error(message: "[CardNetworkSelectionBridge] no CardNetworkDetectionInteractor registered in DI")
      throw PrimerError.unknown(message: "No active CardNetworkDetectionInteractor")
    }
    logger.debug(message: "[CardNetworkSelectionBridge] -> interactor.selectNetwork(\(network.rawValue))")
    await interactor.selectNetwork(network)
    logger.info(message: "[CardNetworkSelectionBridge] selectNetwork(\(network.rawValue)) completed")
  }

  public var state: AsyncStream<State> {
    AsyncStream { continuation in
      let task = Task { [self] in
        guard let interactor = await interactorResolver() else {
          logger.debug(message: "[CardNetworkSelectionBridge] state stream: no interactor, yielding .empty")
          continuation.yield(.empty)
          continuation.finish()
          return
        }
        logger.debug(message: "[CardNetworkSelectionBridge] state stream started")
        let aggregator = StateAggregator()

        async let detection: Void = {
          for await networks in interactor.networkDetectionStream {
            logger.debug(message: "[CardNetworkSelectionBridge] detection tick: \(networks.map(\.rawValue))")
            let snapshot = await aggregator.applyDetection(networks, allowed: allowedNetworksProvider())
            logger.debug(message: Self.formatYield(label: "detection", snapshot: snapshot))
            continuation.yield(snapshot)
          }
        }()

        async let binData: Void = {
          for await bin in interactor.binDataStream {
            let preferredId = bin.preferred?.network.rawValue ?? "nil"
            logger.debug(message: "[CardNetworkSelectionBridge] binData tick: preferred=\(preferredId)")
            let snapshot = await aggregator.applyBinData(bin)
            logger.debug(message: Self.formatYield(label: "binData", snapshot: snapshot))
            continuation.yield(snapshot)
          }
        }()

        _ = await (detection, binData)
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  private static func formatYield(label: String, snapshot: State) -> String {
    let available = snapshot.availableNetworks.map(\.identifier)
    let selected = snapshot.selectedIdentifier ?? "nil"
    return "[CardNetworkSelectionBridge] yield(\(label)): available=\(available) selected=\(selected) selectable=\(snapshot.isNetworkSelectable)"
  }

  static func makeDescriptor(for network: CardNetwork, allowed: Set<String>) -> NetworkDescriptor? {
    guard network != .unknown else { return nil }
    let identifier = network.rawValue
    let isAllowed = allowed.isEmpty || allowed.contains(identifier)
    return NetworkDescriptor(
      identifier: identifier,
      displayName: network.displayName,
      allowed: isAllowed,
      allowsUserSelection: network != .eftpos
    )
  }
}

@available(iOS 15.0, *)
private actor StateAggregator {
  private var availableNetworks: [ComponentsCardNetworkSelectionBridge.NetworkDescriptor] = []
  private var selectedIdentifier: String?
  private var isNetworkSelectable = false

  func applyDetection(
    _ networks: [CardNetwork],
    allowed: [String]?
  ) -> ComponentsCardNetworkSelectionBridge.State {
    let allowedSet = Set(allowed ?? [])
    let descriptors = networks
      .compactMap { ComponentsCardNetworkSelectionBridge.makeDescriptor(for: $0, allowed: allowedSet) }
      .filter(\.allowed)
    availableNetworks = descriptors
    isNetworkSelectable = !descriptors.isEmpty && descriptors.allSatisfy(\.allowsUserSelection)
    if let selectedIdentifier, !descriptors.contains(where: { $0.identifier == selectedIdentifier }) {
      self.selectedIdentifier = nil
    }
    return snapshot()
  }

  func applyBinData(_ bin: PrimerBinData) -> ComponentsCardNetworkSelectionBridge.State {
    selectedIdentifier = bin.preferred?.network.rawValue
    return snapshot()
  }

  private func snapshot() -> ComponentsCardNetworkSelectionBridge.State {
    ComponentsCardNetworkSelectionBridge.State(
      availableNetworks: availableNetworks,
      selectedIdentifier: selectedIdentifier,
      isNetworkSelectable: isNetworkSelectable
    )
  }
}
