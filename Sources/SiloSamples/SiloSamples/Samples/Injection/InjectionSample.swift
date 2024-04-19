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
private enum API {
    public static let baseURL = Injectable<URL> { URL(string: "https://api.apple.com")! }
}

// MARK: - Sample View
struct InjectionSample: View {
    @Injected(API.baseURL) var baseURL
    
    enum GeneratorType: String, CaseIterable, Identifiable {
        case random
        case constant
        case sequential

        var id: Self { self }
    }

    @State private var uuid = UUID()
    @State private var generator = Builtins.uuid()
    @State private var selectedGenerator: GeneratorType = .random
    
    private func updateGenerator() {
        switch selectedGenerator {
        case .random:
            Builtins.uuid.reset()
        case .constant:
            Builtins.uuid.register { .constant(UUID()) }
        case .sequential:
            Builtins.uuid.register { .sequential }
        }
        
        generator = Builtins.uuid()
        generateNextUUID()
    }
    
    var body: some View {
        Form {
            Section {
                Text("`Injectable`s are values which can be used to modify behaviour of your code.")
            }
            Section("Injectable Properties") {
                Text("`@Injected(API.baseURL)` injectable")
                Text("\(baseURL)")
            }
            Section("Injectable Registration") {
                Text("`Builtins.uuid` generator configured to return random, constant, or sequential UUIDs")
                Text("\(uuid)").font(.callout)
                
                Picker("UUID Generator", selection: $selectedGenerator) {
                    ForEach(GeneratorType.allCases) {
                        Text($0.rawValue.capitalized)
                            .tag($0)
                    }
                }.onChange(of: selectedGenerator) { _ in
                    updateGenerator()
                }
                
                Button("Generate Next UUID", action: generateNextUUID)
            }
        }
        .formStyle(GroupedFormStyle())
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
