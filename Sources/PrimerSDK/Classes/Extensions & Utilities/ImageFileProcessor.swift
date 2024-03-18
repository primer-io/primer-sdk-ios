//
//  ImageFileProcessor.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 01/03/2024.
//

import Foundation

// swiftlint:disable cyclomatic_complexity
class ImageFileProcessor {

    init() {}

    func process(configuration apiConfiguration: PrimerAPIConfiguration) -> Promise<Void> {
        var imageFiles: [ImageFile] = []

        for paymentMethod in (apiConfiguration.paymentMethods ?? []) {

            var coloredImageFile: ImageFile
            if let coloredVal = paymentMethod.displayMetadata?.button.iconUrl?.coloredUrlStr {
                var remoteUrl: URL?
                var base64Data: Data?

                if let data = Data(base64Encoded: coloredVal) {
                    base64Data = data
                } else if let url = URL(string: coloredVal) {
                    remoteUrl = url
                }

                coloredImageFile = ImageFile(
                    fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-colored",
                    fileExtension: "png",
                    remoteUrl: remoteUrl,
                    base64Data: base64Data)

            } else {
                coloredImageFile = ImageFile(
                    fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-colored",
                    fileExtension: "png",
                    remoteUrl: nil,
                    base64Data: nil)
            }
            imageFiles.append(coloredImageFile)

            var lightImageFile: ImageFile
            if let lightVal = paymentMethod.displayMetadata?.button.iconUrl?.lightUrlStr {
                var remoteUrl: URL?
                var base64Data: Data?

                if let data = Data(base64Encoded: lightVal) {
                    base64Data = data
                } else if let url = URL(string: lightVal) {
                    remoteUrl = url
                }

                lightImageFile = ImageFile(
                    fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-light",
                    fileExtension: "png",
                    remoteUrl: remoteUrl,
                    base64Data: base64Data)

            } else {
                lightImageFile = ImageFile(
                    fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-light",
                    fileExtension: "png",
                    remoteUrl: nil,
                    base64Data: nil)
            }
            imageFiles.append(lightImageFile)

            var darkImageFile: ImageFile
            if let darkVal = paymentMethod.displayMetadata?.button.iconUrl?.darkUrlStr {
                var remoteUrl: URL?
                var base64Data: Data?

                if let data = Data(base64Encoded: darkVal) {
                    base64Data = data
                } else if let url = URL(string: darkVal) {
                    remoteUrl = url
                }

                darkImageFile = ImageFile(
                    fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-dark",
                    fileExtension: "png",
                    remoteUrl: remoteUrl,
                    base64Data: base64Data)

            } else {
                darkImageFile = ImageFile(
                    fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-dark",
                    fileExtension: "png",
                    remoteUrl: nil,
                    base64Data: nil)
            }
            imageFiles.append(darkImageFile)
        }

        let imageManager = ImageManager()

        return firstly {
            imageManager.getImages(for: imageFiles)
        }
        .done { imageFiles in
            for (index, paymentMethod) in (apiConfiguration.paymentMethods ?? []).enumerated() {
                let paymentMethodImageFiles = imageFiles.filter { $0.fileName.contains(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-")) }
                if paymentMethodImageFiles.isEmpty {
                    continue
                }

                let coloredImageFile = paymentMethodImageFiles
                    .filter({ $0.fileName.contains("dark") == false && $0.fileName.contains("light") == false }).first
                let darkImageFile = paymentMethodImageFiles
                    .filter({ $0.fileName.contains("dark") == true }).first
                let lightImageFile = paymentMethodImageFiles
                    .filter({ $0.fileName.contains("light") == true }).first

                let baseImage = PrimerTheme.BaseImage(
                    colored: coloredImageFile?.image,
                    light: lightImageFile?.image,
                    dark: darkImageFile?.image)
                apiConfiguration.paymentMethods?[index].baseLogoImage = baseImage
            }
        }
    }
}
// swiftlint:enable cyclomatic_complexity
