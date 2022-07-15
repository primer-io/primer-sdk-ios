//
//  DownloaderModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 14/7/22.
//

#if canImport(UIKit)

import Foundation

internal typealias FileName = String
internal typealias FileExtension = String

internal class File {
    
    var fileName: FileName
    var fileExtension: FileExtension
    var localUrl: URL?
    var remoteUrl: URL?
    
    var data: Data? {
        guard let localUrl = localUrl else { return nil }
        return try? Data(contentsOf: localUrl)
    }
    
    init(
        fileName: FileName,
        fileExtension: FileExtension,
        localUrl: URL? = nil,
        remoteUrl: URL? = nil
    ) {
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.localUrl = localUrl
        self.remoteUrl = remoteUrl
    }
}

internal protocol DownloaderModule {
    func download(files: [File], storeInDirectory directory: String?) -> Promise<[File]>
}

internal class Downloader: NSObject, DownloaderModule {
    
    private var documentDirectoryUrl: URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    func download(files: [File], storeInDirectory directory: String? = nil) -> Promise<[File]> {
        return Promise { seal in
            guard let documentDirectoryUrl = documentDirectoryUrl else {
                seal.reject(PrimerError.invalidValue(key: "documentsDirectory", value: nil, userInfo: nil, diagnosticsId: nil))
                return
            }
            
            var promises: [Promise<Void>] = []
            
            for file in files {
                guard let fileRemoteUrl = file.remoteUrl else { continue }
                var tmpFilename: String = file.fileName + "." + file.fileExtension
                
                if let directory = directory {
                    tmpFilename = directory + "/" + tmpFilename
                }
                
                let fileLocalUrl = documentDirectoryUrl.appendingPathComponent(tmpFilename)
                file.localUrl = fileLocalUrl
                let p = self.downloadData(from: fileRemoteUrl, to: fileLocalUrl)
                promises.append(p)
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
                    let err = InternalError.underlyingErrors(errors: errors, userInfo: nil, diagnosticsId: nil)
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
    
    func download(file: File, storeInDirectory directory: String? = nil) -> Promise<File> {
        return Promise { seal in
            guard let documentDirectoryUrl = documentDirectoryUrl else {
                seal.reject(PrimerError.invalidValue(key: "documentsDirectory", value: nil, userInfo: nil, diagnosticsId: nil))
                return
            }
            
            guard let fileRemoteUrl = file.remoteUrl else {
                let err = InternalError.invalidValue(key: "remoteUrl", value: nil, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            var tmpFilename: String = file.fileName + "." + file.fileExtension
            
            if let directory = directory {
                tmpFilename = directory + "/" + tmpFilename
            }
            
            let fileLocalUrl = documentDirectoryUrl.appendingPathComponent(tmpFilename)
            file.localUrl = fileLocalUrl
            
            firstly {
                self.downloadData(from: fileRemoteUrl, to: fileLocalUrl)
            }
            .done {
                seal.fulfill(file)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func downloadData(from url: URL, to localUrl: URL) -> Promise<Void> {
        return Promise { seal in
            let sessionConfig = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfig)
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
            
            let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                if let error = error {
                    let primerErr = PrimerError.underlyingErrors(errors: [error], userInfo: nil, diagnosticsId: nil)
                    seal.reject(primerErr)
                    
                } else if let tempLocalUrl = tempLocalUrl {
                    guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                        let err = InternalError.invalidValue(key: "URL status code", value: nil, userInfo: nil, diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }
                    
                    let validStatusCodeRange = 200..<300
                    if validStatusCodeRange.contains(statusCode) {
                        do {
                            FileManager.default.delegate = self
                            try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                            seal.fulfill(())
                            
                        } catch {
                            let primerErr = PrimerError.underlyingErrors(errors: [error], userInfo: nil, diagnosticsId: nil)
                            seal.reject(primerErr)
                        }
                    } else {
                        let err = InternalError.serverError(status: statusCode, response: nil, userInfo: nil, diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                    }
                    
                } else {
                    let err = InternalError.invalidValue(key: "Failed to receive both error and response", value: nil, userInfo: nil, diagnosticsId: nil)
                    precondition(true, err.localizedDescription)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            }
            
            task.resume()
        }
    }
}

extension Downloader: FileManagerDelegate {
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAt srcURL: URL, to dstURL: URL) -> Bool {
        return true
    }
}

#endif
