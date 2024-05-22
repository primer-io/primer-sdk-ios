//
//  PrimerTheme+Images.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 19/05/2024.
//

import UIKit

extension PrimerTheme {

    class BaseImage {

        var colored: UIImage?
        var light: UIImage?
        var dark: UIImage?

        init?(colored: UIImage?, light: UIImage?, dark: UIImage?) {
            self.colored = colored
            self.light = light
            self.dark = dark

            if self.colored == nil, self.light == nil, self.dark == nil {
                return nil
            }
        }
    }

    public class BaseColoredURLs: Codable {

        var coloredUrlStr: String?
        var darkUrlStr: String?
        var lightUrlStr: String?

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case coloredUrlStr = "colored"
            case darkUrlStr = "dark"
            case lightUrlStr = "light"
        }

        init?(
            coloredUrlStr: String?,
            lightUrlStr: String?,
            darkUrlStr: String?
        ) {
            self.coloredUrlStr = coloredUrlStr
            self.lightUrlStr = lightUrlStr
            self.darkUrlStr = darkUrlStr
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            coloredUrlStr = (try? container.decode(String?.self, forKey: .coloredUrlStr)) ?? nil
            lightUrlStr = (try? container.decode(String?.self, forKey: .lightUrlStr)) ?? nil
            darkUrlStr = (try? container.decode(String?.self, forKey: .darkUrlStr)) ?? nil

            if coloredUrlStr == nil && lightUrlStr == nil && darkUrlStr == nil {
                let err = InternalError.failedToDecode(message: "BaseColoredURLs", userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(coloredUrlStr, forKey: .coloredUrlStr)
            try? container.encode(lightUrlStr, forKey: .lightUrlStr)
            try? container.encode(darkUrlStr, forKey: .darkUrlStr)
        }
    }

    public class BaseColors: Codable {

        var coloredHex: String?
        var darkHex: String?
        var lightHex: String?

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case coloredHex = "colored"
            case darkHex = "dark"
            case lightHex = "light"
        }

        init?(
            coloredHex: String?,
            lightHex: String?,
            darkHex: String?
        ) {
            self.coloredHex = coloredHex
            self.lightHex = lightHex
            self.darkHex = darkHex
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            coloredHex = (try? container.decode(String?.self, forKey: .coloredHex)) ?? nil
            darkHex = (try? container.decode(String?.self, forKey: .darkHex)) ?? nil
            lightHex = (try? container.decode(String?.self, forKey: .lightHex)) ?? nil

            if coloredHex == nil && lightHex == nil && darkHex == nil {
                let err = InternalError.failedToDecode(message: "BaseColors", userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(coloredHex, forKey: .coloredHex)
            try? container.encode(darkHex, forKey: .darkHex)
            try? container.encode(lightHex, forKey: .lightHex)
        }
    }

    public class BaseBorderWidth: Codable {

        var colored: CGFloat?
        var dark: CGFloat?
        var light: CGFloat?

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case colored
            case dark
            case light
        }

        init?(
            colored: CGFloat? = 0,
            light: CGFloat? = 0,
            dark: CGFloat? = 0
        ) {
            self.colored = colored
            self.light = light
            self.dark = dark
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            colored = (try? container.decode(CGFloat?.self, forKey: .colored)) ?? nil
            light = (try? container.decode(CGFloat?.self, forKey: .light)) ?? nil
            dark = (try? container.decode(CGFloat?.self, forKey: .dark)) ?? nil
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(colored, forKey: .colored)
            try? container.encode(light, forKey: .light)
            try? container.encode(dark, forKey: .dark)
        }
    }
}
