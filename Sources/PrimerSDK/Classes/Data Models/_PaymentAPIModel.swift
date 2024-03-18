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
        let lineItems = apiConfiguration.clientSession?.order?.lineItems?
            .compactMap { PrimerLineItem(itemId: $0.itemId,
                                         itemDescription: $0.description,
                                         amount: $0.amount,
                                         discountAmount: $0.discountAmount,
                                         quantity: $0.quantity,
                                         taxCode: apiConfiguration.clientSession?.customer?.taxId,
                                         taxAmount: apiConfiguration.clientSession?.order?.totalTaxAmount) }

        let orderDetails = PrimerOrder(countryCode: apiConfiguration.clientSession?.order?.countryCode?.rawValue)

        let billing = apiConfiguration.clientSession?.customer?.billingAddress
        let shipping = apiConfiguration.clientSession?.customer?.shippingAddress

        let billingAddress = PrimerAddress(firstName: billing?.firstName,
                                           lastName: billing?.lastName,
                                           addressLine1: billing?.addressLine1,
                                           addressLine2: billing?.addressLine2,
                                           postalCode: billing?.postalCode,
                                           city: billing?.city,
                                           state: billing?.state,
                                           countryCode: billing?.countryCode?.rawValue)

        let shippingAddress = PrimerAddress(firstName: shipping?.firstName,
                                            lastName: shipping?.lastName,
                                            addressLine1: shipping?.addressLine1,
                                            addressLine2: shipping?.addressLine2,
                                            postalCode: shipping?.postalCode,
                                            city: shipping?.city,
                                            state: shipping?.state,
                                            countryCode: shipping?.countryCode?.rawValue)

        let customer = PrimerCustomer(emailAddress: apiConfiguration.clientSession?.customer?.emailAddress,
                                      mobileNumber: apiConfiguration.clientSession?.customer?.mobileNumber,
                                      firstName: apiConfiguration.clientSession?.customer?.firstName,
                                      lastName: apiConfiguration.clientSession?.customer?.lastName,
                                      billingAddress: billingAddress,
                                      shippingAddress: shippingAddress)

        self.init(customerId: apiConfiguration.clientSession?.customer?.id,
                  orderId: apiConfiguration.clientSession?.order?.id,
                  currencyCode: apiConfiguration.clientSession?.order?.currencyCode?.code,
                  totalAmount: apiConfiguration.clientSession?.order?.totalOrderAmount,
                  lineItems: lineItems,
                  orderDetails: orderDetails,
                  customer: customer)
    }
}
