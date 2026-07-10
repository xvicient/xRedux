import Combine
import xRedux

@testable import GroceryApp

class HomeUseCaseMock: HomeUseCaseApi {

    var fetchItemsResult: ActionResult<[Item]>!
    var updateItemResult: ActionResult<EquatableVoid> = .success()

    func fetchItems() -> AnyPublisher<[Item], Error> {
        switch fetchItemsResult! {
        case .success(let items):
            return Just(items).setFailureType(to: Error.self).eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func updateItem(_ item: Item) async -> ActionResult<EquatableVoid> {
        updateItemResult
    }
}
    
