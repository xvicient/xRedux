/// A type that represents either a success with an associated value or a failure
/// with a typed error.
///
/// The error is a generic `Failure` parameter (not `any Error`) so that equality
/// and hashing compare the actual error, rather than its `localizedDescription`.
public enum ActionResult<Success, Failure: Error> {
    /// Represents a successful result containing the associated value
    case success(Success)
    /// Represents a failure result containing the associated typed error
    case failure(Failure)

    /// Creates a new result from a standard Swift `Result`.
    /// - Parameter result: The `Result` to convert from.
    public init(_ result: Result<Success, Failure>) {
        switch result {
        case let .success(value):
            self = .success(value)
        case let .failure(error):
            self = .failure(error)
        }
    }

    /// The success value if the result is a success, `nil` otherwise.
    public var value: Success? {
        switch self {
        case let .success(value):
            return value
        case .failure:
            return nil
        }
    }

    /// The typed error if the result is a failure, `nil` otherwise.
    public var error: Failure? {
        switch self {
        case .success:
            return nil
        case let .failure(error):
            return error
        }
    }
}

/// Convenience for the untyped path: build a result from an async throwing closure.
/// Thrown errors are captured as `any Error`, so this is only available when the
/// failure type is `any Error`. Map into a domain error to regain equality.
public extension ActionResult where Failure == any Error {
    /// Creates a new result by evaluating an async throwing closure.
    /// - Parameter body: The async throwing closure to evaluate.
    init(catching body: @Sendable () async throws -> Success) async {
        do {
            self = .success(try await body())
        }
        catch {
            self = .failure(error)
        }
    }
}

/// `ActionResult` is `Sendable` when both of its payloads are.
extension ActionResult: Sendable where Success: Sendable, Failure: Sendable {}

/// `ActionResult` is `Equatable` when both of its payloads are.
/// Errors are compared by value, not by `localizedDescription`.
extension ActionResult: Equatable where Success: Equatable, Failure: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lhsValue), .success(rhsValue)):
            return lhsValue == rhsValue
        case let (.failure(lhsError), .failure(rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

/// `ActionResult` is `Hashable` when both of its payloads are.
extension ActionResult: Hashable where Success: Hashable, Failure: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .success(value):
            hasher.combine(value)
        case let .failure(error):
            hasher.combine(error)
        }
    }
}

/// Extension to provide convenience success initializer for EquatableVoid results
public extension ActionResult where Success == EquatableVoid {
    /// Creates a new success result with an EquatableVoid value
    /// - Returns: A success result containing EquatableVoid
    static func success() -> Self {
        .success(EquatableVoid())
    }
}
