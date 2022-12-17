//
//  Injectables.swift
//  Silo
//
//  Created by Mark Onyschuk on 2022-12-14.
//  Copyright © 2022 Dimension North Inc. All rights reserved.

// Factory.swift
//
// GitHub Repo and Documentation: https://github.com/hmlongco/Factory
//
// Copyright ©2022 Michael Long. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/// An injectable dependency
///
/// Conceptually, an `Injectable` is a value  that you want to `inject` into other code at runtime, rather than hard code at compile time.
/// `Injectables` can be values, classes, or functions that - when injected into other code - cause that code to behave differently.
///
/// **Use Injectables to make your code more testable:**
///
/// Networking code that accesses a remote server in a running application can
/// be replaced by injecting a stub that doesn't actually access the remote server, but instead returns a predetermined result - either some data, or
/// a simulated networking failure. By controlling network responses, you can write tests to ensure your code can handle hard-to-reproduce
/// networking conditions and replies.
///
///```swift
/// func processUsers() async throws {
///     @Injected(API.getUsers) var getUsers
///     let users = try await getUsers()
///     //...
/// }
///```
/// **Use Injectables to make using Xcode previews easier:**
///
/// Substitute data displayed in a running application with data meant to be displayed in an Xcode preview instead using an injectable.
///
///```swift
/// struct ProductList_Previews: PreviewProvider {
///     static var previews: some View {
///         let _ = API.getProducts.register { query in
///             return [
///                 Product("Beets"),
///                 Product("Fish"),
///             ]
///         }
///         ProductList()
///     }
/// }
///```
///
/// **Use Injectables to make your applications more flexible:**
///
/// Specialize your code for particular users or marketplaces by injecting premium features in place of basic features in an in-app purchasable
/// application; or by injecting code that interacts with either the Apple App Store, or third party stores like Paddle, depending upon where the app is sold.
///
///```swift
/// func enablePremiumFeatures() async throws {
///     Features.gameModes.register {
///         premiumGameModes()
///     }
///     Features.purchaseablePowerups.register { user in
///         premiumPowerupsFor(user)
///     }
///     //...
/// }
///```
///
public struct Injectable<Value> where Value: Sendable {
    /// Initializes an Injectable with a factory closure that returns a new instance of the desired type.
    public init(factory: @escaping () -> Value) {
        self.registration = InjectionRegistration<Void, Value>(factory: factory, scope: nil)
    }
    
    /// Initializes a scoped Injectable with a factory closure that returns a new instance of the desired type.
    public init(scope: InjectionScope, factory: @escaping () -> Value) {
        self.registration = InjectionRegistration<Void, Value>(factory: factory, scope: scope)
    }
    
    /// Resolves and returns an instance of the desired value type.
    ///
    /// The result may be new, or created previously  then cached,  depending upon  whether or not a scope was specified when the injectable was created.
    public func callAsFunction() -> Value {
        registration.resolve(())
    }
    
    /// Registers a new factory closure used to create and return an instance of the desired value
    ///
    /// This registration overrides the original factory and its result will be returned on all new object resolutions.
    /// Registering a new factory also clears the previous instance from the associated scope.
    public func register(factory: @escaping () -> Value) {
        registration.register(factory: factory)
    }
    
    /// Resets a factory closure override, replacing it with the Injectable's original factory.
    public func reset() {
        registration.reset()
    }
    
    private let registration: InjectionRegistration<Void, Value>
}

/// A parameterized injectable dependency
///
/// Conceptually, an `Injectable` is a value  that you want to `inject` into other code at runtime, rather than hard code at compile time.
/// `Injectables` can be values, classes, or functions that - when injected into other code - cause that code to behave differently.
///
/// **Passing Parameters**
///
/// A `ParameterizedInjectable` allows you to pass parameters to specialize the value you retrieve. Consider an injectable logging
/// system `.logger` whose behavior varies based on where the logging originates in code:
///
/// ```swift
/// // a named injectable dependency container
/// enum Dependencies {
///     static var logger: ParameterizedFeature<Logger> = ParameterizedFeature { subsystemLabel in
///         ConsoleLogger(prefix: subsystemLabel)
///     }
/// }
///
/// // an application subsystem
/// struct ComputeEngine {
///     // inject our logger
///     var log = Dependencies.logger("COMPUTE")
///
///     // do work and log progress
///     func doCompute() {
///         log("BEEP! BOOP! WHIRR!") // logs "COMPUTE: BEEP! BOOP! WHIRR!" to console
///
///         // ...
///     }
/// }
/// ```

public struct ParameterizedInjectable<Parameters, Value> where Parameters: Sendable, Value: Sendable {
    
