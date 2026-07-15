# Plan de mejora de xRedux

Plan de trabajo para corregir las 7 debilidades identificadas en la revisión.
Ordenado por **retorno / esfuerzo**: primero lo barato y de alto impacto, al final lo
estructural.

Leyenda de estado: ⬜ pendiente · 🟡 en progreso · ✅ hecho

---

## 1. `TestStore`: fuera `precondition`, dentro Swift Testing ✅

**Problema.** `TestStore.send` / `receive` (y `TestReducer`) usan `precondition`, que
**crashea el proceso entero** en vez de fallar un test individual. No hay diff, no hay
mensaje útil, y un fallo mata toda la suite.

**Archivos.**
- `Sources/xReduxTest/TestStore.swift`
- `Sources/xReduxTest/TestReducer.swift`

**Enfoque.**
- Sustituir cada `precondition(...)` por `Issue.record(...)` de `Testing` (o `#expect`),
  con mensajes que incluyan acción esperada vs. recibida y el estado.
- Importar `Testing` en el target `xReduxTest` y propagar `#filePath`/`#line` (o
  `SourceLocation`) para que el fallo apunte a la línea del test que llama, no a la
  librería.
- Mantener la API pública (`send(_:assert:)`, `receive(...)`) estable.

**Criterio de aceptación.**
- Un assert fallido reporta un fallo de test legible **sin** crashear el runner.
- Los tests del `GroceryApp` siguen compilando y pasando sin cambios de llamada.

**Tests de regresión.** Añadir `Tests/xReduxTests/TestStoreTests.swift` que verifique:
un `send` con expectativa correcta pasa; una incorrecta reporta fallo (no crash).

---

## 2. `TestStore.receive`: eliminar el polling con `Task.sleep` ⬜

**Problema.** `receive` hace un bucle de `Task.sleep(100ms)` hasta 5s esperando el efecto
async. Es lento y no determinista.

**Archivos.**
- `Sources/xReduxTest/TestStore.swift`
- `Sources/xReduxTest/TestReducer.swift`

**Enfoque.**
- Reemplazar el bucle de sondeo por una espera basada en continuación: el
  `TestReducer` señaliza (vía `CheckedContinuation` / `AsyncStream`) en cuanto llega la
  acción esperada.
- Mantener un `timeout` real (con `Task` de timeout que cancele la espera) para no colgar
  la suite si la acción no llega nunca.
- Depende de tener control sobre los efectos → se apoya en el **punto 3** (cancelación /
  ejecución determinista de efectos). Hacer este punto **después** del 3.

**Criterio de aceptación.**
- `receive` no usa `sleep` en el camino feliz.
- El timeout sigue produciendo un fallo de test claro (no crash).

**Tests de regresión.** Test que reciba una acción emitida por un `.task` y otra por un
`.publish`, verificando estado resultante.

---

## 3. Cancelación de efectos ⬜

**Problema.** `.task` hace `Task { … }` y **descarta el handle** → imposible de cancelar.
`.publish` guarda el cancellable por `UUID` pero no hay API pública para cancelar por
identidad. Sin cancellation IDs no hay debounce, ni "cancela la búsqueda anterior", ni
cancelar al desaparecer la vista.

**Archivos.**
- `Sources/xRedux/Effect.swift`
- `Sources/xRedux/Store.swift`

**Enfoque.**
- Añadir identidad de cancelación a `Effect`:
  - `case cancellable(id: AnyHashable, Effect<Action>)` (o un envoltorio `.cancel(id:)`).
  - Nuevo caso `case cancel(AnyHashable)` que cancela un efecto en vuelo por id.
- En `Store`:
  - Cambiar el diccionario de cancellables a estar **keyed por la id de cancelación**
    (además del `UUID` interno), de modo que lanzar un efecto con la misma id cancele el
    anterior.
  - Guardar el `Task` de `.task` (hoy fire-and-forget) para poder cancelarlo; cancelar en
    `deinit` del store todos los efectos en vuelo.
  - Encadenar la cancelación de estructura: cancelar padre → cancelar hijos.
- Asegurar que `Effect.map` propaga la identidad de cancelación intacta.

**Criterio de aceptación.**
- Un efecto lanzado con id `X` cancela cualquier efecto previo con id `X`.
- `store.send(.cancel(X))` detiene un efecto en vuelo.
- Al destruirse el store, no quedan tasks corriendo.

**Tests de regresión.** Test de debounce (dos envíos rápidos con misma id → solo el
último emite) y test de cancelación explícita.

---

## 4. `ActionResult`: no comparar errores por `localizedDescription` ✅

**Problema.** `Equatable`/`Hashable` de `ActionResult` comparan errores por
`localizedDescription`: dos errores distintos con igual texto son "iguales" y depende del
locale. Bomba de relojería para tests.

**Archivos.**
- `Sources/xRedux/ActionResult.swift`

