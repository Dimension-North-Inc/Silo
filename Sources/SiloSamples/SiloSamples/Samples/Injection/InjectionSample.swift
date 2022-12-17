//
//  InjectionSample.swift
//  SiloSamples
//
//  Created by Mark Onyschuk on 2022-12-15.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Silo
import SwiftUI

// MARK: - Custom Injectables Container
private enum App {
    public static let baseURL = Injectable<URL> { URL(string: "https://api.apple.com")! }
}

// MARK: - Sample View
struct InjectionSample: View {
    @State private var uuid = UUID()
    @State private var generator = Builtins.uuid()
    
    @Injected(App.baseURL) var baseURL
    
    var body: some View {
        Form {
            Section {
                Text("`Injectable`s are values which can be used to modify behaviour of your code.")
            }
            Section("Injectable Properties") {
                Text("`@Injected(App.baseURL)` injectable")
                Text("\(baseURL)")
            }
            Section("Injectable Registration") {
                Text("`Builtin.uuid` generator configured to return random, constant, or sequential UUIDs")
                Text("\(uuid)").font(.callout)
                ControlGroup {
                    Button("Random UUID", action: useRandomUUIDs)
                    Button("Constant UUID", action: useConstantUUIDs)
                    Button("Sequential UUID", action: useSequentialUUIDs)
                }
                Button("Generate Next UUID", action: generateNextUUID)
            }
        }
        .formStyle(GroupedFormStyle())
    }
    
    private func useRandomUUIDs() {
        Builtins.uuid.reset()
        generator = Builtins.uuid()
        
        generateNextUUID()
    }
    private func useConstantUUIDs() {
        Builtins.uuid.register { .constant(UUID()) }
        generator = Builtins.uuid()

        generateNextUUID()
    }
    private func useSequentialUUIDs() {
        Builtins.uuid.register { .sequential }
        generator = Builtins.uuid()

        generateNextUUID()
    }
    
    private func generateNextUUID() {
        uuid = generator()
    }
}

struct InjectionSample_Previews: PreviewProvider {
    static var previews: some View {
        InjectionSample()
    }
}
