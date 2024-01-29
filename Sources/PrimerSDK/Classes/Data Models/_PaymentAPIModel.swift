//
//  PaymentAPIModel.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 28/02/22.
//

import Foundation

// MARK: -

extension PrimerClientSession {

    internal convenience init(from apiConfiguration: PrimerAPIConfiguration) {
        let lineItems = apiConfiguration.clientSession?.order?.lineItems?.compactMap { PrimerLineItem(itemId: $0.itemId,
                                                                                                      itemDescription: $0.description,
                                                                                                      amount: $0.amount,
                                                                                                      discountAmount: $0.discountAmount,
                                                                                                      quantity: $0.quantity,
                                                                                                      taxCode: apiConfiguration.clientSession?.customer?.taxId,
                                                                                                      taxAmount: apiConfiguration.clientSession?.order?.totalTaxAmount) }

        let orderDetails = PrimerOrder(countryCode: apiConfiguration.clientSession?.order?.countryCode?.rawValue)

        let billingAddress = PrimerAddress(firstName: apiConfiguration.clientSession?.customer?.billingAddress?.firstName,
                                           lastName: apiConfiguration.clientSession?.customer?.billingAddress?.lastName,
                                           addressLine1: apiConfiguration.clientSession?.customer?.billingAddress?.addressLine1,
                                           addressLine2: apiConfiguration.clientSession?.customer?.billingAddress?.addressLine2,
                                           postalCode: apiConfiguration.clientSession?.customer?.billingAddress?.postalCode, city: apiConfiguration.clientSession?.customer?.billingAddress?.city,
                                           state: apiConfiguration.clientSession?.customer?.billingAddress?.state,
                                           countryCode: apiConfiguration.clientSession?.customer?.billingAddress?.countryCode?.rawValue)

        let shippingAddress = PrimerAddress(firstName: apiConfiguration.clientSession?.customer?.shippingAddress?.firstName,
                                            lastName: apiConfiguration.clientSession?.customer?.shippingAddress?.lastName,
                                            addressLine1: apiConfiguration.clientSession?.customer?.shippingAddress?.addressLine1,
                                            addressLine2: apiConfiguration.clientSession?.customer?.shippingAddress?.addressLine2,
                                            postalCode: apiConfiguration.clientSession?.customer?.shippingAddress?.postalCode, city: apiConfiguration.clientSession?.customer?.shippingAddress?.city,
                                            state: apiConfiguration.clientSession?.customer?.shippingAddress?.state,
                                            countryCode: apiConfiguration.clientSession?.customer?.shippingAddress?.countryCode?.rawValue)

        let customer = PrimerCustomer(emailAddress: apiConfiguration.clientSession?.customer?.emailAddress,
                                      mobileNumber: apiConfiguration.clientSession?.customer?.mobileNumber,
                                      firstName: apiConfiguration.clientSession?.customer?.firstName,
                                      lastName: apiConfiguration.clientSession?.customer?.lastName,
                                      billingAddress: billingAddress,
                                      shippingAddress: shippingAddress)

        self.init(customerId: apiConfiguration.clientSession?.customer?.id,
                  orderId: apiConfiguration.clientSession?.order?.id,
                  currencyCode: apiConfiguration.clientSession?.order?.currencyCode?.rawValue,
                  totalAmount: apiConfiguration.clientSession?.order?.totalOrderAmount,
                  lineItems: lineItems,
                  orderDetails: orderDetails,
                  customer: customer)
    }
}
