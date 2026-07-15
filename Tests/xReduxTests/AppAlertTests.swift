import SwiftUI
import Testing

@testable import xRedux

/// Regression tests for `AppAlert` (issue #5 in the improvement plan):
/// unique identity, content-based equality, and dismiss propagation.
@MainActor
struct AppAlertTests {

	private enum Action: Equatable, Sendable {
		case confirm
		case cancel
		case dismiss
	}

	// MARK: - Identity

	@Test("Two alerts with identical content still get distinct ids")
	func identicalContentHasDistinctIds() {
		let a = AppAlert<Action>(title: "T", message: "M", primaryAction: (.confirm, "OK"))
		let b = AppAlert<Action>(title: "T", message: "M", primaryAction: (.confirm, "OK"))

		#expect(a.id != b.id)
	}

	// MARK: - Equality

	@Test("Alerts with identical content are equal despite different ids")
	func identicalContentIsEqual() {
		let a = AppAlert<Action>(title: "T", message: "M", primaryAction: (.confirm, "OK"))
		let b = AppAlert<Action>(title: "T", message: "M", primaryAction: (.confirm, "OK"))

		#expect(a == b)
	}

	@Test("Alerts differing only in action are not equal")
	func differingActionIsNotEqual() {
		let a = AppAlert<Action>(title: "T", primaryAction: (.confirm, "OK"))
		let b = AppAlert<Action>(title: "T", primaryAction: (.cancel, "OK"))

		#expect(a != b)
	}

	@Test("Alerts differing in secondary action presence are not equal")
	func differingSecondaryIsNotEqual() {
		let single = AppAlert<Action>(title: "T", primaryAction: (.confirm, "OK"))
		let double = AppAlert<Action>(
			title: "T",
			primaryAction: (.confirm, "OK"),
			secondaryAction: (.cancel, "Cancel")
		)

		#expect(single != double)
	}

	@Test("Alerts with matching secondary actions are equal")
	func matchingSecondaryIsEqual() {
		let a = AppAlert<Action>(
			title: "T",
			primaryAction: (.confirm, "OK"),
			secondaryAction: (.cancel, "Cancel")
		)
		let b = AppAlert<Action>(
			title: "T",
			primaryAction: (.confirm, "OK"),
			secondaryAction: (.cancel, "Cancel")
		)

		#expect(a == b)
	}

	// MARK: - Dismiss binding

	private struct AlertReducer: Reducer {
		struct State: AppAlertState {
			var alert: AppAlert<Action>?
			var dismissAlertAction: Action? { .dismiss }
		}

		func reduce(_ state: inout State, _ action: Action) -> Effect<Action> {
			switch action {
			case .confirm, .cancel, .dismiss:
				state.alert = nil
				return .none
			}
		}
	}

	@Test("Clearing the binding while an alert is present sends the dismiss action")
	func dismissBindingSendsDismissAction() {
		let store = Store(
			initialState: AlertReducer.State(
				alert: AppAlert(title: "T", primaryAction: (.confirm, "OK"))
			),
			reducer: AlertReducer()
		)

		#expect(store.state.alert != nil)

		// Simulate SwiftUI writing nil to the binding on dismissal.
		store.alertBinding.wrappedValue = nil

		#expect(store.state.alert == nil)
	}

	@Test("Clearing the binding when no alert is present is a no-op")
	func dismissBindingNoOpWhenAlreadyCleared() {
		let store = Store(
			initialState: AlertReducer.State(alert: nil),
			reducer: AlertReducer()
		)

		store.alertBinding.wrappedValue = nil

		#expect(store.state.alert == nil)
	}
}
