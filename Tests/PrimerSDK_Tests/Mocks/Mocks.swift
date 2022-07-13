//
//  PrimerSettings.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 03/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK
import XCTest

var mockClientToken = DecodedClientToken(accessToken: "bla", exp: 2000000000, configurationUrl: "https://primer.io", paymentFlow: "bla", threeDSecureInitUrl: "https://primer.io", threeDSecureToken: "bla", coreUrl: "https://primer.io", pciUrl: "https://primer.io", env: "bla", intent: "bla", statusUrl: "https://primer.io", redirectUrl: "https://primer.io", qrCode: nil)

//(
//    accessToken: "bla",
//    configurationUrl: "bla",
//    paymentFlow: "bla",
//    threeDSecureInitUrl: "bla",
//    threeDSecureToken: "bla",
//    coreUrl: "https://primer.io",
//    pciUrl: "https://primer.io",
//    env: "bla"
//)

var mockSettings = PrimerSettings(
    paymentMethodOptions: PrimerPaymentMethodOptions(
        urlScheme: "urlScheme",
        applePayOptions: PrimerApplePayOptions(merchantIdentifier: "mid", merchantName: "name")
    )
)

class MockPrimerDelegate: PrimerDelegate {
    
    var token: String?
    var authorizePaymentFails: Bool
    var clientTokenCallbackCalled = false
    var authorizePaymentCalled = false
    var primerDidDismissCalled = false

    init(token: String? = nil, authorizePaymentFails: Bool = false) {
        self.token = token
        self.authorizePaymentFails = authorizePaymentFails
    }

    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        clientTokenCallbackCalled = true
        guard let token = token else {
            completion(nil, PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil))
            return
        }
        completion(token, nil)
    }
    
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {

    }

    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
        
    }

    

    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)) }
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        authorizePaymentCalled = true
        if authorizePaymentFails { completion(PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)) }
    }

    func primerDidDismiss() {
        primerDidDismissCalled = true
    }
    
    func primerDidFailWithError(_ error: Error) {
        
    }
}

struct MockPrimerSettings: PrimerSettingsProtocol {
    var paymentHandling = PrimerPaymentHandling.auto
    var localeData = PrimerLocaleData()
    var paymentMethodOptions = PrimerPaymentMethodOptions()
    var uiOptions = PrimerUIOptions()
    var debugOptions = PrimerDebugOptions()
}

let mockPaymentMethodConfig = PrimerAPIConfiguration(
    coreUrl: "url",
    pciUrl: "url",
    clientSession: nil,
    paymentMethods: [
        PaymentMethodConfig(id: "Klarna", options: nil, processorConfigId: nil, type: .klarna),
        PaymentMethodConfig(id: "PayPal", options: nil, processorConfigId: nil, type: .payPal),
        PaymentMethodConfig(id: "Apaya", options: ApayaOptions(merchantAccountId: "merchant_account_id"), processorConfigId: nil, type: .apaya)
    ],
    keys: nil,
    checkoutModules: nil
)

class MockAppState: AppStateProtocol {
    
    static var current: AppStateProtocol {
        let appState: AppStateProtocol = DependencyContainer.resolve()
        return appState
    }

    var amount: Int? {
        return MockAppState.current.apiConfiguration?.clientSession?.order?.merchantAmount ?? AppState.current.apiConfiguration?.clientSession?.order?.totalOrderAmount
    }

    var currency: Currency? {
        return MockAppState.current.apiConfiguration?.clientSession?.order?.currencyCode
    }

    var clientToken: String?
    var apiConfiguration: PrimerAPIConfiguration?
    var paymentMethods: [PaymentMethodToken] = []
    var selectedPaymentMethodId: String?
    var selectedPaymentMethod: PaymentMethodToken?

    init(
        clientToken: String? = MockAppState.mockClientToken,
        apiConfiguration: PrimerAPIConfiguration? = PrimerAPIConfiguration(
            coreUrl: "url",
            pciUrl: "url",
            clientSession: nil,
            paymentMethods: [
                PaymentMethodConfig(id: "Klarna", options: nil, processorConfigId: nil, type: .klarna),
                PaymentMethodConfig(id: "PayPal", options: nil, processorConfigId: nil, type: .payPal),
                PaymentMethodConfig(id: "Apaya", options: ApayaOptions(merchantAccountId: "merchant_account_id"), processorConfigId: nil, type: .apaya)
            ],
            keys: nil,
            checkoutModules: nil
        )
    ) {
        self.clientToken = clientToken
        self.apiConfiguration = apiConfiguration
    }
}

