import xRedux
import Entities
import Foundation

extension Hello {
    struct Reducer: xRedux.Reducer {
        enum Action: Equatable {
            /// HelloReducer+ViewAppear
            case onViewAppear

            /// HelloReducer+UserActions
            case didTapSayHello

            /// HelloReducer+Results
            case fetchContentResult(ActionResult<String>)
        }

        @MainActor
        struct State {
            var viewState = ViewState.idle
            var viewModel = ViewModel()
        }

        enum ViewState: Equatable {
            case idle
            case loading
            case error
        }

        // MARK: - Reduce

        @MainActor
        func reduce(
            _ state: inout State,
            _ action: Action
        ) -> Effect<Action> {

            switch (state.viewState, action) {
            case (.idle, .onViewAppear):
                return onAppear(
                    state: &state
                )
                
            case (.loading, .fetchContentResult(let result)):
                return onFetchContentResult(
                    state: &state,
                    result: result
                )

            case (.idle, .didTapSayHello):
                return onDidTapSayHello(
                    state: &state
                )
                
            default:
                return .none
            }
        }
    }
}
