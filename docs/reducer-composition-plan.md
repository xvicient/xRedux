# Composición y extensión de reducers en xRedux

Estado: **En progreso** — Fase 1 y Plan B listos para ejecutar. Fase 2 **diferida** (ver nota al final).

## 1. Contexto

`Reducer` en xRedux es un protocolo (`State`, `Action: Equatable`, `reduce(_:_:)`) implementado por `struct`s. Swift no soporta herencia de structs, y aunque se usaran clases, `Action` es un associated type: un `override` no puede ampliar el tipo de `Action` que acepta (contravarianza no soportada con associated types). **Conclusión: no hay herencia real, y no merece la pena perseguirla.**

Lo que sí es viable — y es el mecanismo real detrás de la composición de features en TCA (`Scope` + `Reduce`) — es **composición por delegación**: un reducer "extendido" envuelve al reducer base y:
- reenvía las acciones compartidas al reducer base, delegando el `reduce`,
- añade sus propios casos de `Action` (y, si hace falta, sus propios campos de `State`) para lo que el reducer base no cubre.

Para que esto funcione hace falta una pieza que hoy no existe en xRedux: una forma de "elevar" el tipo de `Action` de un `Effect` hijo al tipo del padre.

## 2. Fase 1 — Cambio en el core de xRedux (EJECUTAR AHORA)

Añadir `Effect.map` en `Sources/xRedux/Effect.swift`:

```swift
extension Effect {
    public func map<NewAction>(_ transform: @escaping (Action) -> NewAction) -> Effect<NewAction> {
        switch self {
        case .none:
            return .none
        case .publish(let publisher):
            return .publish(publisher.map(transform).eraseToAnyPublisher())
        case .task(let task):
            return .task { send in
                await task { action in send(transform(action)) }
            }
        }
    }
}
```

Checklist:
- [ ] Añadir `Effect.map` con tests unitarios en `Tests/xReduxTests` cubriendo `.none`, `.publish`, `.task`.
- [ ] No se toca `Store`, `TestStore` ni `TestReducer` — ya son genéricos sobre `R: Reducer` y funcionan sin cambios con reducers compuestos.

## 3. Fase 2 — Helper genérico de composición (`Scope`) — **DIFERIDA, NO EJECUTAR AHORA**

> **Nota para retomar en otra sesión / otro contexto:** no implementar esto todavía.

Idea para cuando llegue el momento: extraer a `Sources/xRedux` un tipo genérico al estilo `Scope` de TCA que evite escribir a mano el `switch`/delegación en cada reducer que compone (ver Fase 1). Ejemplo de forma que podría tomar:

```swift
public struct Scope<ParentState, ParentAction, Child: Reducer>: Reducer {
    let toChildState: WritableKeyPath<ParentState, Child.State>
    let toChildAction: (ParentAction) -> Child.Action?
    let fromChildAction: (Child.Action) -> ParentAction
    let child: Child

    public func reduce(_ state: inout ParentState, _ action: ParentAction) -> Effect<ParentAction> {
        guard let childAction = toChildAction(action) else { return .none }
        return child.reduce(&state[keyPath: toChildState], childAction).map(fromChildAction)
    }
}
```

**Criterio para activarla: regla de tres.** Con un único caso de reutilización (Items → List, ver Plan B) escribir el `switch` a mano son 4 líneas; no se justifica una abstracción de librería. El día que aparezca un tercer reducer reutilizando un core compartido, retomar esta fase con contexto fresco y decidir la forma final del helper (¿generic struct? ¿protocol extension con default implementation?) mirando los casos reales que existan entonces, no los hipotéticos de hoy.

## 4. Plan B — Aplicación concreta: features `Lists` e `Items`

### 4.1 Qué cambia conceptualmente

GroceryApp pasa de tener una única feature (`Home`) a tener dos:

- **`Items`** (renombrado de `Home`): gestiona los items de una lista concreta. Comportamiento idéntico al actual `HomeReducer`: fetch, listado, marcar un item como completado.
- **`Lists`** (nueva): gestiona el listado de listas de la compra. Mismo comportamiento base (fetch, listado, marcar una lista como completada) **más** una acción propia que `Items` no tiene: al pulsar sobre una fila (fuera del checkbox) navega a la feature `Items` de esa lista.

Ambas features muestran "un listado con filas marcables como completadas" — por eso comparten lógica — pero operan sobre **entidades de dominio distintas** (`Item` vs. `GroceryList`), así que la reutilización 1:1 de `HomeReducer.State` planteada en la investigación inicial no aplica tal cual: hay que generalizar el reducer base para que sea genérico sobre el tipo de fila, no solo delegar acciones.

