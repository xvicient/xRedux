/// A type that represents either a success with an associated value or a failure with an error
public enum ActionResult<Success: Sendable>: Sendable {
    /// Represents a successful result containing the associated value
    case success(Success)
    /// Represents a failure result containing the associated error
    case failure(Error)

    /// Creates a new result by evaluating an async throwing closure
    /// - Parameter body: The async throwing closure to evaluate
    public init(catching body: @Sendable () async throws -> Success) async {
        do {
            self = .success(try await body())
        }
        catch {
            self = .failure(error)
        }
    }
    
    /// Creates a new result from a standard Swift Result type
    /// - Parameter result: The Result to convert from
    public init<Failure>(_ result: Result<Success, Failure>) where Failure: Error {
        switch result {
        case let .success(value):
            self = .success(value)
        case let .failure(error):
            self = .failure(error)
        }
    }

    /// The success value if the result is a success, nil otherwise
    public var value: Success? {
        switch self {
        case let .success(value):
            return value
        case .failure:
            return nil
        }
    }

    /// The error value if the result is a failure, nil otherwise
    public var error: Error? {
        switch self {
        case .success:
            return nil
        case let .failure(error):
            return error
        }
    }
}

/// Extension to make ActionResult equatable when its Success type is equatable
extension ActionResult: Equatable where Success: Equatable {
    /// Compares two ActionResults for equality
    /// - Parameters:
    ///   - lhs: Left-hand side ActionResult
    ///   - rhs: Right-hand side ActionResult
    /// - Returns: True if both results are equal
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lhsValue), .success(rhsValue)):
            return lhsValue == rhsValue
        case let (.failure(lhsError), .failure(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/// Extension to make ActionResult hashable when its Success type is hashable
extension ActionResult: Hashable where Success: Hashable {
    /// Hashes the essential components of this value by feeding them into the given hasher
    /// - Parameter hasher: The hasher to use when combining the components of this instance
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .success(value):
            hasher.combine(value)
        case let .failure(error):
            hasher.combine(error.localizedDescription)
        }
    }
}

/// Extension to provide convenience success initializer for EquatableVoid results
public extension ActionResult where Success == EquatableVoid {
    /// Creates a new success result with an EquatableVoid value
    /// - Returns: A success result containing EquatableVoid
    static func success() -> ActionResult {
        .success(EquatableVoid())
    }
}