extension MockAppState {
    
    static var mockClientToken: String {
        return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjIwMDAwMDAwMDAsImFjY2Vzc1Rva2VuIjoiYzJlOTM3YmMtYmUzOS00ZjVmLTkxYmYtNTIyNWExNDg0OTc1IiwiYW5hbHl0aWNzVXJsIjoiaHR0cHM6Ly9hbmFseXRpY3MuYXBpLnNhbmRib3guY29yZS5wcmltZXIuaW8vbWl4cGFuZWwiLCJhbmFseXRpY3NVcmxWMiI6Imh0dHBzOi8vYW5hbHl0aWNzLnNhbmRib3guZGF0YS5wcmltZXIuaW8vY2hlY2tvdXQvdHJhY2siLCJpbnRlbnQiOiJDSEVDS09VVCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwicGF5bWVudEZsb3ciOiJERUZBVUxUIn0.1Epm-502bLNhjhIQrmp4ZtrMQa0vQ2FjckPAlgJtuao"
    }
    
    static var mockDecodedClientToken: DecodedClientToken {
        return DecodedClientToken(accessToken: "bla", exp: 2000000000, configurationUrl: "https://primer.io", paymentFlow: "bla", threeDSecureInitUrl: "https://primer.io", threeDSecureToken: "bla", coreUrl: "https://primer.io", pciUrl: "https://primer.io", env: "bla", intent: "bla", statusUrl: "https://primer.io", redirectUrl: "https://primer.io", qrCode: nil)
    }
    
