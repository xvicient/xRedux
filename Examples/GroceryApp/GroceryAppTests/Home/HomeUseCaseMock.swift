import xRedux

@testable import GroceryApp

class HomeUseCaseMock: HomeUseCaseApi {
    
    var fetchItemsResult: ActionResult<[Item]>!
    
    func fetchItems() async -> ActionResult<[Item]> {
        fetchItemsResult
    }
}
    
