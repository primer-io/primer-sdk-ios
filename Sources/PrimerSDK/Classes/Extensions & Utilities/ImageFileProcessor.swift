//
//  ImageFileProcessor.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
// MARK: MISSING_TESTS
final class ImageFileProcessor {

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
                let paymentMethodImageFiles = imageFiles.filter {
                    $0.fileName.contains(paymentMethod.type.lowercased().replacingOccurrences(of: "_",
                                                                                              with: "-"))
                }
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

    func process(configuration apiConfiguration: PrimerAPIConfiguration) async throws {
        var imageFiles: [ImageFile] = []

        for paymentMethod in apiConfiguration.paymentMethods ?? [] {
            imageFiles.append(makeImageFile(for: paymentMethod, variant: "colored", value: paymentMethod.displayMetadata?.button.iconUrl?.coloredUrlStr))
            imageFiles.append(makeImageFile(for: paymentMethod, variant: "light", value: paymentMethod.displayMetadata?.button.iconUrl?.lightUrlStr))
            imageFiles.append(makeImageFile(for: paymentMethod, variant: "dark", value: paymentMethod.displayMetadata?.button.iconUrl?.darkUrlStr))
        }

        let imageManager = ImageManager()
        let images = try await imageManager.getImages(for: imageFiles)

        for (index, paymentMethod) in (apiConfiguration.paymentMethods ?? []).enumerated() {
            let paymentMethodImageFiles = images.filter {
                $0.fileName.contains(paymentMethod.type.lowercased().replacingOccurrences(of: "_",
                                                                                          with: "-"))
            }
            if paymentMethodImageFiles.isEmpty { continue }

            apiConfiguration.paymentMethods?[index].baseLogoImage = .init(
                colored: paymentMethodImageFiles.first { !$0.fileName.contains("dark") && !$0.fileName.contains("light") }?.image,
                light: paymentMethodImageFiles.first { $0.fileName.contains("light") }?.image,
                dark: paymentMethodImageFiles.first { $0.fileName.contains("dark") }?.image
            )
        }
    }

    private func makeImageFile(
        for paymentMethod: PrimerPaymentMethod,
        variant: String,
        value: String?
    ) -> ImageFile {
        ImageFile(
            fileName: "\(paymentMethod.type.lowercased().replacingOccurrences(of: "_", with: "-"))-logo-\(variant)",
            fileExtension: "png",
            remoteUrl: value.flatMap { URL(string: $0) },
            base64Data: value.flatMap { Data(base64Encoded: $0) }
        )
    }
}
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