    static var mockPrimerAPIConfigurationJsonString: String {
        return """
            {
              "pciUrl" : "https://sdk.api.sandbox.primer.io",
              "paymentMethods" : [
                {
                  "id" : "136574d6-7584-4fa4-989b-3287d223238f",
                  "options" : {
                    "merchantId" : "Primer",
                    "clientId" : "Primer",
                    "merchantAccountId" : "b6902742-384a-5dfa-b1ff-7dcd02880dc3"
                  },
                  "type" : "KLARNA",
                  "processorConfigId" : "b70c2b11-e37f-41fe-9797-d3900f343a36"
                },
                {
                  "id" : "1d060d28-5ae5-48c2-8ae5-e51543c419e4",
                  "options" : {
                    "merchantId" : "91000419",
                    "merchantAccountId" : "d241274d-9144-51bc-b69e-57b7047898ea"
                  },
                  "type" : "APAYA",
                  "processorConfigId" : "3d2410f6-9592-4e24-a98e-b8782b43dfa2"
                },
                {
                  "id" : "9e407fb0-a2f8-4636-a5bc-f404ac757c68",
                  "options" : {
                    "merchantId" : "sb-iyjg88292070@business.example.com",
                    "clientId" : "AXsZfsyf2jtpTpLQARwSeBurtfT6WiRjHQt1PodMf94gPH0iLwglSdSJ7ZAQT3tCHNZQL--VlrVfwscv",
                    "merchantAccountId" : "eb3e3763-cfd6-5234-a6c7-19b5de9b0a16"
                  },
                  "type" : "PAYPAL",
                  "processorConfigId" : "573b0c98-d588-4223-973f-513a5b5a6177"
                },
                {
                  "id" : "c657ae04-c230-4be4-9615-9b822743e5e4",
                  "type" : "APPLE_PAY",
                  "options" : {
                    "certificates" : [
                      {
                        "certificateId" : "e09fc38c-f06e-4477-818c-e9e7dc81c31d",
                        "status" : "ACTIVE",
                        "validFromTimestamp" : "2021-12-06T10:14:14",
                        "expirationTimestamp" : "2024-01-05T10:14:13",
                        "merchantId" : "merchant.dx.team",
                        "createdAt" : "2021-12-06T10:24:34.659452"
                      }
                    ]
                  }
                },
                {
                  "id" : "ba022c70-8f18-447d-a214-a55f71bc35be",
                  "options" : {
                    "merchantId" : "dx@primer.io",
                    "clientId" : "dx@primer.io",
                    "merchantAccountId" : "6a126321-5306-53f5-8574-8506a095c90d"
                  },
                  "type" : "GOCARDLESS",
                  "processorConfigId" : "8df71a6c-4946-47e3-8057-7bcafb5221a4"
                },
                {
                  "type" : "PAYMENT_CARD",
                  "options" : {
                    "threeDSecureEnabled" : true,
                    "threeDSecureProvider" : "3DSECUREIO"
                  }
                }
              ],
              "clientSession" : {
                "order" : {
                  "countryCode" : "GB",
                  "orderId" : "ios_order_id_LklKo2zK",
                  "currencyCode" : "GBP",
                  "totalOrderAmount" : 1010,
                  "lineItems" : [
                    {
                      "amount" : 1010,
                      "quantity" : 1,
                      "itemId" : "shoes-382190",
                      "description" : "Fancy Shoes"
                    }
                  ]
                },
                "clientSessionId" : "09841e8a-b1fa-4528-aed1-173808a4f44d",
                "customer" : {
                  "firstName" : "John",
                  "shippingAddress" : {
                    "firstName" : "John",
                    "lastName" : "Smith",
                    "addressLine1" : "9446 Richmond Road",
                    "countryCode" : "GB",
                    "city" : "London",
                    "postalCode" : "EC53 8BT"
                  },
                  "emailAddress" : "john@primer.io",
                  "customerId" : "ios-customer-G90G37kH",
                  "mobileNumber" : "+4478888888888",
                  "billingAddress" : {
                    "firstName" : "John",
                    "lastName" : "Smith",
                    "addressLine1" : "65 York Road",
                    "countryCode" : "GB",
                    "city" : "London",
                    "postalCode" : "NW06 4OM"
                  },
                  "lastName" : "Smith"
                },
                "paymentMethod" : {
                  "options" : [
                    {
                      "type" : "PAYMENT_CARD",
                      "networks" : [
                        {
                          "type" : "VISA",
                          "surcharge" : 109
                        },
                        {
                          "type" : "MASTERCARD",
                          "surcharge" : 129
                        }
                      ]
                    },
                    {
                      "type" : "PAYPAL",
                      "surcharge" : 49
                    },
                    {
                      "type" : "PAY_NL_IDEAL",
                      "surcharge" : 39
                    },
                    {
                      "type" : "ADYEN_IDEAL",
                      "surcharge" : 69
                    },
                    {
                      "type" : "ADYEN_TWINT",
                      "surcharge" : 59
                    },
                    {
                      "type" : "BUCKAROO_BANCONTACT",
                      "surcharge" : 89
                    },
                    {
                      "type" : "ADYEN_GIROPAY",
                      "surcharge" : 79
                    },
                    {
                      "type" : "APPLE_PAY",
                      "surcharge" : 19
                    }
                  ],
                  "vaultOnSuccess" : false
                }
              },
              "primerAccountId" : "84100a01-523f-4347-ac44-e8a3e7083d9a",
              "keys" : {
                "threeDSecureIoCertificates" : [
                  {
                    "encryptionKey" : "MIIBxTCCAWugAwIBAgIIOHin61BZd20wCgYIKoZIzj0EAwIwSTELMAkGA1UEBhMCREsxFDASBgNVBAoTCzNkc2VjdXJlLmlvMSQwIgYDVQQDExszZHNlY3VyZS5pbyBzdGFuZGluIGlzc3VpbmcwHhcNMjEwNDI2MTIwNDE5WhcNMjYwNTI2MTIwNDE5WjBFMQswCQYDVQQGEwJESzEUMBIGA1UEChMLM2RzZWN1cmUuaW8xIDAeBgNVBAMTFzNkc2VjdXJlLmlvIHN0YW5kaW4gQUNTMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEczsq/UTsSeRYLFByvgbcrRiJvwZnQmostNJgl6i4/0rr9xGMD+gcqrYcbvFTEJIVHs1i557PGw2ozHQmZr/R1qNBMD8wDgYDVR0PAQH/BAQDAgOoMAwGA1UdEwEB/wQCMAAwHwYDVR0jBBgwFoAUoejawWDkUr1FVwxacK10626mkYswCgYIKoZIzj0EAwIDSAAwRQIgGvK44bXL6QD1cP322avHRjmD4T1a1el3vf2ttssXoecCIQCtlnwv5tXddJJphIgcxjG7DA8Hpp0zwqROeF3DezMvrA==",
                    "cardNetwork" : "VISA",
                    "rootCertificate" : "MIIByjCCAXCgAwIBAgIIWm3lYnRpg/kwCgYIKoZIzj0EAwIwSTELMAkGA1UEBhMCREsxFDASBgNVBAoTCzNkc2VjdXJlLmlvMSQwIgYDVQQDExszZHNlY3VyZS5pbyBzdGFuZGluIHJvb3QgQ0EwHhcNMjEwNDI2MTIwNDE5WhcNMjYwNTI2MTIwNDE5WjBJMQswCQYDVQQGEwJESzEUMBIGA1UEChMLM2RzZWN1cmUuaW8xJDAiBgNVBAMTGzNkc2VjdXJlLmlvIHN0YW5kaW4gcm9vdCBDQTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABDiki3Z74HsR4G5ejqwk31STA0JZyWdBbzfkpLhxlNepJmzW/lKvgpJ5w1abWymNv+kQ1evdoCZ3xPrWDH3Ov+ajQjBAMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBS1xdoF1e7Ej4pQiLB/n1TSw00iITAKBggqhkjOPQQDAgNIADBFAiAxeIZD+gfFVsQnbbOH7l04v8euq0N82gG8umBaFl+AVwIhAIVDiG4nLkL187clHn5Mw2AALHh1xSSfSBGbdUmuCd7b"
                  }
                ],
                "netceteraLicenseKey" : "eyJhbGciOiJSUzI1NiJ9.eyJ2ZXJzaW9uIjoyLCJ2YWxpZC11bnRpbCI6IjIwMjItMTItMDkiLCJuYW1lIjoiUHJpbWVyYXBpIiwibW9kdWxlIjoiM0RTIn0.T_EP89dFkXvLhOiW0kfX--_GoDwtxTuSxl7dku6-if0hjQb8zIupOMY56TDnsFO96T3-YB34RRLQJ4daxwAuLYaprKN39lDgLpGPvFAYcSk8PPNAOxaIM_xNFuzHYAiRmEEPONuxWq6kse1AgjTJaBbZN80qmOTlKHFZ1BmVVT3M-cyvhdh-5gvlEsNYFD3ufRF6Y79MpySwqr2p94BcXRk2GMgkKYwA6jnw6B6iYOnFj4SuQqjzFneJHlvmF7zwvm-mDvJ82ZoPWzM0uS5YouovzZIdJMqZrZThiSdQYvFh4nIQBBFxE02FvGWJ7Ae9Oq0YrQoLGZrV1l17TW3AZw"
              },
              "env" : "SANDBOX",
              "checkoutModules" : [
                {
                  "type" : "TAX_CALCULATION",
                  "requestUrl" : "/sales-tax/calculate"
                },
                {
                  "type" : "BILLING_ADDRESS",
                  "options" : {
                    "lastName" : true,
                    "city" : true,
                    "firstName" : true,
                    "postalCode" : true,
                    "addressLine1" : true,
                    "countryCode" : true,
                    "addressLine2" : true,
                    "state" : true,
                    "phoneNumber" : false
                  }
                }
              ],
              "coreUrl" : "https://api.sandbox.primer.io"
            }
        """
    }
}

