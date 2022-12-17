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
    public static let username = InjectableDefault<String> {
        .local("username")
    }
    
    public static let password = InjectableKeychain<String> {
        .local("password")
    }
}

// MARK: - Sample View
struct StorageInjectionSample: View {
    @State private var uuid: UUID = UUID()
    @State private var generator = Builtins.uuid()
    
    @Default(App.username, default: "") var username
    @Keychain(App.password, default: "") var password
    
    var body: some View {
        Form {
            Section {
                Text("`InjectableDefault` and `InjectableKeychain` are injectables used to store persistent data.")
            }
            Section("Default Storage") {
                TextField("User Name", text: $username)
            }
            Section("Keychain Storage") {
                SecureField("Password", text: $password)
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
