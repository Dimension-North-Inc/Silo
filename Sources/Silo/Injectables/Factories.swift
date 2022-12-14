//
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
//

import Foundation

/// Factory manages the dependency injection process for a given object or service.
public struct Factory<Value> {
    /// Initializes a Factory with a factory closure that returns a new instance of the desired type.
    public init(_ factory: @escaping @autoclosure () -> Value) {
        self.registration = Registration<Void, Value>(factory: factory, scope: nil)
    }
    
    /// Initializes with factory closure that returns a new instance of the desired type. The scope defines the lifetime of that instance.
    public init(scope: FactoryScope, factory: @escaping @autoclosure () -> Value) {
        self.registration = Registration<Void, Value>(factory: factory, scope: scope)
    }
    
    /// Resolves and returns an instance of the desired object type. This may be a new instance or one that was created previously and then cached,
    /// depending on whether or not a scope was specified when the factory was created.
    ///
    /// Note return type of `Value` could still be `<Value?>` depending on original Factory specification.
    public func callAsFunction() -> Value {
        registration.resolve(())
    }
    
    /// Registers a new factory that will be used to create and return an instance of the desired object type.
    ///
    /// This registration overrides the original factory and its result will be returned on all new object resolutions. Registering a new
    /// factory also clears the previous instance from the associated scope.
    ///
    /// All registrations are stored in SharedContainer.Registrations.
    public func register(factory: @escaping @autoclosure () -> Value) {
        registration.register(factory: factory)
    }
    
    /// Deletes any registered factory override and resets this Factory to use the factory closure specified during initialization. Also
    /// resets the scope so that a new instance of the original type will be returned on the next resolution.
    public func reset() {
        registration.reset()
    }
    
    private let registration: Registration<Void, Value>
}

/// ParameterizedFactory manages the dependency injection process for a given object or service that needs one or more arguments
/// passed to it during instantiation.
public struct ParameterizedFactory<Parameters, Value> {
    
    /// Initializes a Factory with a factory closure that returns a new instance of the desired type.
    public init(factory: @escaping (_ params: Parameters) -> Value) {
        self.registration = Registration<Parameters, Value>(factory: factory, scope: nil)
    }
    
    /// Initializes with factory closure that returns a new instance of the desired type. The scope defines the lifetime of that instance.
    public init(scope: FactoryScope, factory: @escaping (_ params: Parameters) -> Value) {
        self.registration = Registration<Parameters, Value>(factory: factory, scope: scope)
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
    
    private let registration: Registration<Parameters, Value>
}

/// Defines an abstract base implementation of a scope cache.
public class FactoryScope {
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
                if let optional = instance as? OptionalProtocol {
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
        if let optional = instance as? OptionalProtocol {
            return optional.hasWrappedValue ? StrongBox<Value>(boxed: instance) : nil
        } else {
            return StrongBox<Value>(boxed: instance)
        }
    }
    
    private var lock = Mutex(recursive: true)
    private var cache: [UUID: AnyBox] = .init(minimumCapacity: 64)

    
    /// Defines a cached scope. The same instance will be returned by the factory until the cache is reset.
    public static let cached = Cached()
    public final class Cached: FactoryScope {
        public override init() {
            super.init()
        }
    }
    
    /// Defines a shared (weak) scope. The same instance will be returned by the factory as long as someone maintains a strong reference.
    public static let shared = Shared()
    public final class Shared: FactoryScope {
        public override init() {
            super.init()
        }
        fileprivate override func box<Value>(_ instance: Value) -> AnyBox? {
            if let optional = instance as? OptionalProtocol {
                if let unwrapped = optional.wrappedValue, type(of: unwrapped) is AnyObject.Type {
                    return WeakBox(boxed: unwrapped as AnyObject)
                }
            } else if type(of: instance as Any) is AnyObject.Type {
                return WeakBox(boxed: instance as AnyObject)
            }
            return nil
        }
    }
    
    /// Defines a singleton scope. The same instance will always be returned by the factory.
    public static let singleton = Singleton()
    public final class Singleton: FactoryScope {
        public override init() {
            super.init()
        }
    }
    
    /// Resets all scope caches.
    public static func reset(includingSingletons: Bool = false) {
        Self.scopes.forEach {
            if !($0 is Singleton) || includingSingletons {
                $0.reset()
            }
        }
    }
    
    private static var scopes: [FactoryScope] = []
}

/// Internal registration manager for factories.
fileprivate struct Registration<Parameters, Value>: Identifiable {
    
    let id: UUID = UUID()
    let factory: (Parameters) -> Value
    let scope: FactoryScope?
    
    /// Resolves registration returning cached value from scope or new instance from factory. This is pretty much the heart of Factory.
    func resolve(_ params: Parameters) -> Value {
        let currentFactory: (Parameters) -> Value = (Factories.factory(for: id) as? TypedFactory<Parameters, Value>)?.factory ?? factory
        let instance: Value = scope?.resolve(id: id, factory: { currentFactory(params) }) ?? currentFactory(params)
        return instance
    }
    
    /// Registers a factory override and resets cache.
    func register(factory: @escaping (_ params: Parameters) -> Value) {
        Factories.register(id: id, factory: TypedFactory<Parameters, Value>(factory: factory))
        scope?.reset(id)
    }
    
    /// Removes a factory override and resets cache.
    func reset() {
        Factories.reset(id)
        scope?.reset(id)
    }
    
}

public final class Factories {
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

#if swift(>=5.1)
/// Convenience property wrapper takes a factory and creates an instance of the desired type.
@propertyWrapper public struct Injected<Value> {
    private var dependency: Value
    public init(_ factory: Factory<Value>) {
        self.dependency = factory()
    }
    public var wrappedValue: Value {
        get { return dependency }
        mutating set { dependency = newValue }
    }
}

/// Convenience property wrapper takes a factory and creates an instance of the desired type the first time the wrapped value is requested.
@propertyWrapper public struct LazyInjected<Value> {
    private var factory: Factory<Value>
    private var dependency: Value!
    private var initialize = true
    public init(_ factory: Factory<Value>) {
        self.factory = factory
    }
    public var wrappedValue: Value {
        mutating get {
            if initialize {
                dependency = factory()
                initialize = false
            }
            return dependency
        }
        mutating set {
            dependency = newValue
        }
    }
}

@propertyWrapper public struct WeakLazyInjected<Value> {
    private var factory: Factory<Value>
    private weak var dependency: AnyObject?
    private var initialize = true
    public init(_ factory: Factory<Value>) {
        self.factory = factory
    }
    public var wrappedValue: Value? {
        mutating get {
            if initialize {
                dependency = factory() as AnyObject
                initialize = false
            }
            return dependency as? Value
        }
        mutating set {
            dependency = newValue as AnyObject
        }
    }
}
#endif

/// Internal box protocol for factories
private protocol AnyFactory {}

/// Typed factory container
private struct TypedFactory<Parameters, Value>: AnyFactory {
    let factory: (Parameters) -> Value
}

/// Internal protocol used to evaluate optional types for caching
private protocol OptionalProtocol {
    var wrappedType: Any.Type { get }
    var wrappedValue: Any? { get }
    var hasWrappedValue: Bool { get }
}

extension Optional: OptionalProtocol {
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
