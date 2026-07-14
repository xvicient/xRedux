import Combine
import Foundation
import xRedux

/// A row that can be displayed in a list and marked as completed
protocol ToggleableItem: Identifiable, Equatable, Sendable where ID == UUID {
    var completed: Bool { get set }
}

/// Use case for fetching a list of rows and toggling each row's completion state
protocol ToggleableUseCaseApi {
    associatedtype Element: ToggleableItem

    func fetchElements() -> AnyPublisher<[Element], Error>
    func updateElement(_ element: Element) async -> VoidResult
}

/// Reducer for "a list of rows the user can mark as completed" (grocery lists, or their items)
struct ToggleableListReducer<UseCase: ToggleableUseCaseApi>: Reducer {
    typealias Element = UseCase.Element

    enum Action: Equatable, Sendable {
        case onAppear
        case didTapItem(Element.ID)
        case fetchItemsResult(ActionResult<[Element]>)
        case voidResult(VoidResult)
    }

    struct State {
        var viewState: ViewState = .idle
        var items = [Element]()
    }

    enum ViewState: Equatable {
        case idle
        case loading
        case error
    }

    private let useCase: UseCase

    init(useCase: UseCase) {
        self.useCase = useCase
    }

    func reduce(
        _ state: inout State,
        _ action: Action
    ) -> Effect<Action> {
        switch (state.viewState, action) {
        case (.idle, .onAppear):
            // Only fetch once - re-appearing would otherwise re-fetch and wipe out local
            // changes, e.g. a list just marked completed.
            guard state.items.isEmpty else {
                return .none
            }
            state.viewState = .loading
            return .publish(
                useCase.fetchElements()
                    .map { Action.fetchItemsResult(.success($0)) }
                    .catch { Just(Action.fetchItemsResult(.failure($0))) }
                    .eraseToAnyPublisher()
            )

        case (.loading, .fetchItemsResult(.success(let items))):
            state.viewState = .idle
            state.items = items
            return .none

        case (.loading, .fetchItemsResult(.failure)):
            state.viewState = .error
            return .none

        case (.idle, .didTapItem(let id)):
            guard let index = state.items.firstIndex(where: { $0.id == id }) else {
                return .none
            }
            state.items[index].completed.toggle()
            let item = state.items[index]
            return .task { send in
                await send(
                    .voidResult(
                        useCase.updateElement(item)
                    )
                )
            }

        case (_, .voidResult):
            return .none

        default:
            print("No matching ViewState and Action")
            return .none
        }
    }
}
