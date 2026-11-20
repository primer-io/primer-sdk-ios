//
//  SurchargeGroup.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@available(iOS 15.0, *)
struct SurchargeGroup: Equatable {
  enum Title: Hashable {
    case fee(Int)
    case noFee
    case mayApply
  }

  let title: Title?
  let methods: [CheckoutPaymentMethod]

  static func groups(of methods: [CheckoutPaymentMethod]) -> [SurchargeGroup] {
    let titles = methods.map(Title.init)
    guard titles.contains(where: { $0 != .noFee }) else { return [SurchargeGroup(title: nil, methods: methods)] }
    let feeTitles = titles.reduce(into: [Title]()) { feeTitles, title in
      if case .fee = title, !feeTitles.contains(title) { feeTitles.append(title) }
    }
    return (feeTitles + [.noFee, .mayApply]).compactMap { title in
      let members = zip(methods, titles).filter { $0.1 == title }.map(\.0)
      return members.isEmpty ? nil : SurchargeGroup(title: title, methods: members)
    }
  }
}

@available(iOS 15.0, *)
private extension SurchargeGroup.Title {
  init(_ method: CheckoutPaymentMethod) {
    self = if method.hasUnknownSurcharge {
      .mayApply
    } else if let fee = method.surcharge, fee > 0 {
      .fee(fee)
    } else {
      .noFee
    }
  }
}
