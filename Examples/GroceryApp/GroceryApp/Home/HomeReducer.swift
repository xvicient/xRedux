import Foundation
import xRedux

struct HomeReducer: Reducer {
    enum Action: Equatable {
        case onAppear
        case didTapItem(UUID)
        case fetchItemsResult(ActionResult<[Item]>)
        case voidResult(ActionResult<EquatableVoid>)
    }
    
    struct State {
        var viewState: ViewState = .idle
        var items = [Item]()
    }
    
    enum ViewState: Equatable {
        case idle
        case loading
        case error
    }
    
    private let useCase: HomeUseCaseApi
    
    init(useCase: HomeUseCaseApi) {
        self.useCase = useCase
    }
    
    func reduce(
        _ state: inout State,
        _ action: Action
    ) -> Effect<Action> {
        switch (state.viewState, action) {
        case (.idle, .onAppear):
            state.viewState = .loading
            return .task { send in
                await send(
                    .fetchItemsResult(
                        useCase.fetchItems()
                    )
                )
            }
            
        case (.loading, .fetchItemsResult(.success(let items))):
            state.viewState = .idle
            state.items = items
            return .none
            
        case (.loading, .fetchItemsResult(.failure)):
            state.viewState = .error
            return .none
            
        case (.idle, .didTapItem(let id)):
            guard let index = state.items.firstIndex(where: { $0.id == id }) else {
                return .none
            }
            state.items[index].completed.toggle()
            return .none
            
        default:
            print("No matching ViewState and Action")
            return .none
        }
    }
}

extension Store<HomeReducer> {
    var pendingItems: [Item] {
        get {
            state.items.filter { !$0.completed }
        }
        set { }
    }
    
    var completedItems: [Item] {
        get {
            state.items.filter { $0.completed }
        }
        set { }
    }
}
