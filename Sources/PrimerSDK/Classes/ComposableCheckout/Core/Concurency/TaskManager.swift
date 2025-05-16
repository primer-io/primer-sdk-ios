//
//  TaskManager.swift
//
//
//  Created by Boris on 31.3.25..
//

import Foundation

/// An actor‑based task manager to track and cancel async tasks.
@available(iOS 15.0, *)
actor TaskManager {
    private var tasks = [UUID: Task<Void, Never>]()

    /// Starts and tracks a new task.
    @discardableResult
    func startTask(
        priority: TaskPriority? = nil,
        operation: @escaping () async -> Void
    ) -> UUID {
        let id = UUID()
        let task = Task(priority: priority) {
            await operation()
            self.removeTask(id: id)
        }
        tasks[id] = task
        return id
    }

    /// Cancels a specific task.
    func cancelTask(id: UUID) {
        tasks[id]?.cancel()
        tasks[id] = nil
    }

    /// Cancels all active tasks.
    func cancelAllTasks() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
    }

    /// Checks if a task with the given ID is still active.
    func isTaskActive(id: UUID) -> Bool {
        return tasks[id] != nil
    }

    /// Removes a task from tracking.
    func removeTask(id: UUID) {
        tasks[id] = nil
    }

    deinit {
        // Dispatch cancellation asynchronously in deinit.
        Task.detached { [weak self] in
            await self?.cancelAllTasks()
        }
    }
}
