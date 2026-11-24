//
//  PrimerBDCEngine.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import JavaScriptCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

enum EngineError: Error {
    case jsonToDataFailed
    case loadFailed(String)
    case scriptFailed(String)
}

@MainActor @_spi(PrimerInternal)
public final class PrimerBDCEngine: NSObject, EngineScriptRunning {
    let context: JSContext

    private typealias JSStringBlock = @convention(block) (String) -> Void
    private typealias JSVoidBlock = @convention(block) () -> Void
    private typealias JSReplyBlock = @convention(block) (Int, String) -> Void

    private var isReady = false
    private var loadError: String?
    private var loadingContinuations: [CheckedContinuation<Void, Error>] = []
    private var continuations: [Int: CheckedContinuation<String, Never>] = [:]
    private var lastContinuationId = 0

    public convenience init(manifest: Manifest) async throws {
        try await self.init(files: EngineFilesDownloader().download(manifest))
    }

    init(files: EngineFiles) async throws {
        context = JSContext()
        super.init()
        setupContext()
        setupEngine(with: files)
        try await checkIfReady()
    }

    func run(_ script: EngineScript) async throws -> Data {
        try await checkIfReady()
        lastContinuationId += 1
        let continuationId = lastContinuationId
        let json = await withCheckedContinuation { continuation in
            continuations[continuationId] = continuation
            context.setObject(script.arguments, forKeyedSubscript: "__arguments" as NSString)
            context.evaluateScript(call(script, id: continuationId))
        }
        return Data(json.utf8)
    }
}

private extension PrimerBDCEngine {
    func setupContext() {
        let date = Date()
        context.exceptionHandler = { _, exception in Logger.handleJSErr(exception?.toString() ?? "Unknown exception") }
        context.evaluateScript(context.textCodecPolyfill)
        context.evaluateScript(context.consolePolyfill)

        let onReady: JSVoidBlock = { [weak self] in
            guard let self else { return }
            Logger.info(
                "Engine ready in \(Date().timeIntervalSince(date))s — resuming \(self.loadingContinuations.count) pending continuation(s)",
                category: "ENGINE_LIFECYCLE"
            )
            isReady = true
            loadingContinuations.forEach { $0.resume() }
        }

        let onLoadFailed: JSStringBlock = { [weak self] message in
            Logger.handleJSErr(message)
            guard let self else { return }
            loadError = message
            loadingContinuations.forEach { $0.resume(throwing: EngineError.loadFailed(message)) }
        }

        let onScriptReply: JSReplyBlock = { [weak self] continuationId, json in
            self?.continuations.removeValue(forKey: continuationId)?.resume(returning: json)
        }
        context.setObject(onScriptReply, forKeyedSubscript: "onScriptReply" as NSString)

        let consoleLogCallback: JSStringBlock = Logger.handleJSLog
        context.setObject(consoleLogCallback, forKeyedSubscript: "consoleLog" as NSString)

        let consoleErrorCallback: JSStringBlock = Logger.handleJSErr
        context.setObject(consoleErrorCallback, forKeyedSubscript: "consoleError" as NSString)

        context.setObject(onLoadFailed, forKeyedSubscript: "onLoadFailed" as NSString)

        context.setObject(onReady, forKeyedSubscript: "onWASMReady" as NSString)
    }

    func setupEngine(with files: EngineFiles) {
        context.evaluateScript(files.celWrapperJS)
        context.evaluateScript(files.stateProcessorJS)

        let byteArray = [UInt8](files.celWrapperWASM)
        let jsByteArray = JSValue(object: byteArray, in: context)

        context.setObject(jsByteArray, forKeyedSubscript: "wasmBytes" as NSString)
        context.evaluateScript(instantiate)
    }

    func checkIfReady() async throws {
        if let loadError { throw EngineError.loadFailed(loadError) }
        if !isReady { try await withCheckedThrowingContinuation { loadingContinuations.append($0) } }
    }
}
