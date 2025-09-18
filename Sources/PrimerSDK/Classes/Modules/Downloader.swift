//
//  Downloader.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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

        var tmpFilename: String = self.fileName
        if let fileExtension = self.fileExtension {
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
    func download(files: [File]) async throws -> [File]
}

// MARK: MISSING_TESTS
final class Downloader: NSObject, DownloaderModule {

    private var documentDirectoryUrl: URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
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
            throw handled(primerError: .underlyingErrors(errors: errors))
        }

        return downloadedFiles
    }

    func download(file: File) async throws -> File {
        guard let fileRemoteUrl = file.remoteUrl else {
            throw handled(internalError: .invalidValue(key: "remoteUrl"))
        }

        guard let fileLocalUrl = file.localUrl else {
            throw handled(internalError: .invalidValue(key: "localUrl"))
        }

        do {
            try await downloadData(from: fileRemoteUrl, to: fileLocalUrl)
            return file
        } catch {
            if let primerErr = error as? PrimerError,
               case .underlyingErrors(let errors, _) = primerErr,
               errors.contains(where: { ($0 as NSError).code == 516 }) {
                return file
            }

            throw error
        }
    }

    private func downloadData(from url: URL, to localUrl: URL) async throws {
        let session = URLSession.shared
        session.configuration.urlCache = URLCache.shared
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 2)
        let cache = session.configuration.urlCache

        if let cachedResponse = cache?.cachedResponse(for: request) {
            if fileExists(at: localUrl) { return }

            let validStatusCodesRange = 200 ..< 300

            if let httpUrlResponse = cachedResponse.response as? HTTPURLResponse,
               validStatusCodesRange.contains(httpUrlResponse.statusCode) {
                do {
                    FileManager.default.delegate = self
                    try cachedResponse.data.write(to: localUrl)
                    return
                } catch {
                    throw handled(error: error.normalizedForSDK)
                }
            }
        }

        do {
            let (tempLocalUrl, response) = try await executeDownloadTask(for: request, on: session)
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                throw handled(internalError: .invalidValue(key: "URL status code"))
            }

            let validStatusCodeRange = 200 ..< 300

            guard validStatusCodeRange.contains(statusCode) else {
                throw handled(internalError: .serverError(status: statusCode))
            }

            FileManager.default.delegate = self
            try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)

            if cache?.cachedResponse(for: request) == nil, let data = try? Data(contentsOf: tempLocalUrl) {
                cache?.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
            }

        } catch {
            throw handled(error: error.normalizedForSDK)
        }
    }

    private func executeDownloadTask(for request: URLRequest, on session: URLSession) async throws -> (URL, URLResponse) {
        if #available(iOS 15.0, *) {
            return try await session.download(for: request)
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                let task = session.downloadTask(with: request) { tempLocalUrl, response, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let tempLocalUrl, let response {
                        continuation.resume(returning: (tempLocalUrl, response))
                    } else {
                        let err = InternalError.invalidValue(key: "Failed to receive both error and response")
                        precondition(true, err.localizedDescription)
                        continuation.resume(throwing: err)
                    }
                }
                task.resume()
            }
        }
    }

    // MARK: - Helper Methods

    private func fileExists(at url: URL) -> Bool {
        if #available(iOS 16.0, *) {
            return FileManager.default.fileExists(atPath: url.path())
        } else {
            return FileManager.default.fileExists(atPath: url.path)
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
