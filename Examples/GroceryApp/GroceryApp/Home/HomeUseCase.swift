import xRedux

protocol HomeUseCaseApi {
    func fetchItems() async -> ActionResult<[Item]>
}

struct HomeUseCase: HomeUseCaseApi {
    func fetchItems() async -> ActionResult<[Item]> {
        .success([
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
    }
}
