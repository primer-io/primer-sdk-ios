//
//  DownloaderModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 14/7/22.
//

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

import Foundation

internal typealias FileName = String
internal typealias FileExtension = String

class File: LogReporter {
    var fileName: FileName
    var fileExtension: FileExtension?
    var localUrl: URL? {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }

        var tmpFilename: String = fileName
        if let fileExtension = fileExtension {
            tmpFilename += "." + fileExtension
        }

        let fileLocalUrl = documentDirectoryUrl.appendingPathComponent(tmpFilename)
        return fileLocalUrl
    }

    private(set) var remoteUrl: URL?
    private var base64Data: Data?

    var data: Data? {
        guard let localUrl = localUrl else { return nil }
        return try? Data(contentsOf: localUrl)
    }

    init(
        fileName: FileName,
        fileExtension: FileExtension?,
        remoteUrl: URL? = nil,
        base64Data: Data? = nil
    ) {
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.remoteUrl = remoteUrl
        self.base64Data = base64Data

        if let base64Data = self.base64Data,
           let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                var tmpFilename: String = self.fileName
                if let fileExtension = self.fileExtension {
                    tmpFilename += "." + fileExtension
                }

                let fileLocalUrl = documentDirectoryUrl
                    .appendingPathComponent("primer", isDirectory: true)
                    .appendingPathComponent(tmpFilename)
                try base64Data.write(to: fileLocalUrl)

            } catch {
                logger.error(message: "Write failed")
            }
        }
    }
}

internal protocol DownloaderModule {
    func download(files: [File]) -> Promise<[File]>
    func download(files: [File]) async throws -> [File]
}

