//
//  AppetizeConfigProvider.swift
//  Debug App
//
//  Created by Niall Quinn on 08/03/24.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import Foundation

protocol PaymentConfigProviding {}

protocol AppetizePayloadProviding {
    var isAppetize: Bool? { get }
    var configJwt: String? { get }
}

class AppetizeConfigProvider {

    private let payloadProvider: AppetizePayloadProviding

    init(payloadProvider: AppetizePayloadProviding = UserDefaults.standard) {
        self.payloadProvider = payloadProvider
    }

    func fetchConfig() -> PaymentConfiguration? {
        
        guard payloadProvider.isAppetize == true,
              let jwt = payloadProvider.configJwt,
              let config = getConfig(from: jwt) else {
            return nil
        }

        return config
    }

    private func getConfig(from jwt: String) -> PaymentConfiguration? {
        guard let data = Data(base64Encoded: jwt, options: .ignoreUnknownCharacters) else { return nil }
        return (try? JSONDecoder().decode(PaymentConfiguration.self, from: data))
    }

}

extension UserDefaults: AppetizePayloadProviding {
    private static let kIsAppetize = "isAppetize"
    private static let kJwt = "p"

    var isAppetize: Bool? {
        return bool(forKey: Self.kIsAppetize)
    }

    var configJwt: String? {
        return string(forKey: Self.kJwt)
    }
}

struct MockPayloadProvider: AppetizePayloadProviding {
    var isAppetize: Bool? = true
    var configJwt: String? = "eyJjdXN0b21lcklkIjoiIiwibG9jYWxlIjoiZW4iLCJwYXltZW50RmxvdyI6ImRlZmF1bHQiLCJwcm9jZXNzb3IiOiJicmFpbnRyZWUiLCJjdXJyZW5jeSI6IkVVUiIsImNvdW50cnlDb2RlIjoiREUiLCJ2YWx1ZSI6IjEwMCIsInByZWZlclBheUJ5Q2FyZEJ1dHRvbiI6ZmFsc2UsInRocmVlRFNFbmFibGVkIjpmYWxzZSwiY3VzdG9tZXJEZXRhaWxzRW5hYmxlZCI6ZmFsc2UsInN1cmNoYXJnZUVuYWJsZWQiOmZhbHNlLCJwYXlwYWxTdXJjaGFyZ2UiOjAsImdvb2dsZVBheVN1cmNoYXJnZSI6MCwiYXBwbGVQYXlTdXJjaGFyZ2UiOjAsInBheXBhbFBheU5sU3VyY2hhcmdlIjowLCJpZGVhbEFkeWVuU3VyY2hhcmdlIjowLCJzb2ZvcnRBZHllblN1cmNoYXJnZSI6MCwidmlzYVN1cmNoYXJnZSI6MCwibWFzdGVyY2FyZFN1cmNoYXJnZSI6MCwiZmlyc3ROYW1lIjoiSm9obiIsImxhc3ROYW1lIjoiU21pdGgiLCJlbWFpbCI6ImN1c3RvbWVyMTIzQGdtYWlsLmNvbSIsIm1vYmlsZU51bWJlciI6IjA4MjEyMzQ1NjciLCJhZGRyZXNzTGluZTEiOiIxMjMgRmFrZSBTdCIsInN0YXRlIjoiTG9uZG9uIiwiY2l0eSI6IkxvbmRvbiIsInBvc3RhbENvZGUiOiJFQzJBIDRUUCIsImNhcHR1cmUiOmZhbHNlLCJ2YXVsdCI6ZmFsc2UsIm5ld1dvcmtmbG93cyI6dHJ1ZSwiZW52aXJvbm1lbnQiOiJDVVNUT01fU1RBR0lORyIsImFwaVZlcnNpb24iOiJ2MiIsInN1Y2Nlc3NTY3JlZW5UeXBlIjoiZGVmYXVsdCIsImhpZGVDYXJkaG9sZGVyTmFtZSI6ZmFsc2UsInVzZVdvcmtmbG93c1R4bkFwaSI6ZmFsc2UsInVzZVBheW1lbnRzQXBpIjpmYWxzZSwiY3VzdG9tQXBpS2V5IjoiYzk1ZGU0YjgtYTgzMC00Yjg4LTg5OTMtNDBhZTRmYWE0YWRhIiwiZm9yY2VSZWRpcmVjdCI6ZmFsc2UsIm1ldGFkYXRhIjoic2NlbmFyaW89S0xBUk5BIn0="
}
