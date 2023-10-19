//
//  Projection.swift
//  Silo
//
//  Created by Mark Onyschuk on 09/26/23.
//  Copyright © 2023 Dimension North Inc. All rights reserved.
//

import SwiftUI

struct StoresKey: EnvironmentKey {
    // [OID( Reducer ): Store<Reducer> ]
    public static var defaultValue: [ObjectIdentifier: Any] = [:]
}

extension EnvironmentValues {
    var stores: [ObjectIdentifier: Any] {
    get { self[StoresKey.self] }
    set { self[StoresKey.self] = newValue }
  }
}

/// Types which present a `Projection` of Silo  `State`.
///
/// Silo `State` is often written in a way to optimize access or to normalize
/// away duplication across a state hierarchy, rather than to be easily understandable.
///
/// To hide implementation details surrounding state structure, create projections of
/// state that are easier to understand and use.
///
/// - Note: Projections created to serve a particular custom SwiftUI View
/// are often called `ViewModels`.
///
public protocol Projection<Reducer> {
    associatedtype Reducer where Reducer: Silo.Reducer
    
    init(store: Store<Reducer>)
}


/// A SwiftUI View that creates and connects a `Projection` with its underlying `Store`.
/// The projection is made available within the projected view `body.`
public struct Projected<Projection, Content>: View where Projection: Silo.Projection & ObservableObject, Content: View {
    
    public typealias ProjectedContent = (Binding<Projection>)->Content
    
    @Environment(\.stores) private var stores

    @State private var projection: Projection?
    private var content: ProjectedContent

    private struct Container: View {
        var content: ProjectedContent
        @StateObject var projection: Projection
        
        var body: some View {
            content(.constant(projection))
        }
        
        init(content: @escaping ProjectedContent, projection: Projection) {
            self.content = content
            self._projection = StateObject(wrappedValue: projection)
        }
    }
    
    /// Initializes the projection.
    /// - Parameters:
    ///   - projection: the type of projection to create
    ///   - content: the projected view body which can access the projection.
    public init(_ projection: Projection.Type, @ViewBuilder content: @escaping ProjectedContent) {
        self.content = content
    }
    
    public var body: some View {
        if let projection {
            Container(content: content, projection: projection)
        } else {
            Color.clear.task {
                if let store = stores[ObjectIdentifier(Projection.Reducer.self)] as? Store<Projection.Reducer> {
                    projection = Projection(store: store)
                }
            }
        }
    }
}

/// A view modifier used to register Silo `Stores` that can be accessed via a `Projection` in child views.
public struct ProjectModifier<Reducer>: ViewModifier where Reducer: Silo.Reducer {
    @Environment(\.stores) var stores
    
    private var value: Store<Reducer>
    
    /// Initializes the modifier with a `Store` to register.
    /// - Parameter value: <#value description#>
    public init(_ value: Store<Reducer>) {
        self.value = value
    }
    
    public func body(content: Content) -> some View {
        content.environment(
            \.stores,
             stores.merging(
                [ObjectIdentifier(Reducer.self): value],
                uniquingKeysWith: { old, new in new }
             )
        )
    }
}

extension View {
    /// Register a Silo `Store` to be accessed via `Projections` in child views.
    /// - Parameter store: a `Store` that child views may want to project
    /// - Returns: a modified view.
    public func project<R>(_ store: Store<R>) -> some View where R: Silo.Reducer {
        self.modifier(ProjectModifier(store))
    }
}
