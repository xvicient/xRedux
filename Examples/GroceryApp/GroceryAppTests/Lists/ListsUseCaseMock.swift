import Combine
import xRedux

@testable import GroceryApp

class ListsUseCaseMock: ListsUseCaseApi {

    var fetchListsResult: ActionResult<[GroceryList]>!
    var updateListResult: ActionResult<EquatableVoid> = .success()

    func fetchElements() -> AnyPublisher<[GroceryList], Error> {
        switch fetchListsResult! {
        case .success(let lists):
            return Just(lists).setFailureType(to: Error.self).eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    func updateElement(_ element: GroceryList) async -> ActionResult<EquatableVoid> {
        updateListResult
    }
}
