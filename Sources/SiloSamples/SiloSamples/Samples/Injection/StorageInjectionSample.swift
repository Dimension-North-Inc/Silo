//
//  StorageInjectionSample.swift
//  SiloSamples
//
//  Created by Mark Onyschuk on 2022-12-15.
//  Copyright © 2022 Dimension North Inc. All rights reserved.
//

import Silo
import SwiftUI

// MARK: - Custom Injectables Container
private enum App {
    public static let userName = Injectable<any InjectableStorage> {
        DefaultItem<String>.local("username")
    }
}

// MARK: - Sample View
struct StorageInjectionSample: View {
    @State private var uuid: UUID = UUID()
    @State private var generator: UUIDGenerator = Builtins.uuid()
    
    @Injected(App.userName) var userName
    
    var body: some View {
        Form {
            Section {
                Text("`InjectableStorage` is an injectable value used to store persistent data. Storage for user defaults, iCloud key/value stores, and the keychain are provided.")
            }
        }
        .formStyle(GroupedFormStyle())
    }
}

struct StorageInjectionSample_Previews: PreviewProvider {
    static var previews: some View {
        StorageInjectionSample()
    }
}