// MARK: MISSING_TESTS
final class Downloader: NSObject, DownloaderModule {
    private var documentDirectoryUrl: URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    func download(files: [File]) -> Promise<[File]> {
        return Promise { seal in
            var promises: [Promise<File>] = []

            for file in files {
                let promise = self.download(file: file)
                promises.append(promise)
            }

            firstly {
                when(resolved: promises)
            }
            .done { responses in
                var errors: [Error] = []
                for response in responses {
                    switch response {
                    case .success:
                        break
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
                    seal.fulfill(files)
                }
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    func download(files: [File]) async throws -> [File] {
        var downloadedFiles: [File] = []
        var errors: [Error] = []

        for file in files {
            do {
                let downloadedFile = try await download(file: file)
                downloadedFiles.append(downloadedFile)
            } catch {
                errors.append(error)
            }
        }

        if !errors.isEmpty && errors.count == files.count {
            let primerErr = PrimerError.underlyingErrors(
                errors: errors,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: primerErr)
            throw primerErr
        }

        return downloadedFiles
    }

    func download(file: File) -> Promise<File> {
        return Promise { seal in
            guard let fileRemoteUrl = file.remoteUrl else {
                let err = InternalError.invalidValue(key: "remoteUrl",
                                                     value: nil,
                                                     userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            guard let fileLocalUrl = file.localUrl else {
                let err = InternalError.invalidValue(key: "localUrl",
                                                     value: nil,
                                                     userInfo: .errorUserInfoDictionary(),
                                                     diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            firstly {
                self.downloadData(from: fileRemoteUrl, to: fileLocalUrl)
            }
            .done {
                seal.fulfill(file)
            }
            .catch { err in
                if let primerErr = err as? PrimerError {
                    switch primerErr {
                    case .underlyingErrors(let errors, _, _):
                        if errors.filter({ ($0 as NSError).code == 516 }).first != nil {
                            seal.fulfill(file)
                            return
                        }
                    default:
                        break
                    }
                }

                seal.reject(err)
            }
        }
    }

    func download(file: File) async throws -> File {
        guard let fileRemoteUrl = file.remoteUrl else {
            let err = InternalError.invalidValue(key: "remoteUrl",
                                                 value: nil,
                                                 userInfo: .errorUserInfoDictionary(),
                                                 diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        guard let fileLocalUrl = file.localUrl else {
            let err = InternalError.invalidValue(key: "localUrl",
                                                 value: nil,
                                                 userInfo: .errorUserInfoDictionary(),
                                                 diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }

        do {
            try await downloadData(from: fileRemoteUrl, to: fileLocalUrl)
            return file
        } catch {
            if let primerErr = error as? PrimerError {
                switch primerErr {
                case .underlyingErrors(let errors, _, _):
                    if errors.filter({ ($0 as NSError).code == 516 }).first != nil {
                        return file
                    }
                default:
                    break
                }
            }

            throw error
        }
    }

    private func downloadData(from url: URL, to localUrl: URL) -> Promise<Void> {
        return Promise { seal in
            let session = URLSession.shared
            session.configuration.urlCache = URLCache.shared
            let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 2)
            let cache = session.configuration.urlCache

            if let cachedResponse = cache?.cachedResponse(for: request) {
                if #available(iOS 16.0, *) {
                    if FileManager.default.fileExists(atPath: localUrl.path()) {
                        seal.fulfill(())
                        return
                    }
                } else {
                    if FileManager.default.fileExists(atPath: localUrl.path) {
                        seal.fulfill(())
                        return
                    }
                }

                let validStatusCodesRange = 200 ..< 300

                if let httpUrlResponse = cachedResponse.response as? HTTPURLResponse,
                   validStatusCodesRange.contains(httpUrlResponse.statusCode) {
                    do {
                        FileManager.default.delegate = self
                        try cachedResponse.data.write(to: localUrl)
                        seal.fulfill(())
                        return

                    } catch {
                        let primerErr = PrimerError.underlyingErrors(errors: [error],
                                                                     userInfo: .errorUserInfoDictionary(),
                                                                     diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: primerErr)
                    }
                }
            }

            let task = session.downloadTask(with: request) { tempLocalUrl, response, error in
                if let error = error {
                    let primerErr = PrimerError.underlyingErrors(errors: [error],
                                                                 userInfo: .errorUserInfoDictionary(),
                                                                 diagnosticsId: UUID().uuidString)
                    seal.reject(primerErr)

                } else if let response = response,
                          let tempLocalUrl = tempLocalUrl {
                    guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                        let err = InternalError.invalidValue(key: "URL status code",
                                                             value: nil,
                                                             userInfo: .errorUserInfoDictionary(),
                                                             diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }

                    let validStatusCodeRange = 200 ..< 300
                    if validStatusCodeRange.contains(statusCode) {
                        do {
                            FileManager.default.delegate = self
                            try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)

                            if cache?.cachedResponse(for: request) == nil, let data = try? Data(contentsOf: tempLocalUrl) {
                                cache?.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
                            }

                            seal.fulfill(())

                        } catch {
                            let primerErr = PrimerError.underlyingErrors(errors: [error],
                                                                         userInfo: .errorUserInfoDictionary(),
                                                                         diagnosticsId: UUID().uuidString)
                            ErrorHandler.handle(error: primerErr)
                            seal.reject(primerErr)
                        }
                    } else {
                        let err = InternalError.serverError(status: statusCode,
                                                            response: nil,
                                                            userInfo: .errorUserInfoDictionary(),
                                                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    }

                } else {
                    let err = InternalError.invalidValue(key: "Failed to receive both error and response",
                                                         value: nil,
                                                         userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
                    precondition(true, err.localizedDescription)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            }

            task.resume()
        }
    }

    private func downloadData(from url: URL, to localUrl: URL) async throws {
        let session = URLSession.shared
        session.configuration.urlCache = URLCache.shared
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 2)
        let cache = session.configuration.urlCache

        if let cachedResponse = cache?.cachedResponse(for: request) {
            if #available(iOS 16.0, *) {
                if FileManager.default.fileExists(atPath: localUrl.path()) {
                    return
                }
            } else {
                if FileManager.default.fileExists(atPath: localUrl.path) {
                    return
                }
            }

            let validStatusCodesRange = 200 ..< 300

            if let httpUrlResponse = cachedResponse.response as? HTTPURLResponse,
               validStatusCodesRange.contains(httpUrlResponse.statusCode) {
                do {
                    FileManager.default.delegate = self
                    try cachedResponse.data.write(to: localUrl)
                    return
                } catch {
                    let primerErr = PrimerError.underlyingErrors(
                        errors: [error],
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString
                    )
                    ErrorHandler.handle(error: primerErr)
                    throw primerErr
                }
            }
        }

        do {
            let (tempLocalUrl, response) = try await executeDownloadTask(for: request, on: session)
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                let err = InternalError.invalidValue(
                    key: "URL status code",
                    value: nil,
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: err)
                throw err
            }

            let validStatusCodeRange = 200 ..< 300

            guard validStatusCodeRange.contains(statusCode) else {
                let err = InternalError.serverError(
                    status: statusCode,
                    response: nil,
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: err)
                throw err
            }

            FileManager.default.delegate = self
            try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)

            if cache?.cachedResponse(for: request) == nil, let data = try? Data(contentsOf: tempLocalUrl) {
                cache?.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
            }

        } catch {
            let primerErr = PrimerError.underlyingErrors(
                errors: [error],
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: primerErr)
            throw primerErr
        }
    }

    private func executeDownloadTask(for request: URLRequest, on session: URLSession) async throws -> (URL, URLResponse) {
        if #available(iOS 15.0, *) {
            let (tempLocalUrl, response) = try await session.download(for: request)
            return (tempLocalUrl, response)
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                let task = session.downloadTask(with: request) { tempLocalUrl, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let tempLocalUrl = tempLocalUrl, let response = response {
                        continuation.resume(returning: (tempLocalUrl, response))
                    } else {
                        let err = InternalError.invalidValue(
                            key: "Failed to receive both error and response",
                            value: nil,
                            userInfo: .errorUserInfoDictionary(),
                            diagnosticsId: UUID().uuidString
                        )
                        precondition(true, err.localizedDescription)
                        continuation.resume(throwing: err)
                    }
                }
                task.resume()
            }
        }
    }
}

extension Downloader: FileManagerDelegate {
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAt srcURL: URL, to dstURL: URL) -> Bool {
        return true
    }
}

// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
