//
//  ImageManager.swift
//  PrimerSDK
//
//  Created by Evangelos on 15/7/22.
//

// swiftlint:disable function_body_length

import UIKit

// MARK: MISSING_TESTS
final class ImageFile: File {

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
            tmpPaymentMethodFileNameFirstComponent = paymentMethodType.replacingOccurrences(of: "\(supportedPaymentMethodType.provider)_",
                                                                                            with: "")
        } else {
            return nil
        }

        tmpPaymentMethodFileNameFirstComponent = tmpPaymentMethodFileNameFirstComponent!.lowercased().replacingOccurrences(of: "_",
                                                                                                                           with: "-")

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
            if let paymentMethodLogoFileName = ImageFile.getBundledImageFileName(forPaymentMethodType: paymentMethodType,
                                                                                 themeMode: .dark,
                                                                                 assetType: .logo),
               let image = UIImage(primerResource: paymentMethodLogoFileName) {
                return image
            } else if let image = UIImage(primerResource: fileName) {
                return image
            }
        } else if self.fileName.contains("light") == true {
            if let paymentMethodLogoFileName = ImageFile.getBundledImageFileName(forPaymentMethodType: paymentMethodType,
                                                                                 themeMode: .light,
                                                                                 assetType: .logo),
               let image = UIImage(primerResource: paymentMethodLogoFileName) {
                return image
            } else if let image = UIImage(primerResource: fileName) {
                return image
            }
        } else if self.fileName.contains("colored") == true {
            if let paymentMethodLogoFileName = ImageFile.getBundledImageFileName(forPaymentMethodType: paymentMethodType,
                                                                                 themeMode: .colored,
                                                                                 assetType: .logo),
               let image = UIImage(primerResource: paymentMethodLogoFileName) {
                return image
            } else if let image = UIImage(primerResource: fileName) {
                return image
            }
        }

        return nil
    }

    var image: UIImage? {
        return cachedImage ?? bundledImage
    }
}

// MARK: MISSING_TESTS
final class ImageManager: LogReporter {

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
                    let err = InternalError.underlyingErrors(errors: errors,
                                                             userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
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

    func getImages(for imageFiles: [ImageFile]) async throws -> [ImageFile] {
        guard !imageFiles.isEmpty else { return [] }

        let timingEventId = UUID().uuidString
        let timingEventStart = Analytics.Event.allImagesLoading(
            momentType: .start,
            id: timingEventId
        )

        // MARK: REVIEW_CHECK - Same logic as PromiseKit's ensure

        defer {
            let timingEventEnd = Analytics.Event.allImagesLoading(
                momentType: .end,
                id: timingEventId
            )
            Analytics.Service.record(events: [timingEventStart, timingEventEnd])
        }

        var imageFiles: [ImageFile] = []
        var errors: [Error] = []

        for imageFile in imageFiles {
            do {
                let file = try await getImage(file: imageFile)
                imageFiles.append(file)
            } catch {
                errors.append(error)
            }
        }

        if !errors.isEmpty, errors.count == imageFiles.count {
            let err = InternalError.underlyingErrors(errors: errors,
                                                     userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        } else {
            return imageFiles
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

            // First try to download the image with the relevant caching policy.
            // Therefore, if the image is cached, it will be returned.
            // If the image download fails, check for a bundled image with the filename,
            // if it exists continue.
            firstly {
                downloader.download(file: file)
            }
            .done { file in
                if let imageFile = file as? ImageFile,
                   imageFile.cachedImage != nil {
                    seal.fulfill(imageFile)

                } else {
                    let err = InternalError.failedToDecode(message: "image", userInfo: .errorUserInfoDictionary(),
                                                           diagnosticsId: UUID().uuidString)
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

                    self.logger.warn(message: "FAILED TO DOWNLOAD LOGO BUT FOUND LOGO LOCALLY")
                    self.logger.warn(message: "Payment method [\(file.fileName)] logo URL: \(file.remoteUrl?.absoluteString ?? "null")")

                    seal.fulfill(file)

                } else {

                    self.logger.warn(message: "FAILED TO DOWNLOAD LOGO")
                    self.logger.warn(message: "Payment method [\(file.fileName)] logo URL: \(file.remoteUrl?.absoluteString ?? "null")")

                    seal.reject(err)
                }
            }
        }
    }

    func getImage(file: ImageFile) async throws -> ImageFile {
        let download = Downloader()
        let timingEventId = UUID().uuidString
        let timingEventStart = Analytics.Event.allImagesLoading(
            momentType: .start,
            id: timingEventId
        )

        defer {
            let timingEventEnd = Analytics.Event.timer(
                momentType: .end,
                id: timingEventId
            )
            Analytics.Service.record(events: [timingEventStart, timingEventEnd])
        }

        // First try to download the image with the relevant caching policy.
        // Therefore, if the image is cached, it will be returned.
        // If the image download fails, check for a bundled image with the filename,
        // if it exists continue.
        do {
            let file = try await download.download(file: file)

            if let imageFile = file as? ImageFile, imageFile.cachedImage != nil {
                return imageFile
            } else {
                let err = InternalError.failedToDecode(message: "image", userInfo: .errorUserInfoDictionary(),
                                                       diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        } catch {
            if file.bundledImage != nil {
                logger.warn(message: "FAILED TO DOWNLOAD LOGO BUT FOUND LOGO LOCALLY")
                logger.warn(message: "Payment method [\(file.fileName)] logo URL: \(file.remoteUrl?.absoluteString ?? "null")")

                return file

            } else {
                logger.warn(message: "FAILED TO DOWNLOAD LOGO")
                logger.warn(message: "Payment method [\(file.fileName)] logo URL: \(file.remoteUrl?.absoluteString ?? "null")")

                throw error
            }
        }
    }

    static func clean() {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory,
                                                                  in: .userDomainMask).first
        else { return }
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
// swiftlint:enable function_body_length
