import Combine
import xRedux

/// Errors specific to the lists feature.
enum ListsError: Error, Equatable {
    case fetchFailed
}

protocol ListsUseCaseApi: ToggleableUseCaseApi where Element == GroceryList, Failure == ListsError {}

struct ListsUseCase: ListsUseCaseApi {
    func fetchElements() -> AnyPublisher<[GroceryList], ListsError> {
        Just([
            GroceryList(name: "Weekly groceries", completed: false),
            GroceryList(name: "Party supplies", completed: false),
            GroceryList(name: "Pharmacy", completed: false),
        ])
        .setFailureType(to: ListsError.self)
        .eraseToAnyPublisher()
    }

    func updateElement(_ element: GroceryList) async {
        // Simulates a network call.
    }
}
