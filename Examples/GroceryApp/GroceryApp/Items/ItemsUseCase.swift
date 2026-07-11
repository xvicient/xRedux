import Combine
import xRedux

protocol ItemsUseCaseApi: ToggleableUseCaseApi where Element == Item {}

struct ItemsUseCase: ItemsUseCaseApi {
    func fetchElements() -> AnyPublisher<[Item], Error> {
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
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }

    func updateElement(_ element: Item) async -> ActionResult<EquatableVoid> {
        // Simulates persisting the toggle through a network call.
        .success()
    }
}