**Decisión tomada:** opción A — **error tipado**. `ActionResult<Success, Failure: Error>`
con comparación real de errores cuando `Failure: Equatable`. Rompe la firma pública
(aceptado: versión mayor). Cada call site declara su tipo de error.

**Criterio de aceptación.**
- Dos errores de tipos distintos con la misma descripción **no** son iguales.
- Los call sites del `GroceryApp` compilan (ajustar si se elige A).

**Tests de regresión.** Test con dos tipos de error de descripción idéntica →
`!=`.

---

## 5. `AppAlert`: identidad e `id` robustos + binding de dismiss ✅

**Problema.** `id = title + message + botones` → dos alertas con el mismo texto colisionan,
y el `Equatable` depende de eso (SwiftUI puede no re-presentar). El `alertBinding` tiene
el setter vacío → un dismiss del sistema deja estado obsoleto.

**Archivos.**
- `Sources/xRedux/Bindings/AppAlert.swift`

**Enfoque.**
- Dar a `AppAlert` un `id: UUID` propio generado en `init` (identidad estable e única).
- `Equatable` por `id` (o por contenido explícito, sin depender del `id` derivado).
- `alertBinding`: en el `set`, cuando SwiftUI pase `nil` (dismiss), enviar una acción de
  dismiss al store en lugar de ignorarlo. Requiere una forma de mapear "dismiss" a una
  acción (p. ej. añadir un `dismissAction` opcional al protocolo `AppAlertState` o a la
  propia alerta).

**Criterio de aceptación.**
- Dos alertas con idéntico texto tienen `id` distinto.
- Descartar la alerta actualiza el estado del store.

**Tests de regresión.** Test de unicidad de `id` y de propagación del dismiss.

---

## 6. Composición de reducers: helper `Scope`/pullback ⬜

**Problema.** La composición es manual: `sharedReducer.reduce(&state.shared, a).map { .shared($0) }`.
Funciona, pero el boilerplate crece con cada feature anidada.

**Archivos.**
- `Sources/xRedux/` (nuevo `Scope.swift` o extensión en `Reducer`)
- Refactor de ejemplo en `Examples/GroceryApp/.../ItemsReducer.swift`,
  `ListsReducer.swift`.

**Enfoque.**
- Añadir un helper de scoping que dado un `WritableKeyPath` al sub-estado y un
  `CasePath`/embed+extract para la sub-acción, ejecute el child reducer y haga el `.map`
  automáticamente. Sin dependencias externas → implementar un mini "case path"
  (embed: `(ChildAction) -> Action`, extract: `(Action) -> ChildAction?`).
- Refactorizar `ItemsReducer`/`ListsReducer` para usarlo y validar la ergonomía.

**Criterio de aceptación.**
- El ejemplo compila usando el helper con menos boilerplate y mismo comportamiento.
- Tests del `GroceryApp` siguen verdes.

**Tests de regresión.** Test del helper de scope (acción del hijo modifica sub-estado;
acción ajena se ignora).

---

## 7. Inyección de dependencias ⬜

**Problema.** Las dependencias (use cases) se pasan a mano por `init`. Sin environment ni
override para tests → mocks manuales. Es el cambio más estructural.

**Archivos.**
- `Sources/xRedux/` (nuevo mecanismo de dependencias)
- Refactor de use cases del `GroceryApp`.

**Decisión tomada:** opción A — **environment explícito**. Dependencias como propiedad
tipada del reducer; override en tests construyendo el reducer con mocks. Simple, sin magia,
encaja con el diseño actual.

**Criterio de aceptación.**
- Un reducer puede resolver dependencias sin conocer implementaciones concretas.
- En tests se inyectan mocks sin construir todo el grafo a mano.

**Tests de regresión.** Reducer con dependencia mockeada verificando efecto.

---

## Orden de ejecución recomendado

1. **Punto 1** (TestStore sin `precondition`) — barato, máxima credibilidad. Cada punto
   posterior necesita un TestStore que no crashee.
2. **Punto 4** (errores en `ActionResult`) — pequeño, aislado.
3. **Punto 5** (`AppAlert`) — aislado.
4. **Punto 3** (cancelación de efectos) — núcleo; habilita el punto 2.
5. **Punto 2** (`receive` sin polling) — depende del 3.
6. **Punto 6** (composición / `Scope`).
7. **Punto 7** (inyección de dependencias) — el más estructural, al final.

Cada punto: rama propia desde `main`, implementación + test de regresión, tests en verde
antes de proponer commit.

---

## Decisiones tomadas

- **Punto 4:** error tipado (`Failure` genérico). Comparación real de errores.
- **Punto 7:** environment explícito por reducer (sin registro global).
- **Compatibilidad:** se puede **romper API pública** → versión mayor (2.0.0).

## Pendiente (no bloquea código)

- **Licencia:** decisión pendiente de la revisión (MIT vs. privado).
