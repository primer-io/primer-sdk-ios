//
//  ImageManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 15/7/22.
//

import UIKit

internal class ImageFile: File {

    static func getPaymentMethodType(fromFileName fileName: String) -> String? {
        var tmpFileName = fileName.replacingOccurrences(of: "-logo", with: "")
        tmpFileName = tmpFileName.replacingOccurrences(of: "-icon", with: "")
        tmpFileName = tmpFileName.replacingOccurrences(of: "-colored", with: "")
        tmpFileName = tmpFileName.replacingOccurrences(of: "-dark", with: "")
        tmpFileName = tmpFileName.replacingOccurrences(of: "-light", with: "")
        tmpFileName = tmpFileName.uppercased().replacingOccurrences(of: "-", with: "_")

        let paymentMethodTypeRawValues = PrimerPaymentMethodType.allCases.compactMap({ $0.rawValue })
        let results = paymentMethodTypeRawValues.filter({ $0 == tmpFileName })

        if results.isEmpty {
            return nil
        } else {
            return results.first
        }
    }

    static func getBundledImageFileName(
        forPaymentMethodType paymentMethodType: String,
        themeMode: PrimerTheme.Mode,
        assetType: PrimerPaymentMethodAsset.ImageType
    ) -> String? {

        var tmpPaymentMethodFileNameFirstComponent: String?
        guard let supportedPaymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType) else { return nil }

        if supportedPaymentMethodType == .xfersPayNow {
            tmpPaymentMethodFileNameFirstComponent = supportedPaymentMethodType.provider
        } else if supportedPaymentMethodType.provider == paymentMethodType {
            tmpPaymentMethodFileNameFirstComponent = paymentMethodType
        } else if paymentMethodType.starts(with: "\(supportedPaymentMethodType.provider)_") {
            tmpPaymentMethodFileNameFirstComponent = paymentMethodType.replacingOccurrences(of: "\(supportedPaymentMethodType.provider)_", with: "")
        } else {
            return nil
        }

        tmpPaymentMethodFileNameFirstComponent = tmpPaymentMethodFileNameFirstComponent!.lowercased().replacingOccurrences(of: "_", with: "-")

        switch assetType {
        case .logo:
            return "\(tmpPaymentMethodFileNameFirstComponent!)-logo-\(themeMode.rawValue)"
        case .icon:
            return "\(tmpPaymentMethodFileNameFirstComponent!)-icon-\(themeMode.rawValue)"
        }
    }

    var cachedImage: UIImage? {
        guard let data = self.data, let image = UIImage(data: data, scale: 2.0) else { return nil }
        return image
    }

    var bundledImage: UIImage? {
        let paymentMethodType = ImageFile.getPaymentMethodType(fromFileName: self.fileName) ?? self.fileName

        if self.fileName.contains("dark") == true {
            if let paymentMethodLogoFileName = ImageFile.getBundledImageFileName(forPaymentMethodType: paymentMethodType, themeMode: .dark, assetType: .logo),
               let image = UIImage(named: paymentMethodLogoFileName, in: Bundle.primerResources, compatibleWith: nil) {
                return image
            } else if let image = UIImage(named: self.fileName, in: Bundle.primerResources, compatibleWith: nil) {
                return image
            }
        } else if self.fileName.contains("light") == true {
            if let paymentMethodLogoFileName = ImageFile.getBundledImageFileName(forPaymentMethodType: paymentMethodType, themeMode: .light, assetType: .logo),
               let image = UIImage(named: paymentMethodLogoFileName, in: Bundle.primerResources, compatibleWith: nil) {
                return image
            } else if let image = UIImage(named: self.fileName, in: Bundle.primerResources, compatibleWith: nil) {
                return image
            }
        } else if self.fileName.contains("colored") == true {
            if let paymentMethodLogoFileName = ImageFile.getBundledImageFileName(forPaymentMethodType: paymentMethodType, themeMode: .colored, assetType: .logo),
               let image = UIImage(named: paymentMethodLogoFileName, in: Bundle.primerResources, compatibleWith: nil) {
                return image
            } else if let image = UIImage(named: self.fileName, in: Bundle.primerResources, compatibleWith: nil) {
                return image
            }
        }

        return nil
    }

    var image: UIImage? {
        return cachedImage ?? bundledImage
    }
}