> Nota de nomenclatura: en el mensaje original se menciona "UseKey" — se asume que es "UseCase" (así se llama ya en el código, `HomeUseCaseApi`/`HomeUseCase`) y se sigue esa convención: `ItemsUseCaseApi`/`ItemsUseCase`, `ListsUseCaseApi`/`ListsUseCase`. Confirmar si el nombre pretendido era otro.

### 4.2 Reducer base genérico compartido

Nuevo archivo `Examples/GroceryApp/GroceryApp/Shared/ToggleableListReducer.swift`:

```swift
/// Element.ID is pinned to UUID (not left as Identifiable's free associated type) so that
/// Action can be declared unconditionally Sendable — otherwise passing `.shared` as a
/// function value to Effect.map triggers a "converting non-Sendable function value" warning.
protocol ToggleableItem: Identifiable, Equatable, Sendable where ID == UUID {
    var completed: Bool { get set }
}

protocol ToggleableUseCaseApi {
    associatedtype Element: ToggleableItem
    func fetchElements() -> AnyPublisher<[Element], Error>
    func updateElement(_ element: Element) async -> ActionResult<EquatableVoid>
}

struct ToggleableListReducer<UseCase: ToggleableUseCaseApi>: Reducer {
    typealias Element = UseCase.Element

    enum Action: Equatable, Sendable {
        case onAppear
        case didTapItem(Element.ID)
        case fetchItemsResult(ActionResult<[Element]>)
        case voidResult(ActionResult<EquatableVoid>)
    }

    struct State {
        var viewState: ViewState = .idle
        var items = [Element]()
    }

    enum ViewState: Equatable { case idle, loading, error }

    private let useCase: UseCase

    init(useCase: UseCase) { self.useCase = useCase }

    func reduce(_ state: inout State, _ action: Action) -> Effect<Action> {
        // Misma lógica que el HomeReducer actual, generalizada sobre Element.
    }
}
```

Este tipo vive en el **app de ejemplo**, no en la librería xRedux: es lógica de dominio de Groceria ("lista de filas marcables"), no una preocupación genérica de xRedux. Si este patrón se repite en apps reales que consuman xRedux, es candidato a subir a la librería más adelante (mismo criterio de "regla de tres" que la Fase 2).

### 4.3 Feature `Items` (renombrado de `Home`)

Sin acciones propias — es un uso directo del reducer base:

```swift
protocol ItemsUseCaseApi: ToggleableUseCaseApi where Element == Item {}
struct ItemsUseCase: ItemsUseCaseApi { /* ex HomeUseCase */ }

typealias ItemsReducer = ToggleableListReducer<ItemsUseCase>
```

Archivos (`Examples/GroceryApp/GroceryApp/Home/` → `Examples/GroceryApp/GroceryApp/Items/`):
- [ ] `HomeReducer.swift` → `ItemsReducer.swift` (queda como `typealias` + extensión `Store<ItemsReducer>.pendingItems/completedItems`, ex `Store<HomeReducer>`)
- [ ] `HomeUseCase.swift` → `ItemsUseCase.swift` (`HomeUseCaseApi` → `ItemsUseCaseApi`, `HomeUseCase` → `ItemsUseCase`)
- [ ] `HomeBuilder.swift` → `ItemsBuilder.swift` (`makeHome()` → `makeItems(for list: GroceryList)`, recibe la lista seleccionada para pedir sus items)
- [ ] `HomeView.swift` → `ItemsView.swift`
- [ ] `Item.swift` se queda igual (modelo de dominio, sin cambios)

Tests (`Examples/GroceryApp/GroceryAppTests/Home/` → `.../Items/`):
- [ ] `HomeTests.swift` → `ItemsTests.swift`
- [ ] `HomeUseCaseMock.swift` → `ItemsUseCaseMock.swift`
- [ ] `ItemMock.swift` sin cambios

### 4.4 Feature `Lists` (nueva)

Modelo de dominio nuevo, `Examples/GroceryApp/GroceryApp/Lists/GroceryList.swift`:

```swift
struct GroceryList: ToggleableItem, Hashable {
    let id = UUID()
    let name: String
    var completed: Bool
}
```

(`Hashable` además de `ToggleableItem` porque `navigationDestination(item:)` lo exige para la navegación — ver más abajo.)

