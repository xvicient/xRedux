# xRedux

## Description
`xRedux` is a state management library for Swift applications, inspired by Redux architecture. It provides a predictable state container that helps manage application state in a consistent and maintainable way.

## Installation
To use `xRedux` in your Swift project, you can add it as a dependency using Swift Package Manager (SPM). Here’s how:

1. Open your `Package.swift` file.
2. Add `xRedux` to the dependencies array:
   ```swift
   .package(url: "https://github.com/xvicient/xRedux.git", from: "1.0.0")
   ```
3. Add `xRedux` to your target's dependencies:
   ```swift
   .target(name: "YourTargetName", dependencies: ["xRedux"]),
   ```
4. Run `swift package update` to fetch the package.

## Usage
Import `xRedux` in your Swift files:
```swift
import xRedux
```

You can now start using `xRedux` to manage your application state.