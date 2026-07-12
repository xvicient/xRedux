import Combine
import xRedux

protocol ListsUseCaseApi: ToggleableUseCaseApi where Element == GroceryList {}

struct ListsUseCase: ListsUseCaseApi {
    func fetchElements() -> AnyPublisher<[GroceryList], Error> {
        Just([
            GroceryList(name: "Weekly groceries", completed: false),
            GroceryList(name: "Party supplies", completed: false),
            GroceryList(name: "Pharmacy", completed: false),
        ])
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }

    func updateElement(_ element: GroceryList) async -> ActionResult<EquatableVoid> {
        // Simulates a network call.
        .success()
    }
}
