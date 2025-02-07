import xRedux

// MARK: - Reducer user actions

extension Hello.Reducer {
    
    func onDidTapSayHello(
        state: inout State
    ) -> Effect<Action> {
        state.viewModel.content = "Hello!"
        return .none
    }
}