internal class ImageManager: LogReporter {

    func getImages(for imageFiles: [ImageFile]) -> Promise<[ImageFile]> {
        return Promise { seal in
            guard !imageFiles.isEmpty else {
                seal.fulfill([])
                return
            }

            let timingEventId = UUID().uuidString
            let timingEventStart = Analytics.Event.allImagesLoading(
                momentType: .start,
                id: timingEventId
            )

            let promises = imageFiles.compactMap({ self.getImage(file: $0) })

            firstly {
                when(resolved: promises)
            }
            .done { responses in
                var imageFiles: [ImageFile] = []
                var errors: [Error] = []

                for response in responses {
                    switch response {
                    case .success(let imageFile):
                        imageFiles.append(imageFile)
                    case .failure(let err):
                        errors.append(err)
                    }
                }

                if !errors.isEmpty, errors.count == responses.count {
                    let err = InternalError.underlyingErrors(errors: errors, userInfo: nil, diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    throw err
                } else {
                    seal.fulfill(imageFiles)
                }
            }
            .ensure {
                let timingEventEnd = Analytics.Event.allImagesLoading(
                    momentType: .end,
                    id: timingEventId
                )

                Analytics.Service.record(events: [timingEventStart, timingEventEnd])
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    func getImage(file: ImageFile) -> Promise<ImageFile> {
        return Promise { seal in
            let downloader = Downloader()

            let timingEventId = UUID().uuidString
            let timingEventStart = Analytics.Event.allImagesLoading(
                momentType: .start,
                id: timingEventId
            )

            /// First try to download the image with the relevant caching policy.
            /// Therefore, if the image is cached, it will be returned.
            /// If the image download fails, check for a bundled image with the filename,
            /// if it exists continue.

            firstly {
                downloader.download(file: file)
            }
            .done { file in
                if let imageFile = file as? ImageFile,
                   imageFile.cachedImage != nil {
                    seal.fulfill(imageFile)

                } else {
                    let err = InternalError.failedToDecode(message: "image", userInfo: nil, diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    throw err
                }
            }
            .ensure {
                let timingEventEnd = Analytics.Event.timer(
                    momentType: .end,
                    id: timingEventId
                )
                Analytics.Service.record(events: [timingEventStart, timingEventEnd])
            }
            .catch { err in
                if file.bundledImage != nil {
                    let bundledImageEvent = Analytics.Event.message(
                        message: "Failed to load image (\(file.fileName) with URL \(file.remoteUrl?.absoluteString ?? "null"), but found image locally",
                        messageType: .paymentMethodImageLoadingFailed,
                        severity: .info
                    )
                    Analytics.Service.record(events: [bundledImageEvent])

                    self.logger.warn(message: "FAILED TO DOWNLOAD LOGO BUT FOUND LOGO LOCALLY")
                    self.logger.warn(message: "Payment method [\(file.fileName)] logo URL: \(file.remoteUrl?.absoluteString ?? "null")")

                    seal.fulfill(file)

                } else {
                    let failedToLoadEvent = Analytics.Event.message(
                        message: "Failed to load image (\(file.fileName) with URL \(file.remoteUrl?.absoluteString ?? "null")",
                        messageType: .paymentMethodImageLoadingFailed,
                        severity: .warning
                    )
                    Analytics.Service.record(events: [failedToLoadEvent])

                    self.logger.warn(message: "FAILED TO DOWNLOAD LOGO")
                    self.logger.warn(message: "Payment method [\(file.fileName)] logo URL: \(file.remoteUrl?.absoluteString ?? "null")")

                    seal.reject(err)
                }
            }
        }
    }

    static func clean() {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let documentsPath = documentDirectoryUrl.path

        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: "\(documentsPath)")

            for fileName in fileNames where fileName.hasSuffix(".png") {
                let filePathName = "\(documentsPath)/\(fileName)"
                try FileManager.default.removeItem(atPath: filePathName)
            }

        } catch {
            logger.error(message: "IMAGE MANAGER")
            logger.error(message: "Clean failed with error: \(error)")
        }
    }
}
