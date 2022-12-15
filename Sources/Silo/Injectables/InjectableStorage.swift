//
//  InjectableStorage.swift
//  Silo
//  
//
//  Created by Mark Onyschuk on 2022-12-15.
//

#if canImport(SwiftUI)
import SwiftUI
#else
import Foundation
#endif

/// An `Injectible` value that acts as a container for data.
///
/// When an `InjectableStorage` conforming value is wrapped using the `@Injected()` property wrapper,
/// storage contents serve as the wrapper's wrapped value.
///
/// ```swift
/// enum Stores {
///     static var prefs = Factory<any InjectableContainer<Value>> {
///         // store user prefs in our cloud key/value store
///         DefaultItem.cloud("userPreferences")
///     }
/// }
///
/// struct PreferenceView: View {
///     // the injected value offers read/write access to underlying storage
///     @Injected(Stores.prefs) var prefs: UserPreferences
///
///     var body: some View {
///         List {
///             ForEach(pref, prefs) {
///                 // ...
///             }
///         }
///     }
/// }
/// ```
/// Both ``DefaultItem`` and ``KeychainItem`` conform to `InjectableStorage`
///
public protocol InjectableStorage<Value> {
    associatedtype Value: Codable
    var value: Value { get nonmutating set }
}

extension DefaultItem: InjectableStorage {}
extension KeychainItem: InjectableStorage {}

extension Injected where Value: InjectableStorage {
    public var wrappedValue: Value.Value {
        get { return injectedValue.value }
        nonmutating set { injectedValue.value = newValue }
    }
    #if canImport(swiftUI)
    public var projectedValue: Binding<Value.Value> {
        return Binding {
            return injectedValue.value
        } set: { newValue, transaciton in
            injectedValue.value = newValue
        }
    }
    #endif
}