`ListsReducer` reutiliza `ToggleableListReducer<UseCase>` para lo compartido y añade `didSelectList` para la navegación — este es el ejemplo real de "extensión de acciones" que motivó la investigación. Es genérico sobre `UseCase` (no solo sobre `ListsUseCase` a secas) para poder inyectar un mock en tests, igual que antes se inyectaba `HomeUseCaseApi` como protocolo:

```swift
protocol ListsUseCaseApi: ToggleableUseCaseApi where Element == GroceryList {}
struct ListsUseCase: ListsUseCaseApi { /* fetch de listas + updateElement */ }

struct ListsReducer<UseCase: ListsUseCaseApi>: Reducer {
    typealias State = ToggleableListReducer<UseCase>.State

    enum Action: Equatable, Sendable {
        case shared(ToggleableListReducer<UseCase>.Action)
        case didSelectList(UUID)
    }

    private let sharedReducer: ToggleableListReducer<UseCase>

    init(useCase: UseCase) {
        self.sharedReducer = ToggleableListReducer(useCase: useCase)
    }

    func reduce(_ state: inout State, _ action: Action) -> Effect<Action> {
        switch action {
        case .shared(let sharedAction):
            // `.map { .shared($0) }`, no `.map(Action.shared)` — pasar el case como función
            // desnuda dispara el mismo warning de Sendable que motivó fijar Element.ID == UUID.
            return sharedReducer.reduce(&state, sharedAction).map { .shared($0) }

        case .didSelectList:
            // Navegar es responsabilidad de ListsView (navigationDestination(item:)); esta
            // acción solo existe para demostrar el punto de extensión que Items no tiene.
            return .none
        }
    }
}

extension Store where R == ListsReducer<ListsUseCase> {
    var pendingLists: [GroceryList] { state.items.filter { !$0.completed } }
    var completedLists: [GroceryList] { state.items.filter { $0.completed } }
}
```

Nota de diseño: a diferencia del boceto inicial de la investigación, `Lists` **no** necesita un campo de `State` propio — `didSelectList` no muta nada que el core no tenga, así que `State` sigue siendo un alias directo del core (igual que `Items`). La navegación se resuelve con `@State private var selectedList: GroceryList?` **local a `ListsView`**, no en el reducer: `didSelectList` se sigue enviando (documenta el punto de extensión y sirve de gancho para analítica), pero quien decide qué mostrar es la vista, coherente con "no generalizar navegación en xRedux" (§6).

Interacción: pulsar el checkbox de la fila envía `.shared(.didTapItem(id))` (marcar como completada); pulsar el resto de la fila envía `.didSelectList(id)` y además actualiza el `@State` local que dispara `navigationDestination(item:)` hacia `ItemsBuilder.makeItems(for:)`.

Archivos nuevos (`Examples/GroceryApp/GroceryApp/Lists/`):
- [ ] `GroceryList.swift`
- [ ] `ListsUseCase.swift`
- [ ] `ListsReducer.swift`
- [ ] `ListsBuilder.swift` (`makeLists() -> some View`, se convierte en el punto de entrada de la app)
- [ ] `ListsView.swift`

Tests (`Examples/GroceryApp/GroceryAppTests/Lists/`):
- [ ] `GroceryListMock.swift`
- [ ] `ListsUseCaseMock.swift`
- [ ] `ListsTests.swift` (calcado de `ItemsTests.swift`, más casos para `didSelectList`)

### 4.5 Cambios de arranque

- [ ] `GroceryApp.swift`: `HomeBuilder.makeHome()` → `ListsBuilder.makeLists()`

## 5. Orden de ejecución propuesto

1. Fase 1 (`Effect.map` + tests en la librería xRedux).
2. Generalizar el reducer actual: crear `ToggleableListReducer` en el ejemplo, renombrar `Home` → `Items` implementado como `typealias` sobre él, sin cambiar comportamiento.
3. Añadir la feature `Lists` completa (modelo, use case, reducer, builder, vista, tests) sobre el mismo core compartido.
4. Actualizar `GroceryApp.swift` para arrancar en `Lists`.
5. Ejecutar toda la suite de tests del ejemplo y confirmar que `ItemsTests` sigue en verde tras el renombrado.

## 6. Qué queda explícitamente fuera de esta ronda

- **Fase 2** (helper `Scope` genérico en la librería xRedux) — diferida, ver §3.
- Cualquier sistema de navegación/coordinator genérico en xRedux — se resuelve aquí con SwiftUI puro (`navigationDestination(item:)`), no se generaliza.
