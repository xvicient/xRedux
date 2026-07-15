import Combine
import xRedux

/// Errors specific to the items feature.
enum ItemsError: Error, Equatable {
    case fetchFailed
}

protocol ItemsUseCaseApi: ToggleableUseCaseApi where Element == Item, Failure == ItemsError {
    func deleteElement(_ element: Item) async
}

struct ItemsUseCase: ItemsUseCaseApi {
    func fetchElements() -> AnyPublisher<[Item], ItemsError> {
        Just([
            Item(name: "Apples", completed: false),
            Item(name: "Bananas", completed: false),
            Item(name: "Bread", completed: false),
            Item(name: "Milk", completed: false),
            Item(name: "Eggs", completed: false),
            Item(name: "Chicken", completed: false),
            Item(name: "Rice", completed: false),
            Item(name: "Pasta", completed: false),
            Item(name: "Tomatoes", completed: false),
        ])
        .setFailureType(to: ItemsError.self)
        .eraseToAnyPublisher()
    }

    func updateElement(_ element: Item) async {
        // Simulates a network call.
    }

    func deleteElement(_ element: Item) async {
        // Simulates a network call.
    }
}
