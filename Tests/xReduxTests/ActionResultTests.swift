import Testing

@testable import xRedux

/// Regression tests for `ActionResult` (issue #4 in the improvement plan):
/// failures must compare by the typed error's value, not by `localizedDescription`.
struct ActionResultTests {

	/// Two instances with different values but an identical `localizedDescription`.
	/// The old string-based comparison would wrongly treat them as equal.
	private struct SampleError: Error, Equatable {
		let code: Int
		var localizedDescription: String { "The operation failed" }
	}

	@Test("Two failures with different error values are not equal despite identical descriptions")
	func differentErrorsAreNotEqual() {
		let first = SampleError(code: 1)
		let second = SampleError(code: 2)

		// Same description, different value: the whole point of the fix.
		#expect(first.localizedDescription == second.localizedDescription)

		let lhs: ActionResult<Int, SampleError> = .failure(first)
		let rhs: ActionResult<Int, SampleError> = .failure(second)

		#expect(lhs != rhs)
	}

	@Test("Two failures with the same error value are equal")
	func sameErrorsAreEqual() {
		let lhs: ActionResult<Int, SampleError> = .failure(SampleError(code: 1))
		let rhs: ActionResult<Int, SampleError> = .failure(SampleError(code: 1))

		#expect(lhs == rhs)
	}

	@Test("Success and failure are never equal")
	func successNotEqualToFailure() {
		let success: ActionResult<Int, SampleError> = .success(1)
		let failure: ActionResult<Int, SampleError> = .failure(SampleError(code: 1))

		#expect(success != failure)
	}

	@Test("value and error accessors return the typed payloads")
	func accessorsReturnTypedPayloads() {
		let success: ActionResult<Int, SampleError> = .success(42)
		#expect(success.value == 42)
		#expect(success.error == nil)

		let failure: ActionResult<Int, SampleError> = .failure(SampleError(code: 7))
		#expect(failure.value == nil)
		#expect(failure.error == SampleError(code: 7))
	}
}
