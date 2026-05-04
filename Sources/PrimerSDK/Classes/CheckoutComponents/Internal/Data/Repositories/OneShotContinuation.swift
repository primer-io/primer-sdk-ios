//
//  OneShotContinuation.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Thread-safe one-shot wrapper for CheckedContinuation to prevent double-resume crashes.
@available(iOS 15.0, *)
final class OneShotContinuation<T>: @unchecked Sendable {
  private var continuation: CheckedContinuation<T, Error>?
  private let lock = NSLock()

  init(_ continuation: CheckedContinuation<T, Error>) {
    self.continuation = continuation
  }

  deinit {
    lock.lock()
    let cont = continuation
    continuation = nil
    lock.unlock()
    cont?.resume(throwing: CancellationError())
  }

  func resume(returning value: T) {
    lock.lock()
    let cont = continuation
    continuation = nil
    lock.unlock()
    cont?.resume(returning: value)
  }

  func resume(throwing error: Error) {
    lock.lock()
    let cont = continuation
    continuation = nil
    lock.unlock()
    cont?.resume(throwing: error)
  }

  func resume(with result: Result<T, Error>) {
    switch result {
    case let .success(value):
      resume(returning: value)
    case let .failure(error):
      resume(throwing: error)
    }
  }
}
