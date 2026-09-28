//
//  PrimerBDCEngine.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import CryptoKit
import JavaScriptCore
@_spi(PrimerInternal) import PrimerFoundation
import PrimerStepResolver

private enum EngineError: Error {
    case badUrl
    case badStatus(Int)
    case jsonToDataFailed
    case scriptFailed(String)
    case sha256Mismatch
}

@MainActor @_spi(PrimerInternal)
public final class PrimerBDCEngine: NSObject, BDCEngineProtocol {
    let context: JSContext

    private typealias Continuation = CheckedContinuation<String, Never>
    private typealias ContinuationPath = ReferenceWritableKeyPath<PrimerBDCEngine, Continuation?>
    private typealias JSStringBlock = @convention(block) (String) -> Void
    private typealias JSVoidBlock = @convention(block) () -> Void
    
    private let urlSession: URLSession
    private let manifest: Manifest
    private let encoder = JSONEncoder()
    private var isReady = false
    private var loadingContinuations: [CheckedContinuation<Void, Never>] = []
    private var initializeContinuation: Continuation?
    private var applyEventContinuation: Continuation?
    private var evaluateTreeContinuation: Continuation?
    private var executeActionContinuation: Continuation?
    private var checkRequirementsContinuation: Continuation?

    private static let downloadAttempts = 3

    public init(manifest: Manifest) async throws  {
        self.manifest = manifest
        context = JSContext()
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 20_000_000)
        self.urlSession = URLSession(configuration: sessionConfiguration)
        super.init()
        setupContext()
        try await setupEngine()
    }
}

public extension PrimerBDCEngine {
    func start(schema: String, context: SDKContext, state: CodableValue) async throws -> [String: Any] {
        await checkIfReady()
        let script = initialize(schema: schema, context: try context.literal(encoder), state: try state.literal(encoder))
        return try await runScript(script, continuationPath: \.initializeContinuation)
    }
    
    func applyEvent<State: Encodable>(
        _ event: CodableValue,
        context: SDKContext,
        schema: String,
        state: State
    ) async throws -> [String: Any]  {
        await checkIfReady()
        let script = eventScript(
            schema: schema,
            context: try context.literal(encoder),
            state: try state.literal(encoder),
            event: try event.jsonString
        )
        return try await runScript(script, continuationPath: \.applyEventContinuation)
    }
    
    func applyResult(
        schema: String,
        context: SDKContext,
        actionId: String,
        state: CodableState,
        outcome: String,
        data: Data?
    ) async throws  -> [String: Any] {
        await checkIfReady()
        let script = resultScript(
            schema: schema,
            context: try context.literal(encoder),
            actionId: actionId,
            state: try state.literal(encoder),
            outcome: outcome,
            data: data.flatMap { String(data: $0, encoding: .utf8) }
        )
        return try await runScript(script, continuationPath: \.executeActionContinuation)
    }

    func checkClientRequirements(
        items: [ClientRequirementsItem],
        client: BDCClient
    ) async throws -> ClientRequirementsVerdicts {
        await checkIfReady()
        let script = checkClientRequirementsScript(items: try items.literal(encoder), client: try client.literal(encoder))
        return try await decodedResult(of: script, continuationPath: \.checkRequirementsContinuation)
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
        
        setupCallback(continuation: \.initializeContinuation, value: "onInitializeResult")
        setupCallback(continuation: \.applyEventContinuation, value: "onProcessFieldResult")
        setupCallback(continuation: \.evaluateTreeContinuation, value: "onEvaluateTreeResult")
        setupCallback(continuation: \.executeActionContinuation, value: "onExecuteActionResult")
        setupCallback(continuation: \.checkRequirementsContinuation, value: "onCheckClientRequirementsResult")

        let consoleLogCallback: JSStringBlock = Logger.handleJSLog
        context.setObject(consoleLogCallback, forKeyedSubscript: "consoleLog" as NSString)
        
        let consoleErrorCallback: JSStringBlock = Logger.handleJSErr
        context.setObject(consoleErrorCallback, forKeyedSubscript: "consoleError" as NSString)

        let onLoadFailed: JSStringBlock = Logger.handleJSErr
        context.setObject(onLoadFailed, forKeyedSubscript: "onLoadFailed" as NSString)
        
        context.setObject(onReady, forKeyedSubscript: "onWASMReady" as NSString)
    }
    
