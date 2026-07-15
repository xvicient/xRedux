import Combine
import xRedux

@testable import GroceryApp

class ItemsUseCaseMock: ItemsUseCaseApi {

    var fetchItemsResult: ActionResult<[Item], ItemsError>!

    func fetchElements() -> AnyPublisher<[Item], ItemsError> {
        switch fetchItemsResult! {
        case .success(let items):
            return Just(items).setFailureType(to: ItemsError.self).eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func updateElement(_ element: Item) async {}

    func deleteElement(_ element: Item) async {}
}
