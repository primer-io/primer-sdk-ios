//
//  JSContextPolyfillTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import JavaScriptCore
@testable import PrimerBDCEngine
import XCTest

final class JSContextPolyfillTests: XCTestCase {

    private let context = JSContext()!

    func testTextEncoderPolyfillRegistersGlobals() {
        context.evaluateScript(context.textCodecPolyfill)
        
        let hasEncoder = context.evaluateScript("typeof TextEncoder !== 'undefined'")!
        let hasDecoder = context.evaluateScript("typeof TextDecoder !== 'undefined'")!

        XCTAssertTrue(hasEncoder.toBool())
        XCTAssertTrue(hasDecoder.toBool())
    }

    func testTextEncoderEncodesASCII() {
        context.evaluateScript(context.textCodecPolyfill)

        let result = context.evaluateScript("""
            const encoded = new TextEncoder().encode("hello");
            Array.from(encoded).join(",");
        """)

        let helloInAscii = "104,101,108,108,111"
        XCTAssertEqual(result?.toString(), helloInAscii)
    }

    func testTextDecoderDecodesASCII() {
        context.evaluateScript(context.textCodecPolyfill)

        let result = context.evaluateScript("""
            const helloBytes = new Uint8Array([104, 101, 108, 108, 111]);
            new TextDecoder().decode(helloBytes);
        """)

        XCTAssertEqual(result?.toString(), "hello")
    }

    func testTextEncoderDecoderRoundTrip() {
        context.evaluateScript(context.textCodecPolyfill)

        let result = context.evaluateScript("""
            const original = "test string 123";
            const encoded = new TextEncoder().encode(original);
            const decoded = new TextDecoder().decode(encoded);
            decoded;
        """)

        XCTAssertEqual(result?.toString(), "test string 123")
    }

    func testConsolePolyfillRegistersConsoleObject() {
        context.evaluateScript(context.consolePolyfill)

        let hasLog = context.evaluateScript("typeof console.log === 'function'")!
        let hasWarn = context.evaluateScript("typeof console.warn === 'function'")!
        let hasError = context.evaluateScript("typeof console.error === 'function'")!

        XCTAssertTrue(hasLog.toBool())
        XCTAssertTrue(hasWarn.toBool())
        XCTAssertTrue(hasError.toBool())
    }

    func testConsoleLogCallsNativeCallback() {
        assertConsole(
            console: "consoleLog",
            script: "console.log('hello from JS')",
            expecting: "hello from JS"
        )
    }

    func testConsoleErrorCallsNativeCallback() {
        assertConsole(
            console: "consoleError",
            script: "console.error('something broke')",
            expecting: "something broke"
        )
    }
}

private extension JSContextPolyfillTests {
    func assertConsole(
        console: String,
        script: String,
        expecting expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        context.evaluateScript(context.consolePolyfill)

        let expectation = expectation(description: "console")
        let callback: @convention(block) (String) -> Void = { message in
            XCTAssertTrue(message.contains(expected))
            expectation.fulfill()
        }
        
        context.setObject(callback, forKeyedSubscript: console as NSString)
        context.evaluateScript(script)
        waitForExpectations(timeout: 1.0)
    }
}
