#if !os(Linux)

import Foundation
import CoreData

package extension NSManagedObjectContext {
    var dispatcher: CoreDataDispatcher {
        return CoreDataDispatcher(self)
    }
}

/// A `Dispatcher` that dispatches onto the threads associated with
/// `NSManagedObjectContext`s, allowing Core Data operations to be
/// handled using promises.

package struct CoreDataDispatcher: Dispatcher {

    let context: NSManagedObjectContext

    package init(_ context: NSManagedObjectContext) {
        self.context = context
    }

    package func dispatch(_ body: @escaping () -> Void) {
        context.perform(body)
    }

}

#endif
