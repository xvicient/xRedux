public enum ActionResult<Success: Sendable>: Sendable {
	case success(Success)
	case failure(Error)

	public init(catching body: @Sendable () async throws -> Success) async {
		do {
			self = .success(try await body())
		}
		catch {
			self = .failure(error)
		}
	}

	public init<Failure>(_ result: Result<Success, Failure>) where Failure: Error {
		switch result {
		case let .success(value):
			self = .success(value)
		case let .failure(error):
			self = .failure(error)
		}
	}

	public var value: Success? {
		switch self {
		case let .success(value):
			return value
		case .failure:
			return nil
		}
	}

	public var error: Error? {
		switch self {
		case .success:
			return nil
		case let .failure(error):
			return error
		}
	}
}

extension ActionResult: Equatable where Success: Equatable {
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

extension ActionResult: Hashable where Success: Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .success(value):
			hasher.combine(value)
		case let .failure(error):
			hasher.combine(error.localizedDescription)
		}
	}
}

public extension ActionResult where Success == EquatableVoid {
	static func success() -> ActionResult {
		.success(EquatableVoid())
	}
}