let mockPayPalBillingAgreement = PayPalConfirmBillingAgreementResponse(billingAgreementId: "agreementId", externalPayerInfo: ExternalPayerInfo(externalPayerId: "", email: "", firstName: "", lastName: ""), shippingAddress: ShippingAddress(firstName: "", lastName: "", addressLine1: "", addressLine2: "", city: "", state: "", countryCode: "", postalCode: ""))

class MockLocator {
    static func registerDependencies() {
        let state: AppStateProtocol = MockAppState()
        state.apiConfiguration = mockPaymentMethodConfig
        DependencyContainer.register(state as AppStateProtocol)
        // register dependencies
        DependencyContainer.register(mockSettings as PrimerSettingsProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        DependencyContainer.register(MockPrimerAPIClient() as PrimerAPIClientProtocol)
        DependencyContainer.register(MockVaultService() as VaultServiceProtocol)
        DependencyContainer.register(MockClientTokenService() as ClientTokenServiceProtocol)
        DependencyContainer.register(MockPaymentMethodConfigService() as PaymentMethodConfigServiceProtocol)
        DependencyContainer.register(MockPayPalService() as PayPalServiceProtocol)
        DependencyContainer.register(MockTokenizationService(paymentInstrumentType: PrimerPaymentMethodType.paymentCard.rawValue, tokenType: TokenType.singleUse.rawValue) as TokenizationServiceProtocol)
        DependencyContainer.register(MockVaultPaymentMethodViewModel() as VaultPaymentMethodViewModelProtocol)
        DependencyContainer.register(MockVaultCheckoutViewModel() as VaultCheckoutViewModelProtocol)
        DependencyContainer.register(MockExternalViewModel() as ExternalViewModelProtocol)
        DependencyContainer.register(PrimerTheme() as PrimerThemeProtocol)
        DependencyContainer.register(MockCreateResumePaymentService() as CreateResumePaymentServiceProtocol)
    }
}

#endif
