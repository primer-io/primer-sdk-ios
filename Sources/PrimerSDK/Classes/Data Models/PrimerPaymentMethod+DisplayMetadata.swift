//
//  PrimerPaymentMethod+DisplayMetadata.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerFoundation
import PrimerNetworking

extension PrimerPaymentMethod {

    final class DisplayMetadata: Codable {

        var button: PrimerPaymentMethod.DisplayMetadata.Button

        init(button: PrimerPaymentMethod.DisplayMetadata.Button) {
            self.button = button
        }

        // swiftlint:disable:next nesting
        final class Button: Codable {

            var iconUrl: BaseColoredURLs?
            var backgroundColor: BaseColors?
            var cornerRadius: Int?
            var borderWidth: BaseBorderWidth?
            var borderColor: BaseColors?
            var text: String?
            var textColor: BaseColors?

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
                iconUrl: BaseColoredURLs?,
                backgroundColor: BaseColors?,
                cornerRadius: Int?,
                borderWidth: BaseBorderWidth?,
                borderColor: BaseColors?,
                text: String?,
                textColor: BaseColors?
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

                iconUrl = (try? container.decode(BaseColoredURLs?.self, forKey: .iconUrl)) ?? nil
                backgroundColor = (try? container.decode(BaseColors?.self, forKey: .backgroundColor)) ?? nil
                cornerRadius = (try? container.decode(Int?.self, forKey: .cornerRadius)) ?? nil
                borderWidth = (try? container.decode(BaseBorderWidth?.self, forKey: .borderWidth)) ?? nil
                borderColor = (try? container.decode(BaseColors?.self, forKey: .borderColor)) ?? nil
                text = (try? container.decode(String?.self, forKey: .text)) ?? nil
                textColor = (try? container.decode(BaseColors?.self, forKey: .textColor)) ?? nil

                if iconUrl == nil,
                   backgroundColor == nil,
                   cornerRadius == nil,
                   borderWidth == nil,
                   borderColor == nil,
                   text == nil,
                   textColor == nil {
                    throw handled(error: InternalError.failedToDecode(message: "BaseColors"))
                }
            }
        }
    }
}
