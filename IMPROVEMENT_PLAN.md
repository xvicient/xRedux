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

## 2. `TestStore.receive`: eliminar el polling con `Task.sleep` ✅

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

## 3. Cancelación de efectos (interna) ✅

> **Nota de alcance:** este punto se redujo respecto al plan original. La cancelación
> por id (debounce, latest-wins) se descartó para no contaminar `Effect`. Queda solo la
> gestión interna del ciclo de vida de los efectos.


**Problema.** `.task` hace `Task { … }` y **descarta el handle** → imposible de cancelar;
sobrevive al store. `.publish` guardaba el cancellable por `UUID`, pero los tasks no se
gestionaban.

**Restricción de diseño (decidida durante la implementación).** `Effect` es la superficie
que ven los reducers: debe quedarse **solo** con `none`/`publish`/`task`. No se exponen
`cancellable`/`cancel` como cases del enum — un reducer no debe poder ejecutarlos. La
cancelación es **maquinaria interna del `Store`**. Como corolario, NO hay API pública de
cancelación por id (debounce / "cancela la búsqueda anterior" queda fuera de alcance por
ahora; se puede añadir más tarde por un canal que no sea `Effect`).

**Archivos.**
- `Sources/xRedux/Store.swift` (sin cambios en `Effect.swift`).

**Enfoque aplicado.**
- `Store` lleva `running: [UUID: RunningEffect]`, donde `RunningEffect` envuelve una
  `AnyCancellable` (publish) o un `Task` (task), y ambos saben `cancel()`.
- Cada efecto se registra al arrancar y se elimina al completarse (completion del
  publisher / fin del task).
- `deinit` cancela todo lo que quede en vuelo → nada sobrevive al store.

**Criterio de aceptación.**
- Al destruirse el store, no quedan tasks corriendo. ✅

**Tests de regresión.** `StoreTests.inFlightTaskCancelledOnDeinit`: un `.task` suspendido
observa la cancelación (vía `withTaskCancellationHandler`) en cuanto el store se libera.

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
