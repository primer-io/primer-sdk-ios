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

    public var fileName: FileName
    public var fileExtension: FileExtension?
    public var localUrl: URL? {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }

        var tmpFilename: String = self.fileName
        if let fileExtension = self.fileExtension {
            tmpFilename += "." + fileExtension
        }

        let fileLocalUrl = documentDirectoryUrl.appendingPathComponent(tmpFilename)
        return fileLocalUrl
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
