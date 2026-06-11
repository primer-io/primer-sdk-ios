//
//  SDKContext.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public struct SDKContext: Encodable {
    let sdk: SDK
    let device: SDKDevice
    let app: SDKApp
    let session: SDKSession
    let payment: SDKPayment
    let merchant: SDKMerchant
    let analytics: SDKAnalytics
    
    public init(
        sdk: SDK,
        device: SDKDevice,
        app: SDKApp,
        session: SDKSession,
        payment: SDKPayment,
        merchant: SDKMerchant,
        analytics: SDKAnalytics
    ) {
        self.sdk = sdk
        self.device = device
        self.app = app
        self.session = session
        self.payment = payment
        self.merchant = merchant
        self.analytics = analytics
    }
}

@_spi(PrimerInternal)
public struct SDK: Encodable {
    let type: String
    let version: String
    let integrationType: String
    let paymentHandling: String
    
    public init(type: String, version: String, integrationType: String, paymentHandling: String) {
        self.type = type
        self.version = version
        self.integrationType = integrationType
        self.paymentHandling = paymentHandling
    }
}

@_spi(PrimerInternal)
public struct SDKDevice: Encodable {
    let type: String?
    let make: String
    let model: String
    let modelIdentifier: String?
    let platformVersion: String
    let uniqueDeviceIdentifier: String
    let locale: String?
    
    public init(
        type: String?,
        make: String,
        model: String,
        modelIdentifier: String?,
        platformVersion: String,
        uniqueDeviceIdentifier: String,
        locale: String?
    ) {
        self.type = type
        self.make = make
        self.model = model
        self.modelIdentifier = modelIdentifier
        self.platformVersion = platformVersion
        self.uniqueDeviceIdentifier = uniqueDeviceIdentifier
        self.locale = locale
    }
}

@_spi(PrimerInternal)
public struct SDKApp: Encodable {
    let identifier: String
    
    public init(identifier: String) {
        self.identifier = identifier
    }
}

@_spi(PrimerInternal)
public struct SDKSession: Encodable {
    let checkoutSessionId: String?
    let clientSessionId: String?
    let customerId: String?
    
    public init(
        checkoutSessionId: String?,
        clientSessionId: String?,
        customerId: String?
    ) {
        self.checkoutSessionId = checkoutSessionId
        self.clientSessionId = clientSessionId
        self.customerId = customerId
    }
}

@_spi(PrimerInternal)
public struct SDKPayment: Encodable {
    let paymentMethodType: String
    
    public init(paymentMethodType: String) {
        self.paymentMethodType = paymentMethodType
    }
}

@_spi(PrimerInternal)
public struct SDKMerchant: Encodable {
    let primerAccountId: String?
    
    public init(primerAccountId: String?) {
        self.primerAccountId = primerAccountId
    }
}

@_spi(PrimerInternal)
public struct SDKAnalytics: Encodable {
    let url: String?
    
    public init(url: String?) {
        self.url = url
    }
}
