import Combine
import xRedux

@testable import GroceryApp

class ListsUseCaseMock: ListsUseCaseApi {

    var fetchListsResult: ActionResult<[GroceryList], ListsError>!

    func fetchElements() -> AnyPublisher<[GroceryList], ListsError> {
        switch fetchListsResult! {
        case .success(let lists):
            return Just(lists).setFailureType(to: ListsError.self).eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func updateElement(_ element: GroceryList) async {}
}
