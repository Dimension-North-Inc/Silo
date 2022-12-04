# Silo

A Redux inspired state container featuring composable Reducer types and a unified Reducer/Middleware async `Effect` system.

`Silo` is an evolution of our older state container: `Storage`, which more closely models Redux with `Store`, `Reducer`, and `Middleware` 
types playing roles similar to those you might encounter in a standard Redux environment. 

### Silo versus Storage - Benefits & Drawbacks

`Silo` has been designed from the ground-up to work in the new `async-await` world of Swift. It falls back on the `Combine` framework
where it needs to, but eschews that wherever it can to simplify the codebase. `Combine` plays a role in Apple's SwiftUI framework, so `Silo`
adopts it particularly in it's built-in SwiftUI support, but it otherwise minimizes dependency on the framework.

`Storage`, by comparison, was written prior to `async-await` and has rudimentary support for `Combine`.

One among several areas where `Storage` is more established than `Silo` is its handling of classic Cocoa undo management. `Storage`
started its life as the back-end for a document-based Cocoa application. Undo is a key part of this environment, and `Silo` hasn't yet
been coded to support Cocoa-style undo/redo.

### Testing

`Silo` includes the `Expect` package for more fluent test case expressions and several basic tests surrounding parent-child reducer relationships.