    /// Initializes an Injectable with a factory closure that returns a new instance of the desired type.
    public init(factory: @escaping (_ params: Parameters) -> Value) {
        self.registration = InjectionRegistration<Parameters, Value>(factory: factory, scope: nil)
    }
    
    /// Initializes with factory closure that returns a new instance of the desired type. The scope defines the lifetime of that instance.
    public init(scope: InjectionScope, factory: @escaping (_ params: Parameters) -> Value) {
        self.registration = InjectionRegistration<Parameters, Value>(factory: factory, scope: scope)
    }
    
    /// Resolves and returns an instance of the desired object type. This may be a new instance or one that was created previously and then cached,
    /// depending on whether or not a scope was specified when the factory was created.
    ///
    /// Note return type of `Value` could still be `<Value?>` depending on original Factory specification.
    public func callAsFunction(_ params: Parameters) -> Value {
        registration.resolve(params)
    }
    
    /// Registers a new factory that will be used to create and return an instance of the desired object type.
    ///
    /// This registration overrides the original factory and its result will be returned on all new object resolutions. Registering a new
    /// factory also clears the previous instance from the associated scope.
    ///
    /// All registered factories are stored in SharedContainer.Registrations.
    public func register(factory: @escaping (_ params: Parameters) -> Value) {
        registration.register(factory: factory)
    }
    
    /// Deletes any registered factory override and resets this Factory to use the factory closure specified during initialization. Also
    /// resets the scope so that a new instance of the original type will be returned on the next resolution.
    public func reset() {
        registration.reset()
    }
    
    private let registration: InjectionRegistration<Parameters, Value>
}

/// An injection scope.
///
/// Injection scopes define the lifetime of an injected value. By default, injected values are recalculated each time they are resolved,
/// but other lifetimes exist. Builtin scopes include `.cached`, `.shared`, or `.singleton`. Refer to documentation for each for details.
///
/// **Using Scopes:**
///
/// To scope your injectable, pass the scope as a parameter when declaring it:
///
/// ```swift
/// // injectable services
/// enum Services {
///     static var logger = Injectable<any Logger>(scope: .singleton) {
///         return ConsoleLogger()
///     }
///
///     // ...
/// }
/// ```
public class InjectionScope {
    fileprivate init() {
        defer { lock.unlock() }
        lock.lock()
        Self.scopes.append(self)
    }
    
    /// Resets the cache. Any factory using this cache will return a new instance after the cache is reset.
    public func reset() {
        defer { lock.unlock() }
        lock.lock()
        cache = [:]
    }
    
    /// Public query mechanism for cache empty
    public var isEmpty: Bool {
        defer { lock.unlock() }
        lock.lock()
        return cache.isEmpty
    }
    
    /// Internal cache resolution function used by Factory Registration
    fileprivate func resolve<Value>(id: UUID, factory: () -> Value) -> Value {
        defer { lock.unlock() }
        lock.lock()
        if let box = cache[id] {
            if let instance = box.instance as? Value {
                if let optional = instance as? OptionalType {
                    if optional.hasWrappedValue {
                        return instance
                    }
                } else {
                    return instance
                }
            }
        }
        let instance: Value = factory()
        if let box = box(instance) {
            cache[id] = box
        }
        return instance
    }
    
    /// Internal reset function used by Factory
    fileprivate func reset(_ id: UUID) {
        defer { lock.unlock() }
        lock.lock()
        cache.removeValue(forKey: id)
    }
    
    /// Internal function correctly boxes cache value depending upon scope type
    fileprivate func box<Value>(_ instance: Value) -> AnyBox? {
        if let optional = instance as? OptionalType {
            return optional.hasWrappedValue ? StrongBox<Value>(boxed: instance) : nil
        } else {
            return StrongBox<Value>(boxed: instance)
        }
    }
    
    private var lock = Mutex(recursive: true)
    private var cache: [UUID: AnyBox] = .init(minimumCapacity: 64)

    
    /// A cached scope.
    ///
    /// An Injectable scoped `.cached` will resolve to the same value each time, until the cache is reset.
    public static let cached = Cached()
    public final class Cached: InjectionScope {
        public override init() {
            super.init()
        }
    }
    
    /// A weakly shared scope
    ///
    /// An Injectable scoped `.shared` will resolve to the same value each time so long as an instance remains in use.
    /// Once all instances are released, then `.shared` injectables resolve to a new value.
    public static let shared = Shared()
    public final class Shared: InjectionScope {
        public override init() {
            super.init()
        }
        fileprivate override func box<Value>(_ instance: Value) -> AnyBox? {
            if let optional = instance as? OptionalType {
                if let unwrapped = optional.wrappedValue, type(of: unwrapped) is AnyObject.Type {
                    return WeakBox(boxed: unwrapped as AnyObject)
                }
            } else if type(of: instance as Any) is AnyObject.Type {
                return WeakBox(boxed: instance as AnyObject)
            }
            return nil
        }
    }
    
