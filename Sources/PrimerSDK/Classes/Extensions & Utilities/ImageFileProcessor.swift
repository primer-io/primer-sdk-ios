//
//  ImageFileProcessor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length
// MARK: MISSING_TESTS
final class ImageFileProcessor {
    init() {}

    func process(configuration apiConfiguration: PrimerAPIConfiguration) async throws {
        var imageFiles: [ImageFile] = []

        for paymentMethod in apiConfiguration.paymentMethods ?? [] {
            imageFiles.append(makeImageFile(for: paymentMethod,
                                            variant: "colored",
                                            value: paymentMethod.displayMetadata?.button.iconUrl?.coloredUrlStr))
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
