//
//  PrimerPaymentMethod+DisplayMetadata.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 19/05/2024.
//

import Foundation

extension PrimerPaymentMethod {

    class DisplayMetadata: Codable {

        var button: PrimerPaymentMethod.DisplayMetadata.Button

        init(button: PrimerPaymentMethod.DisplayMetadata.Button) {
            self.button = button
        }

        // swiftlint:disable:next nesting
        class Button: Codable {

            var iconUrl: PrimerTheme.BaseColoredURLs?
            var backgroundColor: PrimerTheme.BaseColors?
            var cornerRadius: Int?
            var borderWidth: PrimerTheme.BaseBorderWidth?
            var borderColor: PrimerTheme.BaseColors?
            var text: String?
            var textColor: PrimerTheme.BaseColors?

            // swiftlint:disable:next nesting
            private enum CodingKeys: String, CodingKey {
                case iconUrl,
                     backgroundColor,
                     cornerRadius,
                     borderWidth,
                     borderColor,
                     text,
                     textColor
            }

            init(
                iconUrl: PrimerTheme.BaseColoredURLs?,
                backgroundColor: PrimerTheme.BaseColors?,
                cornerRadius: Int?,
                borderWidth: PrimerTheme.BaseBorderWidth?,
                borderColor: PrimerTheme.BaseColors?,
                text: String?,
                textColor: PrimerTheme.BaseColors?
            ) {
                self.iconUrl = iconUrl
                self.backgroundColor = backgroundColor
                self.cornerRadius = cornerRadius
                self.borderWidth = borderWidth
                self.borderColor = borderColor
                self.text = text
                self.textColor = textColor
            }

            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                iconUrl = (try? container.decode(PrimerTheme.BaseColoredURLs?.self, forKey: .iconUrl)) ?? nil
                backgroundColor = (try? container.decode(PrimerTheme.BaseColors?.self, forKey: .backgroundColor)) ?? nil
                cornerRadius = (try? container.decode(Int?.self, forKey: .cornerRadius)) ?? nil
                borderWidth = (try? container.decode(PrimerTheme.BaseBorderWidth?.self, forKey: .borderWidth)) ?? nil
                borderColor = (try? container.decode(PrimerTheme.BaseColors?.self, forKey: .borderColor)) ?? nil
                text = (try? container.decode(String?.self, forKey: .text)) ?? nil
                textColor = (try? container.decode(PrimerTheme.BaseColors?.self, forKey: .textColor)) ?? nil

                if iconUrl == nil,
                   backgroundColor == nil,
                   cornerRadius == nil,
                   borderWidth == nil,
                   borderColor == nil,
                   text == nil,
                   textColor == nil {
                    let err = InternalError.failedToDecode(message: "BaseColors", userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    throw err
                }
            }
        }
    }
}
