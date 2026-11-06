//
//  ImageManagerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) import PrimerCore

final class ImageManagerTests: XCTestCase {

    private static let bundledFileName = "paypal-logo-colored"
    private static let remoteUrl = URL(string: "https://example.com/paypal-logo-colored@3x.png")

    private var sut: ImageManager!
    private var mockDownloader: MockDownloader!

    override func setUp() {
        super.setUp()
        removeCachedFile(named: Self.bundledFileName)
        mockDownloader = MockDownloader()
        sut = ImageManager(downloader: mockDownloader)
    }

    override func tearDown() {
        removeCachedFile(named: Self.bundledFileName)
        sut = nil
        mockDownloader = nil
        super.tearDown()
    }

    func testGetImages_EmptyArray_ReturnsEmptyArray() async throws {
        let imageFiles = try await sut.getImages(for: [])
        XCTAssertEqual(imageFiles.count, 0)
    }

    func test_getImages_validImageFiles_downloadsEachFile() async throws {
        // Given
        let imageFiles = ["test-image-1", "test-image-2"].map {
            ImageFile(fileName: "\($0)-\(UUID().uuidString)", fileExtension: "png", remoteUrl: Self.remoteUrl)
        }
        defer { imageFiles.forEach { removeCachedFile(named: $0.fileName) } }
        mockDownloader.data = try makeImageData()

        // When
        let result = try await sut.getImages(for: imageFiles)

        // Then
        XCTAssertEqual(mockDownloader.downloadCallCount, 2)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.cachedImage != nil })
    }

    func testGetImage_WithCachedImage() async throws {
        guard let testImage = UIImage(systemName: "star"),
              let imageData = testImage.pngData() else {
            return XCTFail("Could not create test image data")
        }

        // base64Data is written to localUrl on init, so getImage returns the cache without network
        let imageFile = ImageFile(
            fileName: "test-image-\(UUID().uuidString)",
            fileExtension: "png",
            remoteUrl: URL(string: "https://example.com/image.png"),
            base64Data: imageData
        )
        defer {
            if let localUrl = imageFile.localUrl {
                try? FileManager.default.removeItem(at: localUrl)
            }
        }

        XCTAssertNotNil(imageFile.cachedImage, "base64Data should be readable back as the cached image")

        let result = try await sut.getImage(file: imageFile)
        XCTAssertNotNil(result.cachedImage)
        XCTAssertEqual(mockDownloader.downloadCallCount, 0)
    }

    func test_getImage_bundledCopyAndUrl_downloadsAndUsesDownloadedImage() async throws {
        // Given
        let imageFile = makeBundledImageFile(remoteUrl: Self.remoteUrl)
        let bundledSize = try XCTUnwrap(imageFile.bundledImage?.size)
        mockDownloader.data = try makeImageData()

        // When
        let result = try await sut.getImage(file: imageFile)

        // Then
        XCTAssertEqual(mockDownloader.downloadCallCount, 1)
        let downloadedSize = try XCTUnwrap(result.cachedImage?.size)
        XCTAssertEqual(result.image?.size, downloadedSize)
        XCTAssertNotEqual(downloadedSize, bundledSize)
    }

    func test_getImage_downloadFails_fallsBackToBundledCopy() async throws {
        // Given
        let imageFile = makeBundledImageFile(remoteUrl: Self.remoteUrl)
        let bundledSize = try XCTUnwrap(imageFile.bundledImage?.size)

        // When
        let result = try await sut.getImage(file: imageFile)

        // Then
        XCTAssertEqual(mockDownloader.downloadCallCount, 1)
        XCTAssertNil(result.cachedImage)
        XCTAssertEqual(result.image?.size, bundledSize)
    }

    func test_getImage_cachedFile_doesNotDownload() async throws {
        // Given
        let imageFile = ImageFile(
            fileName: Self.bundledFileName,
            fileExtension: "png",
            remoteUrl: Self.remoteUrl,
            base64Data: try makeImageData()
        )

        // When
        let result = try await sut.getImage(file: imageFile)

        // Then
        XCTAssertEqual(mockDownloader.downloadCallCount, 0)
        XCTAssertNotNil(result.cachedImage)
    }

    func test_getImage_noUrl_returnsBundledCopyWithoutDownload() async throws {
        // Given
        let imageFile = makeBundledImageFile(remoteUrl: nil)

        // When
        let result = try await sut.getImage(file: imageFile)

        // Then
        XCTAssertEqual(mockDownloader.downloadCallCount, 0)
        XCTAssertNil(result.cachedImage)
        XCTAssertNotNil(result.image)
    }

    // MARK: - clean Tests

    func testClean_RemovesPNGFiles() {
        guard let cacheURL = File.cacheDirectoryUrl,
              let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("Could not get cache/documents directory")
            return
        }
        File.ensureCacheDirectoryExists()

        let cachedFileURL = cacheURL.appendingPathComponent("test-image-\(UUID().uuidString).png")
        let hostAppFileURL = documentsURL.appendingPathComponent("host-image-\(UUID().uuidString).png")

        let testData = Data("test".utf8)
        do {
            try testData.write(to: cachedFileURL)
            try testData.write(to: hostAppFileURL)

            ImageManager.clean()

            // SDK cache is swept
            XCTAssertFalse(FileManager.default.fileExists(atPath: cachedFileURL.path))
            // The host app's own files are out of bounds
            XCTAssertTrue(FileManager.default.fileExists(atPath: hostAppFileURL.path))

            try FileManager.default.removeItem(at: hostAppFileURL)
        } catch {
            XCTFail("Failed to create test file: \(error)")
        }
    }

    func testClean_DoesNotRemoveNonPNGFiles() {
        // Create a test non-PNG file in the SDK cache directory
        guard let cacheURL = File.cacheDirectoryUrl else {
            XCTFail("Could not get cache directory")
            return
        }
        File.ensureCacheDirectoryExists()

        let testFileName = "test-file-\(UUID().uuidString).txt"
        let testFileURL = cacheURL.appendingPathComponent(testFileName)

        // Create test file
        let testData = Data("test".utf8)
        do {
            try testData.write(to: testFileURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))

            // Clean
            ImageManager.clean()

            // Verify file is NOT removed
            XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))

            // Clean up
            try FileManager.default.removeItem(at: testFileURL)
        } catch {
            XCTFail("Failed to create/remove test file: \(error)")
        }
    }

    // MARK: - Helpers

    private func makeBundledImageFile(remoteUrl: URL?) -> ImageFile {
        ImageFile(fileName: Self.bundledFileName, fileExtension: "png", remoteUrl: remoteUrl)
    }

    private func makeImageData() throws -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        return try XCTUnwrap(image.pngData())
    }

    private func removeCachedFile(named fileName: String) {
        guard let localUrl = File(fileName: fileName, fileExtension: "png").localUrl else { return }
        try? FileManager.default.removeItem(at: localUrl)
    }
}

// MARK: - Mock Classes

private final class MockDownloader: DownloaderModule {
    var data: Data?
    private(set) var downloadCallCount = 0

    func download(files: [File]) async throws -> [File] {
        var downloaded: [File] = []
        for file in files {
            try await downloaded.append(download(file: file))
        }
        return downloaded
    }

    func download(file: File) async throws -> File {
        downloadCallCount += 1
        guard let data, let localUrl = file.localUrl else { throw TestError.networkFailure }
        File.ensureCacheDirectoryExists()
        try data.write(to: localUrl)
        return file
    }
}
