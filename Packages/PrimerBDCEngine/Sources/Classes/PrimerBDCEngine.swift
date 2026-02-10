//
//  PrimerBDCEngine.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import JavaScriptCore
import PrimerFoundation
import PrimerStepResolver

private enum EngineError: Error {
    case jsonToDataFailed
}

@MainActor
public final class PrimerBDCEngine: NSObject {
    let context: JSContext

    private typealias Continuation = CheckedContinuation<String, Never>
    private typealias ContinuationPath = ReferenceWritableKeyPath<PrimerBDCEngine, Continuation?>
    private typealias JSStringBlock = @convention(block) (String) -> Void
    private typealias JSVoidBlock = @convention(block) () -> Void
    
    private let encoder = JSONEncoder()
    private var isReady = false
    private var loadingContinuations: [CheckedContinuation<Void, Never>] = []
    private var initializeContinuation: Continuation?
    private var applyEventContination: Continuation?
    private var evaluateTreeContinuation: Continuation?
    private var executeActionContinuation: Continuation?
    
    override public init() {
        context = JSContext()!
        super.init()
        setupContext()
        Task { try! await setupEngine() }
    }
}

public extension PrimerBDCEngine {
    func start(schema: String, state: CodableValue) async throws -> [String: Any] {
        await checkIfReady()
        let script = initialize(schema: schema, state: try state.literal(encoder))
        return try await runScript(script, continuationPath: \.initializeContinuation)
    }
    
    func applyEvent<State: Encodable>(
        _ event: Event,
        schema: String,
        screenId: String = "first",
        state: [String: State]
    ) async throws -> [String: Any]  {
        await checkIfReady()
        let script = eventsScript(schema: schema, screenId: screenId, state: try state.literal(encoder), event: event)
        return try await runScript(script, continuationPath: \.applyEventContination)
    }
    
    func applyWorkflowStepResponse<State: Encodable>(
        schema: String,
        state: State,
        workflowId: String,
		screenId: String = "first",
        stepId: String,
        response: Data?
	) async throws  -> [String: Any] {
		await checkIfReady()
		let state = try state.literal(encoder)
		let script = actionsScript(
			schema: schema,
			screenId: screenId,
			state: state,
			workflowId: workflowId,
			stepId: stepId,
            response: response.flatMap { String(data: $0, encoding: .utf8) }
		)
        return try await runScript(script, continuationPath: \.executeActionContinuation)
    }
}

private extension PrimerBDCEngine {
    func setupContext() {
        let date = Date()
        context.exceptionHandler = { _, exception in
            fatalError(exception?.toString() ?? "Unknown exception")
        }
        context.evaluateScript(context.textCodecPolyfill)
        context.evaluateScript(context.consolePolyfill)
        
        let onReady: JSVoidBlock = { [weak self] in
            guard let self else { return }
            print("Time to load: \(Date().timeIntervalSince(date)) seconds - pending continuations: \(self.loadingContinuations.count)")
            isReady = true
            loadingContinuations.forEach { $0.resume() }
        }
        
        setupCallback(continuation: \.initializeContinuation, value: "onInitializeResult")
        setupCallback(continuation: \.applyEventContination, value: "onProcessFieldResult")
        setupCallback(continuation: \.evaluateTreeContinuation, value: "onEvaluateTreeResult")
        setupCallback(continuation: \.executeActionContinuation, value: "onExecuteActionResult")
        
        let consoleLogCallback: JSStringBlock = Logger.handleJSLog
        context.setObject(consoleLogCallback, forKeyedSubscript: "consoleLog" as NSString)
        
        let consoleErrorCallback: JSStringBlock = Logger.handleJSErr
        context.setObject(consoleErrorCallback, forKeyedSubscript: "consoleError" as NSString)

        let onLoadFailed: JSStringBlock = { fatalError($0) }
        context.setObject(onLoadFailed, forKeyedSubscript: "onLoadFailed" as NSString)
        
        context.setObject(onReady, forKeyedSubscript: "onWASMReady" as NSString)
    }
    
    func setupEngine() async throws  {
        try await evaluate { try await fetch(jsURL) }
        try await evaluate { try await fetch(stateProcessorURL) }
        
        let wasmData = try await fetch(wasmURL)
        let byteArray = [UInt8](wasmData)
        let jsByteArray = JSValue(object: byteArray, in: context)!
        
        context.setObject(jsByteArray, forKeyedSubscript: "wasmBytes" as NSString)
        context.evaluateScript(instantiate)
    }
    
    func fetch(_ urlString: String) async throws -> Data {
        let url = URL(string: urlString)!
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        return data
    }
    
    private func setupCallback(continuation: ContinuationPath, value: String) {
        let callback: JSStringBlock = { [unowned self] json in
            let continuation = self[keyPath: continuation]
            continuation?.resume(returning: json)
        }
        context.setObject(callback, forKeyedSubscript: value as NSString)
    }
}

private extension PrimerBDCEngine {
    func evaluate(_ script: () async throws -> Data) async rethrows {
        let script = String(data: try await script(), encoding: .utf8)!
        context.evaluateScript(script)
    }
    
    func checkIfReady() async {
        if !isReady { await withCheckedContinuation { loadingContinuations.append($0) } }
    }
    
    private func runScript(_ script: String, continuationPath: ContinuationPath) async throws -> AnyDict {
        await checkIfReady()
        let jsonString = await withCheckedContinuation { cont in
            self[keyPath: continuationPath] = cont
            context.evaluateScript(script)
        }
        guard let resultData = jsonString.data(using: .utf8) else { throw EngineError.jsonToDataFailed }
        return try JSONSerialization.jsonObject(with: resultData) as! AnyDict
    }
}

private extension Encodable {
    func literal(_ encoder: JSONEncoder) throws -> String {
        String(data: try encoder.encode(self), encoding: .utf8)!
    }
}

private extension Int {
    var MB: Int { self * 1024 * 1024 }
}
