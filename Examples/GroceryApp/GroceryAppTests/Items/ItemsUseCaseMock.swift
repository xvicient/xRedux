import Combine
import xRedux

@testable import GroceryApp

class ItemsUseCaseMock: ItemsUseCaseApi {

    var fetchItemsResult: ActionResult<[Item]>!
    var updateItemResult: VoidResult = .success()
    var deleteItemResult: VoidResult = .success()

    func fetchElements() -> AnyPublisher<[Item], Error> {
        switch fetchItemsResult! {
        case .success(let items):
            return Just(items).setFailureType(to: Error.self).eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func updateElement(_ element: Item) async -> VoidResult {
        updateItemResult
    }

    func deleteElement(_ element: Item) async -> VoidResult {
        deleteItemResult
    }
}
