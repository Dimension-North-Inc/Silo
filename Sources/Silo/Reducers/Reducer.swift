//
//  Reducer.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-11-01.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Foundation

/// Application state which evolves over time.
///
/// States represent an application's configuration at some snapshot in time:
///
/// ```swift
/// struct TickerState: States {
///     var timer: String
///     var numberOfTicks: Int
/// }
/// ```
public typealias States = Sendable

/// An abstract behavor which may cause application state to change.
///
/// Actions represent both user interactions as well as points in an application's lifecycle.
/// A user's button tap which adds a TODO item to a list of TODOs can be modeled as an action.
/// Similarly, application launch, a ticking timer, or the presentation of a new window can be
/// modeled as actions.
///
/// ```swift
/// enum TickerAction: Actions {
///     case tick // a tick
///     case stopTicking // stop ticking
///     case startTicking(timer: String) // start ticking
/// }
/// ```
public typealias Actions = Sendable

/// A type with describes how application `State` evolves over time in response to `Actions`.
///
/// Reducers encapsulate application logic in a `reduce(state:action:)` where they modify
/// `State` and return optional asynchronous `Action` generating `Effect`s as result of the
/// `Action`s they receive:
///
/// ```swift
/// struct Ticker: Reducer {
///     struct State: States {
///         var timer: String?
///         var numberOfTicks: Int
///     }
///     enum Action: Actions {
///         case tick
///         case stopTicking
///         case startTicking(timer: String)
///     }
///     func reduce(state: inout State, action: Action) -> Effect<Action>? {
///         switch action {
///         case .tick:
///             if state.timer != nil {
///                 state.numberOfTicks += 1
///             }
///             return .none
///
///         case .stopTicking:
///             defer { state.timer = nil }
///             return Effects.cancel(state.timer)
///
///         case .startTicking(let timer):
///             state.timer = timer
///             return Effect.many {
///                 emit in
///                 while true {
///                     try? await Task.sleep(for: .seconds(1))
///                     emit(.tick)
///                 }
///             }
///             .cancelled(using: state.timer)
///         }
///     }
/// }
/// ```
///
public protocol Reducer<State, Action> {
    /// reducer-native state
    associatedtype State: States
    
    /// reducer-native actions
    associatedtype Action: Actions
    
    /// Reduces `state` as result of receiving a reducer-native `action`.
    ///
    /// - Parameters:
    ///   - state: reducer-native state
    ///   - action: a reducer-native action
    /// - Returns: an optional effect associated with the received action
    func reduce(state: inout State, action: Action) -> Effect<Action>?
    
    // NB: For Xcode to favor autocompleting `var body: Body` over `var body: Never` we must use a
    //     type alias. We compile it out of release because this workaround is incompatible with
    //     library evolution.
    #if DEBUG
      associatedtype _Body

      /// A type representing the body of this reducer.
      ///
      /// When you create a custom reducer by implementing the ``body-swift.property-7foai``, Swift
      /// infers this type from the value returned.
      ///
      /// If you create a custom reducer by implementing the ``reduce(into:action:)-8yinq``, Swift
      /// infers this type to be `Never`.
      typealias Body = _Body
    #else
      /// A type representing the body of this reducer.
      ///
      /// When you create a custom reducer by implementing the ``body-swift.property-7foai``, Swift
      /// infers this type from the value returned.
      ///
      /// If you create a custom reducer by implementing the ``reduce(into:action:)-8yinq``, Swift
      /// infers this type to be `Never`.
      associatedtype Body
    #endif


    /// Compose reducer logic declaratively with a `body` declaration.
    ///
    /// Reducers can describe their behavior in either of two ways.
    ///
    /// They can implement a `reduce(state:action:)` method, or they can provide a `body` declaration
    /// which allows both basic reducer behaviour as well as reducer composition:
    ///
    /// ```swift
    /// public var body: some Reducer<State, Action> {
    ///     Trace { // use a trace reducer to log actions and state changes
    ///         Reduce { // use a block reducer to process local state reduction
    ///             state, action in
    ///
    ///             // local reducer logic goes here...
    ///             return .none
    ///         }
    ///
    ///         // if the reducer's state contains substates managed by other
    ///         // reducers, then they can be included in the composition here...
    ///     }
    /// }
    /// ```
    @ReducerBuilder<State, Action>
    var body: Body { get }
}

extension Reducer where Body == Never {
    public var body: Body {
        fatalError()
    }
}

extension Reducer where Body: Reducer, Body.State == Self.State, Body.Action == Self.Action {
    
    /// Where `body` is defined, forward `reduce` reqiuests to the body
    /// - Parameters:
    ///   - state: reducer-native state
    ///   - action: reducer-native action
    /// - Returns: an optional effect associated with the received action
    public func reduce(state: inout State, action: Action) -> Effect<Action>? {
        return body.reduce(state: &state, action: action)
    }
}

extension Reducer where State: Identifiable {
    /// where state is `Identifiable` provide `Reducer.ID` as an alias for `Reducer.State.ID`
    public typealias ID = State.ID
}

/// TODO: Document this
public protocol SubstateReducer: Reducer {}
