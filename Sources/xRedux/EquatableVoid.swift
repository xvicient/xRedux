/// A type that represents void but conforms to Equatable and Sendable protocols
/// Useful when you need an empty value that can be compared for equality or sent across actor boundaries
public struct EquatableVoid: Equatable, Sendable {
    public init() {}
}