    /// A singleton scope
    ///
    /// An Injectable scoped `.singleton` will always resolve to the same value.
    public static let singleton = Singleton()
    public final class Singleton: InjectionScope {
        public override init() {
            super.init()
        }
    }
    
    /// Resets all scope caches.
    public static func reset(includeSingletons: Bool = false) {
        Self.scopes.forEach {
            if !($0 is Singleton) || includeSingletons {
                $0.reset()
            }
        }
    }
    
    private static var scopes: [InjectionScope] = []
}

/// Internal registration manager for factories.
private struct InjectionRegistration<Parameters, Value>: Identifiable {
    
    let id: UUID = UUID()
    let factory: (Parameters) -> Value
    let scope: InjectionScope?
    
    /// Resolves registration returning cached value from scope or new instance from factory. This is pretty much the heart of Factory.
    func resolve(_ params: Parameters) -> Value {
        let currentFactory: (Parameters) -> Value = (Injectables.factory(for: id) as? TypedFactory<Parameters, Value>)?.factory ?? factory
        let instance: Value = scope?.resolve(id: id, factory: { currentFactory(params) }) ?? currentFactory(params)
        return instance
    }
    
    /// Registers an injectable override and resets cache.
    func register(factory: @escaping (_ params: Parameters) -> Value) {
        Injectables.register(id: id, factory: TypedFactory<Parameters, Value>(factory: factory))
        scope?.reset(id)
    }
    
    /// Removes a factory override and resets cache.
    func reset() {
        Injectables.reset(id)
        scope?.reset(id)
    }
    
}


/// Conceptually, a container holding the state of all injectables and factory function overrides.
///
/// Injectables includes functions you can use to `push()` and `pop()` the state of injectable overrides, or to remove all overrides using the `reset()` function.
public enum Injectables {
    /// Pushes the current set of registration overrides onto a stack. Useful when testing when you want to push the current set of registrations,
    /// add your own, test, then pop the stack to restore the world to its original state.
    public static func push() {
        defer { lock.unlock() }
        lock.lock()
        stack.append(registrations)
    }
    
    /// Pops a previously pushed registration stack. Does nothing if stack is empty.
    public static func pop() {
        defer { lock.unlock() }
        lock.lock()
        if let registrations = stack.popLast() {
            self.registrations = registrations
        }
    }
    
    /// Resets and deletes all registered factory overrides.
    public static func reset() {
        defer { lock.unlock() }
        lock.lock()
        registrations = [:]
    }
    
    /// Internal registration function used by Factory
    fileprivate static func register(id: UUID, factory: AnyFactory) {
        defer { lock.unlock() }
        lock.lock()
        registrations[id] = factory
    }
    
    /// Internal resolution function used by Factory
    fileprivate static func factory(for id: UUID) -> AnyFactory? {
        defer { lock.unlock() }
        lock.lock()
        return registrations[id]
    }
    
    /// Internal reset function used by Factory
    fileprivate static func reset(_ id: UUID) {
        defer { lock.unlock() }
        lock.lock()
        registrations.removeValue(forKey: id)
    }
    
    private static var lock = Mutex()
    private static var stack: [[UUID: AnyFactory]] = []
    private static var registrations: [UUID: AnyFactory] = .init(minimumCapacity: 64)
}


/// Internal box protocol for factories
private protocol AnyFactory {}

/// Typed factory container
private struct TypedFactory<Parameters, Value>: AnyFactory {
    let factory: (Parameters) -> Value
}

/// Internal protocol used to evaluate optional types for caching
private protocol OptionalType {
    var wrappedType: Any.Type { get }
    var wrappedValue: Any? { get }
    var hasWrappedValue: Bool { get }
}

extension Optional: OptionalType {
    var wrappedType: Any.Type {
        Wrapped.self
    }
    var wrappedValue: Any? {
        switch self {
        case .none: return nil
        case .some(let value): return value
        }
    }
    var hasWrappedValue: Bool {
        switch self {
        case .none: return false
        case .some: return true
        }
    }
}


/// Internal box protocol for scope functionality
private protocol AnyBox {
    var instance: Any { get }
}

/// Strong box for cached and singleton scopes
private struct StrongBox<Value>: AnyBox {
    let boxed: Value
    var instance: Any { boxed as Any }
}

/// Weak box for shared scope
private struct WeakBox: AnyBox {
    weak var boxed: AnyObject?
    var instance: Any { boxed as Any }
}
