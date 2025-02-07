import xRedux

// MARK: - Reducer on view appear

extension Hello.Reducer {
    func onAppear(
        state: inout State
    ) -> Effect<Action> {
        state.viewState = .loading
        return .task { send in
            await send(
                .fetchContentResult(.success("Nothing to say..."))
            )
        }
    }
}