    // Downloaded together, evaluated in order.
    func setupEngine() async throws  {
        async let celWrapper = download(manifest.celWrapperJSURLContainer.url, sha256: manifest.celWrapperJSURLContainer.sha256)
        async let stateProcessor = download(manifest.stateProcessorContainer.url, sha256: manifest.stateProcessorContainer.sha256)
        async let wasm = download(manifest.celWrapperWASMURLContainer.br, sha256: manifest.celWrapperWASMURLContainer.sha256)
        let (celWrapperScript, stateProcessorScript, wasmData) = try await (celWrapper, stateProcessor, wasm)

        context.evaluateScript(String(data: celWrapperScript, encoding: .utf8))
        context.evaluateScript(String(data: stateProcessorScript, encoding: .utf8))

        let byteArray = [UInt8](wasmData)
        let jsByteArray = JSValue(object: byteArray, in: context)

        context.setObject(jsByteArray, forKeyedSubscript: "wasmBytes" as NSString)
        context.evaluateScript(instantiate)
    }

    // A failed download is tried again; a hash mismatch is not, the same bytes would come back.
    func download(_ urlString: String, sha256: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw EngineError.badUrl }
        var attempt = 1
        while true {
            do {
                return try await fetch(url, sha256: sha256)
            } catch EngineError.sha256Mismatch {
                throw EngineError.sha256Mismatch
            } catch where attempt < Self.downloadAttempts {
                try await Task.sleep(nanoseconds: UInt64(attempt) * 300_000_000)
                attempt += 1
            }
        }
    }

    func fetch(_ url: URL, sha256: String) async throws -> Data {
        let (data, response) = try await urlSession.data(for: URLRequest(url: url))
        if let status = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(status) {
            throw EngineError.badStatus(status)
        }
        let digest = SHA256.hash(data: data)
        let computedSHA256 = Data(digest).base64EncodedString()
        guard computedSHA256 == sha256 else { throw EngineError.sha256Mismatch }
        return data
    }
    
    private func setupCallback(continuation: ContinuationPath, value: String) {
        let callback: JSStringBlock = { [weak self] json in
            guard let self else { return }
            let continuation = self[keyPath: continuation]
            continuation?.resume(returning: json)
        }
        context.setObject(callback, forKeyedSubscript: value as NSString)
    }
}

private extension PrimerBDCEngine {
    func checkIfReady() async {
        if !isReady { await withCheckedContinuation { loadingContinuations.append($0) } }
    }

    private func runScript(_ script: String, continuationPath: ContinuationPath) async throws -> AnyDict {
        let jsonString = await result(of: script, continuationPath: continuationPath)
        guard
            let data = jsonString.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data, options: []) as? AnyDict
        else { throw EngineError.jsonToDataFailed }
        return object
    }

    // For scripts that answer `{ result }` or `{ error }`.
    private func decodedResult<Value: Decodable>(of script: String, continuationPath: ContinuationPath) async throws -> Value {
        guard let data = await result(of: script, continuationPath: continuationPath).data(using: .utf8) else {
            throw EngineError.jsonToDataFailed
        }
        let reply = try JSONDecoder().decode(ScriptReply<Value>.self, from: data)
        guard let value = reply.result else { throw EngineError.scriptFailed(reply.error ?? "No result") }
        return value
    }

    private func result(of script: String, continuationPath: ContinuationPath) async -> String {
        await checkIfReady()
        return await withCheckedContinuation { cont in
            self[keyPath: continuationPath] = cont
            context.evaluateScript(script)
        }
    }
}

private struct ScriptReply<Value: Decodable>: Decodable {
    let result: Value?
    let error: String?
}

private extension Encodable {
    func literal(_ encoder: JSONEncoder) throws -> String {
        guard let literal = String(data: try encoder.encode(self), encoding: .utf8) else {
            throw EncodableError.literalEncodingFailed
        }
        return literal
    }
}

enum EncodableError: Error {
    case literalEncodingFailed
}
