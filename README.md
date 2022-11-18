# Silo

A Redux inspired state container featuring composable Reducer types and a unified Reducer/Middleware async `Effect` system.

`Silo` is an evolution of our older state container: `Storage`, which more closely models Redux with `Store`, `Reducer`, and `Middleware` 
types playing roles similar to those you might encounter in a standard Redux environment. 

### Silo Benefits Relative to Storage

`Silo` has been designed from the ground-up to work in the new `async-await` world of Swift. It falls back on the `Combine` framework
where it needs to, but eschews that wherever it can to simplify the codebase. `Combine` plays a role in Apple's SwiftUI framework, so `Silo`
adopts it particularly in it's built-in SwiftUI support, but it otherwise minimizes dependency on the framework.

`Storage`, by comparison, was written prior to `async-await` and has rudimentary support of `Combine`.

### Silo Drawbacks Relative to Storage

One among several areas where `Storage` is more established than `Silo` is its handling of classic Cocoa undo management. `Storage`
started its life as the back-end for a document-based Cocoa application. Undo is a key part of this environment, and `Silo` hasn't yet
been coded to support Cocoa-style undo/redo.

### Testing

`Silo` includes the `Expect` package for more fluent test case expressions. We're still working on how to test this package though.
This code is central stuff, so it's not hooked for mocking in the same way an application might be, which makes testing more difficult. 
`Storage` faced the same challenges in testing. 
