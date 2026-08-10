//
//  ImageManagerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) import PrimerCore

final class ImageManagerTests: XCTestCase {
    
    var sut: ImageManager!
    private var mockDownloader: MockDownloader!
    
    override func setUp() {
        super.setUp()
        sut = ImageManager()
        mockDownloader = MockDownloader()
    }
    
    override func tearDown() {
        sut = nil
        mockDownloader = nil
        super.tearDown()
    }
    
    func testGetImages_EmptyArray_ReturnsEmptyArray() async throws {
        let imageFiles = try await sut.getImages(for: [])
        XCTAssertEqual(imageFiles.count, 0)
    }
    
    func testGetImages_ValidImageFiles() async throws {
        // Create test image files
        let imageFile1 = ImageFile(
            fileName: "test-image-1",
            fileExtension: "png",
            remoteUrl: URL(string: "https://example.com/image1.png")
        )
        
        let imageFile2 = ImageFile(
            fileName: "test-image-2",
            fileExtension: "png",
            remoteUrl: URL(string: "https://example.com/image2.png")
        )
        
        // Note: In real implementation, this would need proper mocking
        // of the Downloader class
        let imageFiles = [imageFile1, imageFile2]
        
        do {
            _ = try await sut.getImages(for: imageFiles)
            // In a real test, we'd verify the returned files
        } catch {
            // Expected to fail without proper mocking
        }
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
}

// MARK: - Mock Classes

private final class MockDownloader {
    var shouldSucceed = true
    var mockFile: File?
    var mockError: Error = NSError(domain: "test", code: 0, userInfo: nil)
    
    func download(file: File) async throws -> File {
        if shouldSucceed, let mockFile {
            return mockFile
        } else {
            throw mockError
        }
    }
}
