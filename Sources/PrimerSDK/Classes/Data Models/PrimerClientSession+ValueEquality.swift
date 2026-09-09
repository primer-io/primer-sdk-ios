//
//  PrimerClientSession+ValueEquality.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Structural comparison for the client-session models.
///
/// These types are `NSObject` subclasses, so the inherited `==` is reference identity: two sessions
/// mapped from the same configuration would compare unequal. `PrimerCheckoutState` carries a session
/// and is publicly `Equatable`, so it needs value semantics here.
///
/// Deliberately not an `isEqual(_:)` override — that would change `NSSet`/dictionary behaviour for
/// shipped Drop-In and Headless integrators.
///
/// The free helpers below are named differently from the members: an unqualified call to a global
/// function is shadowed by any member sharing its base name, which is a compile error rather than an
/// overload.
extension PrimerClientSession {
    func isValueEqual(to other: PrimerClientSession) -> Bool {
        customerId == other.customerId
            && orderId == other.orderId
            && currencyCode == other.currencyCode
            && totalAmount == other.totalAmount
            && paymentMethod == other.paymentMethod
            && arraysAreEqual(lineItems, other.lineItems, by: PrimerLineItem.isValueEqual)
            && arraysAreEqual(fees, other.fees, by: PrimerFee.isValueEqual)
            && optionalsAreEqual(orderDetails, other.orderDetails, by: PrimerOrder.isValueEqual)
            && optionalsAreEqual(customer, other.customer, by: PrimerCustomer.isValueEqual)
    }
}

extension PrimerCustomer {
    static func isValueEqual(_ lhs: PrimerCustomer, _ rhs: PrimerCustomer) -> Bool {
        lhs.emailAddress == rhs.emailAddress
            && lhs.mobileNumber == rhs.mobileNumber
            && lhs.firstName == rhs.firstName
            && lhs.lastName == rhs.lastName
            && optionalsAreEqual(lhs.billingAddress, rhs.billingAddress, by: PrimerAddress.isValueEqual)
            && optionalsAreEqual(lhs.shippingAddress, rhs.shippingAddress, by: PrimerAddress.isValueEqual)
    }
}

extension PrimerAddress {
    static func isValueEqual(_ lhs: PrimerAddress, _ rhs: PrimerAddress) -> Bool {
        lhs.firstName == rhs.firstName
            && lhs.lastName == rhs.lastName
            && lhs.addressLine1 == rhs.addressLine1
            && lhs.addressLine2 == rhs.addressLine2
            && lhs.city == rhs.city
            && lhs.state == rhs.state
            && lhs.postalCode == rhs.postalCode
            && lhs.countryCode == rhs.countryCode
    }
}

extension PrimerOrder {
    static func isValueEqual(_ lhs: PrimerOrder, _ rhs: PrimerOrder) -> Bool {
        lhs.countryCode == rhs.countryCode
            && optionalsAreEqual(lhs.shipping, rhs.shipping, by: PrimerShipping.isValueEqual)
    }
}

extension PrimerShipping {
    static func isValueEqual(_ lhs: PrimerShipping, _ rhs: PrimerShipping) -> Bool {
        lhs.amount == rhs.amount
            && lhs.methodId == rhs.methodId
            && lhs.methodName == rhs.methodName
            && lhs.methodDescription == rhs.methodDescription
    }
}

extension PrimerLineItem {
    static func isValueEqual(_ lhs: PrimerLineItem, _ rhs: PrimerLineItem) -> Bool {
        lhs.itemId == rhs.itemId
            && lhs.itemDescription == rhs.itemDescription
            && lhs.amount == rhs.amount
            && lhs.discountAmount == rhs.discountAmount
            && lhs.quantity == rhs.quantity
            && lhs.taxCode == rhs.taxCode
            && lhs.taxAmount == rhs.taxAmount
    }
}

extension PrimerFee {
    static func isValueEqual(_ lhs: PrimerFee, _ rhs: PrimerFee) -> Bool {
        lhs.type == rhs.type && lhs.amount == rhs.amount
    }
}

private func optionalsAreEqual<T>(_ lhs: T?, _ rhs: T?, by compare: (T, T) -> Bool) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil): true
    case let (lhs?, rhs?): compare(lhs, rhs)
    default: false
    }
}

private func arraysAreEqual<T>(_ lhs: [T]?, _ rhs: [T]?, by compare: (T, T) -> Bool) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil): true
    case let (lhs?, rhs?): lhs.count == rhs.count && zip(lhs, rhs).allSatisfy(compare)
    default: false
    }
}
