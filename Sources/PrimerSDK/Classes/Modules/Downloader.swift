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
    var fileExtension: FileExtension?
    var localUrl: URL? {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        var tmpFilename: String = self.fileName
        if let fileExtension = self.fileExtension {
            tmpFilename = tmpFilename + "." + fileExtension
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
            let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        {
            do {
                var tmpFilename: String = self.fileName
                if let fileExtension = self.fileExtension {
                    tmpFilename = tmpFilename + "." + fileExtension
                }
                
                let fileLocalUrl = documentDirectoryUrl
                    .appendingPathComponent("primer", isDirectory: true)
                    .appendingPathComponent(tmpFilename)
                try base64Data.write(to: fileLocalUrl)
                
            } catch {
                log(logLevel: .error, title: "Write failed", message: nil, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: nil, line: nil)
            }
        }
    }
}

internal protocol DownloaderModule {
    func download(files: [File]) -> Promise<[File]>
}

internal class Downloader: NSObject, DownloaderModule {
    
    private var documentDirectoryUrl: URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    func download(files: [File]) -> Promise<[File]> {
        return Promise { seal in
            var promises: [Promise<File>] = []
            
            for file in files {
                let p = self.download(file: file)
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
    
    func download(file: File) -> Promise<File> {
        return Promise { seal in
            guard let fileRemoteUrl = file.remoteUrl else {
                let err = InternalError.invalidValue(key: "remoteUrl", value: nil, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let fileLocalUrl = file.localUrl else {
                let err = InternalError.invalidValue(key: "localUrl", value: nil, userInfo: nil, diagnosticsId: nil)
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
    
    private func downloadData(from url: URL, to localUrl: URL) -> Promise<Void> {
        return Promise { seal in
            let sessionConfig = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfig)
            let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 2)
            
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
                            ErrorHandler.handle(error: primerErr)
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
