//
//  File.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

//
//  File.swift
//  PrimerSDK
//
//  Created by Henry Cooper on 17/06/2026.
//
import Foundation
@_spi(PrimerInternal) import PrimerFoundation

public typealias FileName = String
public typealias FileExtension = String

@_spi(PrimerInternal) open class File: LogReporter {

    /// Directory holding all SDK-cached files, namespaced away from the host app's data.
    /// Lives under Caches: the contents are re-downloadable and should not be backed up.
    public static var cacheDirectoryUrl: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("primer", isDirectory: true)
    }

    public static func ensureCacheDirectoryExists() {
        guard let url = cacheDirectoryUrl else { return }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    public var fileName: FileName
    public var fileExtension: FileExtension?
    public var localUrl: URL? {
        guard let cacheDirectoryUrl = Self.cacheDirectoryUrl else { return nil }

        var tmpFilename: String = self.fileName
        if let fileExtension = self.fileExtension {
            tmpFilename += "." + fileExtension
        }

        return cacheDirectoryUrl.appendingPathComponent(tmpFilename)
    }
    public private(set) var remoteUrl: URL?
    private var base64Data: Data?

    public var data: Data? {
        guard let localUrl = localUrl else { return nil }
        return try? Data(contentsOf: localUrl)
    }

    public init(
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
           let localUrl {
            do {
                Self.ensureCacheDirectoryExists()
                try base64Data.write(to: localUrl)
            } catch {
                logger.error(message: "Write failed")
            }
        }
    }
}
