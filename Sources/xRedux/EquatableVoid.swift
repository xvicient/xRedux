/// A type that represents void but conforms to Equatable and Sendable protocols
/// Useful when you need an empty value that can be compared for equality or sent across actor boundaries
public struct EquatableVoid: Equatable, Sendable {
    public init() {}
}

/// Convenience alias for an action result that carries no payload
/// Use instead of `ActionResult<EquatableVoid>` to reduce noise at call sites
public typealias VoidResult = ActionResult<EquatableVoid>
