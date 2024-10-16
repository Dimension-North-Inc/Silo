//
//  RepeatingEffectsSample.swift
//  SiloSamples
//
//  Created by Mark Onyschuk on 2022-11-06.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Silo
import SwiftUI

// MARK: - Reducer
struct Ticker: Reducer {
    struct State: States {
        var value: Int = 0
        var tickerID: EffectID? = nil
    }
    enum Action: Actions {
        case tick
        case startTicking
        case finishTicking
    }
    
    var body: some Reducer<State, Action> {
        Reduce {
            state, action in
            
            switch action {
            case .tick where state.tickerID != nil:
                /// - NOTE: effects are asynchronous and cooperative, cancelling them isn't guaranteed
                /// to stop them immediately, so an in-flight `.tick` action may be sent through the reducer
                /// even after a `.finishTicking` event has been processed.
                ///
                /// This is a race condition, so to ensure that we're async-safe, we only act on a `.tick`
                /// if  `tickerID` hasn't since been set to `nil`.
                state.value += 1

            case .startTicking where state.tickerID == nil:
                /// We start ticking if we're not already doing so.
                ///
                /// To cause multiple `.tick` actions to be sent, we return an async side-effect
                /// that returns `many` actions.
                
                state.tickerID = .unique
                
                return Effect.many {
                    send in
                    send(Action.tick)
                    while true {
                        try? await Task.sleep(for: .seconds(1))
                        send(Action.tick)
                    }
                }
                /// we make this effect *cancellable* using an EffectID
                /// which we've stored in `state`.
                .cancelled(using: state.tickerID)
                
            case .finishTicking where state.tickerID != nil:
                /// To cancel an existing ticker, we cancel based on ticker name `state.tickerID`.
                defer { state.tickerID = nil }
                return Effect.cancel(state.tickerID)

            default:
                break
            }
            
            // no side effects
            return .none
        }
    }
}

// MARK: - Sample View
struct RepeatingEffectsSample: View {
    @StateObject
    private var ticker = Store(Ticker(), state: Ticker.State())
    
    var body: some View {
        Form {
            Section {
                Text("`Effect`s are asynchronous functions which generate `Actions`. Their lifetime is limited to the lifetime of their associated `Store`s.")
            }
            Section {
                Text("\(ticker.value)")
                Button {
                    ticker.dispatch(.startTicking)
                } label: {
                    Text("Start")
                }
                Button {
                    ticker.dispatch(.finishTicking)
                } label: {
                    Text("Finish")
                }
            }
        }
        .formStyle(GroupedFormStyle())

    }
}

struct RepeatingEffects_Previews: PreviewProvider {
    static var previews: some View {
        RepeatingEffectsSample()
    }
}
