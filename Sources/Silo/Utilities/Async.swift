//
//  Async.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-10-15.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

/// a function which yields a value to a parent concurrency domain
public typealias Yield<Element> = (Element)->Void

extension AsyncStream {
    /// Initializes an asynchronous stream from an async function that periodically yields results to some parent concurrency domain.
    ///
    /// The following code builds an asynchronous stream from an arbitrary `Collection`:
    /// ```swift
    ///     extension Collection {
    ///         var streamed: AsyncStream<Element> {
    ///             AsyncStream { yield in
    ///                 for element in self {
    ///                     yield(element)
    ///                 }
    ///             }
    ///         }
    ///     }
    /// ```
    /// - Parameter builder: a yielding `async` function
    public init(builder: @escaping (Yield<Element>) async -> Void) {
        self = AsyncStream {
            continuation in
            Task {
                await builder {
                    elt in
                    continuation.yield(elt)
                }
                continuation.finish()
            }
        }
    }
}

extension AsyncThrowingStream where Failure == any Error {
    /// Initializes an asynchronous stream from a throwing async function that periodically yields results to some parent concurrency domain.
    ///
    /// The following code builds an asynchronous stream from an arbitrary `Collection`:
    /// ```swift
    ///     enum StreamingError: Error {
    ///         case empty
    ///     }
    ///
    ///     extension Collection {
    ///         var nonemptyStreamed: AsyncThrowingStream<Element, Error> {
    ///             AsyncThrowingStream { yield in
    ///                 if self.isEmpty {
    ///                     throw StreamingError.empty
    ///                 }
    ///                 for element in self {
    ///                     yield(element)
    ///                 }
    ///             }
    ///         }
    ///     }
    /// ```
    /// - Parameter builder: a yielding `async throws` function
    public init(builder: @escaping (Yield<Element>) async throws -> Void) {
        self = AsyncThrowingStream {
            continuation in
            Task {
                do {
                    try await builder {
                        element in
                        continuation.yield(element)
                    }
                    continuation.finish()
                }
                catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
