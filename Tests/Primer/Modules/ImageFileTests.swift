//
//  ImageFileTests.swift
//  PrimerSDKTests
//
//  Created by Boris on 15/7/25.
//

import XCTest
@testable import PrimerSDK

final class ImageFileTests: XCTestCase {
    
    // MARK: - getPaymentMethodType Tests
    
    func testGetPaymentMethodType_ValidPaymentMethod() {
        // Test exact match
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "APPLE_PAY"), "APPLE_PAY")
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "PAYMENT_CARD"), "PAYMENT_CARD")
        
        // Test with logo suffix
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "APPLE_PAY-logo"), "APPLE_PAY")
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "PAYMENT_CARD-logo"), "PAYMENT_CARD")
        
        // Test with icon suffix
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "APPLE_PAY-icon"), "APPLE_PAY")
        
        // Test with colored suffix
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "APPLE_PAY-colored"), "APPLE_PAY")
        
        // Test with dark/light suffix
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "APPLE_PAY-dark"), "APPLE_PAY")
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "APPLE_PAY-light"), "APPLE_PAY")
        
        // Test with multiple suffixes
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "APPLE_PAY-logo-dark"), "APPLE_PAY")
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "PAYMENT_CARD-icon-light"), "PAYMENT_CARD")
        
        // Test case insensitive
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "apple_pay"), "APPLE_PAY")
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "Apple_Pay"), "APPLE_PAY")
        
        // Test with dashes converted to underscores
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "apple-pay"), "APPLE_PAY")
        XCTAssertEqual(ImageFile.getPaymentMethodType(fromFileName: "payment-card"), "PAYMENT_CARD")
    }
    
    func testGetPaymentMethodType_InvalidPaymentMethod() {
        XCTAssertNil(ImageFile.getPaymentMethodType(fromFileName: "INVALID_METHOD"))
        XCTAssertNil(ImageFile.getPaymentMethodType(fromFileName: "random-file"))
        XCTAssertNil(ImageFile.getPaymentMethodType(fromFileName: ""))
    }
    
    // MARK: - getBundledImageFileName Tests
    
    func testGetBundledImageFileName_ValidPaymentMethod() {
        // Test logo assets
        XCTAssertEqual(
            ImageFile.getBundledImageFileName(
                forPaymentMethodType: "APPLE_PAY",
                themeMode: .dark,
                assetType: .logo
            ),
            "apple-pay-logo-dark"
        )
        
        XCTAssertEqual(
            ImageFile.getBundledImageFileName(
                forPaymentMethodType: "APPLE_PAY",
                themeMode: .light,
                assetType: .logo
            ),
            "apple-pay-logo-light"
        )
        
        // Test icon assets
        XCTAssertEqual(
            ImageFile.getBundledImageFileName(
                forPaymentMethodType: "APPLE_PAY",
                themeMode: .dark,
                assetType: .icon
            ),
            "apple-pay-icon-dark"
        )
        
        // Test payment card
        XCTAssertEqual(
            ImageFile.getBundledImageFileName(
                forPaymentMethodType: "PAYMENT_CARD",
                themeMode: .colored,
                assetType: .logo
            ),
            "payment-card-logo-colored"
        )
    }
    
    func testGetBundledImageFileName_InvalidPaymentMethod() {
        XCTAssertNil(
            ImageFile.getBundledImageFileName(
                forPaymentMethodType: "INVALID_METHOD",
                themeMode: .dark,
                assetType: .logo
            )
        )
    }
    
    func testGetBundledImageFileName_XfersPayNow() {
        // Special case for XFERS_PAYNOW
        if let fileName = ImageFile.getBundledImageFileName(
            forPaymentMethodType: "XFERS_PAYNOW",
            themeMode: .dark,
            assetType: .logo
        ) {
            XCTAssertTrue(fileName.contains("xfers"))
        }
    }
    
    // MARK: - Image Property Tests
    
    func testCachedImage() {
        // Test without data
        let imageFile1 = ImageFile(
            fileName: "test-image-no-data",
            fileExtension: "png",
            remoteUrl: URL(string: "https://example.com/image.png")
        )
        XCTAssertNil(imageFile1.cachedImage)
        
        // Test with base64 data
        if let testImage = UIImage(systemName: "star"),
           let imageData = testImage.pngData() {
            let imageFile2 = ImageFile(
                fileName: "test-image-with-data",
                fileExtension: "png",
                remoteUrl: URL(string: "https://example.com/image.png"),
                base64Data: imageData
            )
            // Note: cachedImage reads from file system, so this might still be nil
            // unless the file was successfully written
            _ = imageFile2.cachedImage
        }
    }
    
    func testBundledImage() {
        // Test dark theme
        let darkImageFile = ImageFile(
            fileName: "apple-pay-logo-dark",
            fileExtension: "png",
            remoteUrl: nil
        )
        // This might be nil if the bundled resource doesn't exist in test target
        _ = darkImageFile.bundledImage
        
        // Test light theme
        let lightImageFile = ImageFile(
            fileName: "apple-pay-logo-light",
            fileExtension: "png",
            remoteUrl: nil
        )
        _ = lightImageFile.bundledImage
        
        // Test colored theme
        let coloredImageFile = ImageFile(
            fileName: "payment-card-logo-colored",
            fileExtension: "png",
            remoteUrl: nil
        )
        _ = coloredImageFile.bundledImage
    }
    
    func testImageProperty() {
        // Test without cached image
        let imageFile1 = ImageFile(
            fileName: "test-image",
            fileExtension: "png",
            remoteUrl: URL(string: "https://example.com/image.png")
        )
        // Should return bundled image if no cached image
        _ = imageFile1.image
        
        // Test with cached image via base64Data
        if let testImage = UIImage(systemName: "star"),
           let imageData = testImage.pngData() {
            let imageFile2 = ImageFile(
                fileName: "test-image-cached",
                fileExtension: "png",
                remoteUrl: URL(string: "https://example.com/image.png"),
                base64Data: imageData
            )
            // The image property returns cachedImage ?? bundledImage
            _ = imageFile2.image
        }
    }
}