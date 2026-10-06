---
date: 2026-10-06
model: GPT-6
version: 1
description: "Spec: region-композиция skins, предварительная проверка и публичное описание содержимого."
---

# Spec: Skin composition

Спецификация реализует [принятый ADR](adr.md) и [задание](task.md). Кодовая основа — `52e713e6458963ed6723b6cacf829352c4cd0e76`; изменения реализации ещё не выполнены.

## Goal

Добавить композицию region-предметов на существующем Skeleton compiled-пути без прерывания анимации. Предоставить на asset проверку комплекта без применения и описание собственных записей skins. Сохранить существующие single-skin, legacy и mesh/physics-контракты.

## Glossary

- **Ключ** — пара имени слота и логического имени attachment (placeholder), не путь текстуры.
- **База** — выбранный single skin поверх `default`; фиксируется при входе в композицию.
- **Слой** — одна операция дополнения, полной замены выбранных слотов или скрытия выбранных слотов.
- **Запрос** — последнее логическое имя от setup/attachment timeline, включая nil; сохраняется независимо от видимости.
- **Результат** — разрешённый compiled attachment ID либо отсутствие изображения.
- **Защищённый слот** — слот, имеющий в разрешённой базе хотя бы одно не-region состояние.
- **Prepare** — существующая финальная подготовка изображения после actions/physics/ручных изменений.

## Contract

### 1. Публичное описание комплекта

Новый файл `Sources/Spine/Skins/SpineSkinComposition.swift`; ниже объявления API, тела опущены.

```swift
public struct SpineSkinComposition: Equatable {
    public let baseSkin: String
    public let layers: [SpineSkinLayer]
    public init(baseSkin: String, layers: [SpineSkinLayer])
}
public enum SpineSkinLayer: Equatable {
    case overlay(skin: String)
    case replace(skin: String, slots: [String])
    case hide(slots: [String])
}
public extension SpineMeshAsset {
    func validate(skinComposition: SpineSkinComposition) throws
    func skinDescription(named: String) throws -> SpineSkinDescription
}
public extension Skeleton {
    var skinComposition: SpineSkinComposition? { get }
    func apply(skinComposition: SpineSkinComposition) throws
}
```

### 2. Публичные метаданные

Новый файл `Sources/Spine/Skins/SpineSkinDescription.swift`. Типы результатов создаёт библиотека; публичные конструкторы не нужны.

```swift
public enum SpineSkinAttachmentKind: String, Equatable {
    case region, mesh, linkedMesh, point, boundingBox
}
public struct SpineSkinEntry: Equatable {
    public let slot: String
    public let name: String       // ключ placeholder, не filename и не path
    public let kind: SpineSkinAttachmentKind
}
public struct SpineSkinDescription: Equatable {
    public let name: String
    public let entries: [SpineSkinEntry]
}
```

### 3. Ошибки и адреса

Расширить существующий `SpineRuntimeError.Code`, сохранив старые cases и их raw values. `message` человекочитаемое, его полный текст не является контрактом. Адреса — JSON Pointer, индексы с нуля, компоненты имён экранируют `~` и `/` как `~0` и `~1`.

```text
code                         path
missingSkin                  /composition/baseSkin
missingSkin                  /composition/layers/{i}/skin
missingSkin                  /skins/{skin}                  # skinDescription
invalidSkinComposition       /composition/layers/{i}/slots  # пустой массив
invalidSkinComposition       /composition/layers/{i}/slots/{j} # повтор слота
missingSlot                  /composition/layers/{i}/slots/{j}
unsupportedFeature           /composition/layers/{i}/slots/{slot} # защищённая база
unsupportedFeature           /composition/layers/{i}/attachments/{slot}/{name}
incompleteSkinComposition    /composition/layers/{i}/attachments/{slot}/{name}
skinCompositionBaseMismatch  /composition/baseSkin
unsupportedFeature           /runtime/skinComposition        # legacy instance
```

Новые cases: `invalidSkinComposition`, `missingSlot`, `incompleteSkinComposition`, `skinCompositionBaseMismatch`. Диагностика недостающего состояния называет skin, слот, placeholder и источник требования (`setup` либо имя клипа); неподдерживаемого типа — skin, ключ и тип.

### 4. Клиентский сценарий только с public API

Файл-пример в `Sources/Spine/Documentation.docc/Skins.md`; имена соответствуют fixture из Contract.5.

```swift
import Spine

func dress(_ skeleton: Skeleton, asset: SpineMeshAsset) throws {
    let clothes = SpineSkinLayer.replace(skin: "clothes/a", slots: ["torso", "sleeves"])
    let hat = SpineSkinLayer.replace(skin: "hat/a", slots: ["hat-front", "hat-back"])
    let team = SpineSkinLayer.overlay(skin: "team/blue")
    let look = SpineSkinComposition(baseSkin: "base", layers: [
        clothes, hat, .hide(slots: ["bandana", "earring"]), team
    ])
    try asset.validate(skinComposition: look) // CI: Skeleton не нужен
    let contents = try asset.skinDescription(named: "hat/a")
    _ = contents.entries.map { ($0.slot, $0.name, $0.kind) }
    try skeleton.apply(skinComposition: look) // создан с skin: "base"
    let saved = skeleton.skinComposition!
    try skeleton.apply(skinComposition: .init(baseSkin: "base", layers: [
        clothes, .replace(skin: "hat/b", slots: ["hat-front", "hat-back"]),
        .hide(slots: ["bandana"]), team // серьга возвращается по текущему запросу
    ]))
    try skeleton.apply(skinComposition: saved)
    try skeleton.apply(skinComposition: .init(baseSkin: "base", layers: []))
    try skeleton.apply(skin: "base") // выход из композиции
}
```

### 5. Артефакты проверки и запуска

```text
Tests/SpineTests/Resources/Mesh41/skin-composition/  # собственные JSON/PNG
  wardrobe.json           # base, hat/a,b, clothes/a,b, team/blue,orange,purple,pink
                          # hat-front,hat-back,torso,sleeves,bandana,earring,team
                          # минимум front/side в одном slot; setup nil; events/color/drawOrder
  mixed.json              # region + mesh/linked mesh/deform + point + static box
  README.md               # происхождение, имена, состояния, команды воспроизведения
Tests/SpineTests/Skins/    # новые unit/integration/public-client tests
Examples/SkinComposition/ # запускаемая macOS/iOS SpriteKit-проба и README
features/skin-composition/validation/
  report.md               # commit, команды, тесты, устройства, ограничения
  measurements.json       # schema ниже; реальные данные, не придуманные бюджеты
  captures/               # изображения, записи воспроизведения
```

```json
{
  "schemaVersion": 1,
  "sourceCommit": "<commit>",
  "releaseGate": "pending",
  "targets": [],
  "workload": {"maxSkeletons": null, "switchesPerSecond": null, "catalogItems": null, "teamVariants": 4},
  "budgets": {"applyP95Ms": null, "prepareP95Ms": null, "assetResidentBytes": null, "peakSwitchBytes": null},
  "runs": []
}
```

## Rules

### C — Вход, база, совместимость

| # | Rule |
|---|---|
| C.1 | Публичные типы — immutable value types, без SpriteKit nodes/internal IDs; init комплекта не валидирует и не бросает. Все API доступны клиенту через `import Spine` при существующем Swift tools 5.5 и deployment targets. Getter возвращает nil до входа, после single-skin выхода и на legacy; после apply возвращает точно переданное описание. |
| C.2 | База разрешается как записи `default`, затем записи `baseSkin` по ключу. Отсутствие `default` даёт пустой fallback; `baseSkin` обязан существовать в `asset.skinNames`. Существующий синтетический пустой `default` для asset без skins считается допустимым. Имена регистрозависимы, не обрезаются и не нормализуются. |
| C.3 | При входе `baseSkin` совпадает с текущим selected single skin; в композиции — с зафиксированной базой. Иное имя даёт `skinCompositionBaseMismatch` после успешной проверки контента. Новый API не переключает базу. Пустые layers входят/остаются в композиции с базой и текущими запросами, а не сбрасывают setup. |
| C.4 | Последовательность layers значима; повтор skins и явный overlay `default` допустимы. Пустой overlay skin — no-op. У replace/hide пустой slots или повтор имени слота — ошибка. Разные операции над одним слотом выражаются разными слоями, а не порядком обхода словаря. |
| C.5 | Повтор точно равного активного descriptor — no-op: нет аллокаций renderer-узлов, смены references, времени или событий. Равенство structural: порядок slots тоже участвует; семантически эквивалентные, но не равные описания могут пересоздать затронутые regions. |
| C.6 | Успешные существующие `apply(skin:)`, `applyDefaultSkin()` и выполняющий их action завершают композицию даже при совпадении имени базы; ошибка сохраняет её. Выход обходит старый early return по совпадению selectedSkin: для каждого слота использует эффективный `activeName` композиции, затем старый setup fallback/none, и синхронизирует запрос с фактически выбранным именем (либо nil). Скрытый композицией слот поэтому может восстановить setup; это single-skin переход, не снятие hide новым descriptor. Далее действуют старые single-skin правила. Старые action validation/подавление ошибки не расширяются на новый API. Legacy apply composition бросает unsupportedFeature без изменений; его прежние API сохраняются. |

### L — Разрешение слоёв и полнота

| # | Rule |
|---|---|
| L.1 | overlay берёт все собственные записи указанного skin, без добавления его fallback, и заменяет совпадающие ключи результата. Другие ключи сохраняются. Имена slots и keys всегда берутся из compiled asset, не PNG. |
| L.2 | replace для каждого указанного slots удаляет все накопленные ключи слота и устанавливает только собственные записи указанного skin для этого слота. Записи skin вне slots игнорируются этой операцией. Каждый указанный слот существует; наличие нуля записей допустимо только при пустом множестве обязательных состояний по L.4. |
| L.3 | hide удаляет все ключи слота и запрещает fallback для него. Последующий overlay открывает лишь свои ключи, последующий replace задаёт слот заново; остальные имена не восстанавливаются. Итоговый lookup применяется без дополнительного обращения к default. Удаление hide из полного descriptor пересобирает результат от базы. |
| L.4 | Для replace обязательны все ненулевые setup/attachment-timeline имена данного слота во всех compiled clips. Каждый replace проверяется самостоятельно по собственным записям skin; предыдущие/последующие слои, включая hide, не исправляют неполноту. Nil не требует картинки. Нетронутая база и overlay не проходят новую проверку полноты. |
| L.5 | Типы проверяются для каждого слоя даже если его перекроют позднее. Любое касание защищённого слота — ошибка, включая hide и фактический no-op overlay. Защита определяется по разрешённой базе, после её override default, а не по всем skins asset. |
| L.6 | Все вводимые записи overlay и выбранных replace-slots имеют тип region. Mesh/linked mesh/point/box там отклоняются независимо от текущей видимости; невыбранные записи replace и ненадетые skins ограничение не расширяют. Поддержка остальных типов в базе и single-skin остаётся прежней. |
| L.7 | При разрешении затронутого слота или при setup/timeline sample в режиме композиции результат отсутствует при запросе nil или имени без ключа. Автоматического выбора setup вместо него нет. Если результат отсутствует из-за hide, запрос сохраняется; снятие hide использует последний запрос, в том числе изменившийся во время скрытия. Порядок слоёв не меняет slot/draw-order depth. |

### V — Проверка и описание контента

| # | Rule |
|---|---|
| V.1 | `validate` и apply используют один resolver и одинаковые content errors на одинаковых asset/descriptor. validate не создаёт Skeleton, SKNode, SKPhysicsBody, renderer или SKAction, не вызывает texture provider/повторную компиляцию и не меняет asset/живые экземпляры. Создание самого asset и его ресурсов остаётся отдельным предварительным этапом. |
| V.2 | Validation возвращает Void при успехе, бросает первую ошибку. Порядок: база; слои слева направо; имя skin (если есть); структура/существование slots по порядку входа; защищённые слоты; вводимые типы; полнота. Последние три стадии обходят slots в setup-порядке и keys по Swift `String.<`; при нескольких источниках требования message указывает setup, иначе первый клип по имени. |
| V.3 | Пути/code соответствуют Contract.3; имена в path экранированы. Ошибки контента синхронно throws; новый API не скрывает их через `try?`, не пишет playbackError/frameError и не вызывает meshDiagnosticHandler. Ошибки compilation и существующих frame/playback incidents сохраняют старый контракт. |
| V.4 | skinDescription возвращает собственные записи skin, упорядоченные по setup slot index, затем имени ключа; пустой skin возвращает []. Никакого default fallback, mutable buffers и текстур в metadata. Исходный linkedMesh отличается от mesh даже после разрешения геометрии; чтение повторяемо и не создаёт nodes. |
| V.5 | Предмет проверяется как descriptor фиксированной базы с его слоями; редактирование/переэкспорт клипов создаёт новый asset, после чего CI заново проверяет все replace-слои. Переключение проигрываемого клипа на том же immutable asset не запускает новую validation и не имеет нового отказа полноты. Проверка целого комплекта учитывает порядок, но намеренные пересечения не считает ошибкой. Клиентский пример CI сверяет metadata и заявленные replace/hide области, отдельно отклоняет запрещённые каталогом пересечения; библиотека не перебирает комбинации товаров. |

### A — Состояние, применение и кадр

| # | Rule |
|---|---|
| A.1 | Setup и каждый attachment sample сохраняют логический запрос до lookup, даже при неизвестном имени, nil или скрытии. Этот запрос отслеживается и до первого входа в композицию. Существующий single-skin apply сохраняет прежний fallback и заменяет запрос выбранным им результатом, включая nil; прежний запрос timeline после такого fallback не восстанавливается. Старый no-op сохраняется только когда композиция уже не активна. Выход из неё всегда следует C.6. |
| A.2 | Первый вход не пересэмплирует и не переоценивает нетронутые слоты, включая protected: их effective state остаётся прежним, а последующие setup/timeline samples следуют L.7. После предшествующего single-skin fallback запрос уже синхронизирован по A.1; неизвестный запрос с nil effective также сохраняется до следующего разрешения. Composition apply разрешает запросы только в затронутых слотах: объединение областей прежних и новых слоёв, включая возврат к базе. Поза костей, slot color, draw order, время, epoch/execution, event/attachment/deform cursors, скорость, пауза, actions и completion не меняются. Sampling клипа для переодевания не вызывается. |
| A.3 | Сначала полностью разрешить/проверить content, затем проверить совпадение базы, подготовить region records и next states без live writes, затем выполнить не бросающий commit без внешних callbacks. Любая recoverable ошибка до commit сохраняет descriptor, дерево, references, state и playback. OOM/process termination не входят в rollback. Тестовый internal failure injection после подготовки части новых nodes проверяет откат staging. |
| A.4 | Во время композиции и первого входа неизменны нетронутые slot-state/physics provenance, mesh nodes/буферы/deformSourceID/deform, point nodes, bodies/их свойства и родители. Нет transient detach/reattach тел. Общие proxy bones могут дополняться для новых regions, но существующие цепочки нетронутых records не переустанавливаются; удаление неиспользуемых proxies не накапливает дерево. |
| A.5 | Изменяемые region records могут пересоздаваться; старые nodes отсоединяются, library-owned ссылки на них очищаются. Внешне удержанный старый node остаётся detached и больше не управляет Skeleton. Skeleton/bone/slot identity сохраняются. Для нетронутого смешанного слота с region+не-region сохраняются все его records, не только активный. |
| A.6 | Новый descriptor/lookup публикуется целиком. В кадре после успешного prepare видны все изменения, текущие transforms/color/alpha/draw order; до prepare новое изображение не гарантируется. Apply не выполняет physics reconciliation/prepare; ошибки окружения кадра не откатывают descriptor. Существующие playback/frame-error и singular visibility flags при apply не очищаются. |
| A.7 | Вызовы на owner сериализованы с SpriteKit update, разрешены вне update при сериализованной паузе и из Spine event callback; во время prepare/physics callbacks и конкурентно — вне контракта. Нет нового фонового потока, delegate hook, автоматического frame guard или обещания thread safety asset/resources. Validate требует отдельного сериализованного доступа к asset. |
| A.8 | Event callback может несколько раз сменить комплект; последнее успешное применение действует сразу для дальнейших callbacks, ошибка оставляет последнее успешное. Event cursor уже продвинут, события равного времени/финальное событие не повторяются, completion выполняется однократно. Stop/restart из callback сохраняет старые epoch/execution guards; composition не отменяет их. |
| A.9 | Begin/repeat/setup reset разрешают setup и последующие timeline-запросы через текущую композицию; цвет/draw order сбрасываются только по существующему контракту reset. Stop(false) и завершение сохраняют запросы/комплект, stop(true) сохраняет комплект и устанавливает setup. На паузе apply+prepare работает без продвижения времени. |
| A.10 | Каждый Skeleton владеет descriptor, lookup и mutable состоянием; общий asset/материалы не изменяются. При смене нет повторного decode/compile/texture-provider вызова и нет кэша всех комбинаций. Поведение существующего prepare, bounded static physics и action ownership из mesh spec не ослабляется. |

### D — Поставка и evidence

| # | Rule |
|---|---|
| D.1 | Fixture Contract.5 самодостаточен, не читает pirates или сетевые ассеты; содержит все комбинации 2 шляпы × 2 одежды × серьга да/нет × 4 команды, body+рукава и перед/зад шляпы. Отдельные варианты покрывают отсутствие default, пустой asset, новый ключ редкого клипа, имена с `/` и `~`, смешанный защищённый слот. |
| D.2 | Документация показывает создание Skeleton с базой, независимую смену/снятие/восстановление, CI validation/metadata, ошибки, приоритеты, сроки жизни nodes и финальный prepare. Проба запускается по README на macOS и iOS и позволяет pause/speed/repeat/reset, смену из события и два Skeleton на общем asset. |
| D.3 | Отдельный клиентский тест с обычным `import Spine` компилирует Contract.4 и CI-пример, вызывает public validation/inspection и ловит новые error codes. Не используются `@testable` и internal fixture factories в этом файле; загружаются реальные JSON/PNG через public provider. |
| D.4 | После прогрева 100 смен выполняются 1 000 чередований и 1 000 повторов одинакового комплекта. На одинаковых возвратных точках количество nodes/bodies/proxies совпадает; weak refs старых region trees без внешних владельцев освобождаются после drain autorelease pool. Provider/compile counts не увеличиваются; память полного asset, steady state и пик переключения измеряются отдельно. |
| D.5 | Measurements заполняются commit/ОС/model/build/нагрузкой/числом состояний и сырыми samples apply+prepare отдельно, median/p95/max для cold/repeat/alternating. Поля null и пустые targets допустимы только при releaseGate=pending. Перед выпуском владелец задаёт targets/workload, разработчик фиксирует численные budgets и pass/fail для каждого target; отсутствие входных данных блокирует выпуск, но не функциональные фазы. |
| D.6 | macOS и физический iPhone: кадры сразу после apply+prepare совпадают с контрольным Skeleton на той же позе/запросах/комплекте; одинаковые пиксели RGBA на одном backend, отдельные baseline каждого устройства. Матрица включает nil, цвет, draw order, паузу и callback; видео подтверждает отсутствие скачка фазы. Нет коррекции sRGB/alpha ради прохождения. Старые geometry/image/physics критерии mesh spec сохраняются. |

## Out of scope

- Атомарная смена базы вместе с комплектом; композиция legacy; отдельный composition SKAction.
- Сменные mesh/deform/point/physics предметы, точечное скрытие placeholder, добавление bones/constraints/clipping.
- Linux или полностью безресурсный CLI-валидатор; загрузка отдельного предмета в существующий asset.
- Доставка/версии пакетов, миграция живого персонажа, магазин, сохранение экипировки и автоматический fallback товара.
- Игровой каталог, его правила конфликтов и художественная приёмка командной читаемости; библиотека предоставляет metadata и примеры проверок.
- Tint/palette, новый renderer, mixing/seek, публичные поля EventModel.

## Tests

Пути новых suites относительно `Tests/SpineTests/Skins/`; существующие suites указаны относительно `Tests/SpineTests/`. Все новые automated tests исполняются на macOS, runtime-набор также на iOS.

| # | Where | Asserts | Maps to |
|---|---|---|---|
| 1 | `CompositionPublicAPITests.swift` | Public constructors/getter, imports, пример смены/возврата, error catching, реальные ресурсы | C.1, D.3 |
| 2 | `CompositionResolverTests.swift` | База/default/no-default/empty asset, case sensitivity, nil setup, ключ отличается от PNG | C.2, L.1, D.1 |
| 3 | `CompositionResolverTests.swift` | Порядок, повтор skin/default, пустой overlay, duplicate/empty/unknown slots, selected replace subset | C.4, L.1, L.2 |
| 4 | `CompositionResolverTests.swift` | Overlay→hide→overlay/replace, удаление hide, разных имён одного слота нет в fallback | L.3, L.7 |
| 5 | `CompositionValidationTests.swift` | Полнота каждого replace для setup/всех clips, редкий новый ключ, nil, пустое required set; последующий hide/overlay не спасает | L.4, V.5, D.1 |
| 6 | `CompositionValidationTests.swift` | Все типы, inactive protected state, overlay no-op на protected, default перекрыт базой, проигнорированные replace записи, shadowed invalid слой | L.5, L.6 |
| 7 | `CompositionValidationTests.swift` | First-error order, точные code/path, escaping, одинаковые content errors validate/apply, отсутствие diagnostics/playback fault | V.1, V.2, V.3 |
| 8 | `SkinDescriptionTests.swift` | Raw own entries, стабильный порядок, пустые skins, mesh против linked chain, unknown name; чтение/validate без nodes/provider/compile | V.1, V.4 |
| 9 | `CompositionTransitionTests.swift` | Первый вход, неверная база, empty layers, getter nil; hide→same-base single выход→re-entry без sample проверяет effective/request/setup, ошибки выхода и legacy | C.1, C.3, C.6 |
| 10 | `CompositionPlaybackTests.swift` | Запрос до входа/во время hide, неизвестное имя, nil, current state != setup; single-skin fallback→первый вход с empty/другим слоем сохраняет effective/request нетронутого и protected слота; снятие hide на паузе | L.7, A.1, A.2, A.9 |
| 11 | `CompositionAtomicityTests.swift` | Ошибка позднего слоя, wrong base и staged node failure: точные identity/state/event snapshots до/после, освобождение staging | C.3, A.3, V.3 |
| 12 | `CompositionMixedBaseTests.swift` | Нетронутые region/mesh/linked/point/body/provenance identity; bodies не detach; deform и protected mixed slot; proxy lifetime | A.4, A.5, A.10, L.5, L.6 |
| 13 | `CompositionPlaybackTests.swift` + native probe | Repeat/start/end, stop обоих видов, сохранение phase/color/order/speed/pause/actions, reset не стирает комплект | A.2, A.9 |
| 14 | `CompositionEventTests.swift` + native probe | Несколько событий одного времени, смена+ошибка+смена, end-event, completion once, stop/restart guards | A.8, A.2 |
| 15 | `CompositionFrameTests.swift` | Apply→prepare, late apply→repeat prepare, frame/playback fault не очищается, singular, RGBA и depth | A.6, L.7, A.10 |
| 16 | `CompositionLifetimeTests.swift` | Exact descriptor no-op, structural equality, detached external ref, 100/1000 cycles, resources и два независимых owners | C.5, A.5, A.10, D.4 |
| 17 | `Mesh/` и существующие legacy suites | Прежние single fallback, action ownership, geometry, images, physics P.1–P.7, lifetime без регрессий | C.6, A.10 |
| 18 | DocC/README review + CI client fixture | Команды запуска, public примеры, 32 комплекта, каталог отдельно ловит запрещённый конфликт; serial-access contract документирован | D.1, D.2, V.5, A.7 |
| 19 | `Examples/SkinComposition/` + `validation/` | macOS/iPhone screenshots/video и native lifecycle; memory/timing samples и target-specific release gate | D.4, D.5, D.6 |

## Execution

### Lock

- Implementation branch: `codex/skin-composition`; не писать реализацию в `master`. Создать отдельную ветку/checkout при старте реализации; документы этой сессии не являются началом реализации.
- Preflight: проверить `git status`, актуальную ревизию, AGENTS и отсутствие параллельных пользовательских изменений; сохранить их. Существующей реализации composition/validation/inspection на проверенной ревизии нет; `docs/tech-debt.md` отсутствует.
- [Mesh spec](../mesh-support/spec.md) A.7 остаётся правилом single-skin; новые L/A действуют в composition. G.5/P.1–P.7 не меняются: composition не меняет bodies защищённых слотов. Если кодовая база изменилась, повторить проверку конфликтов до правок.
- Каждая фаза заканчивается указанными тестами и полной `swift test` на macOS, `swift build`; commits только на green. iOS native/device evidence требуется в фазе 5. Red baseline фиксируется и устраняется либо явно блокирует gate; не выдавать skipped tests за pass.

### Phase 1 — Проверяемый каталог и публичные данные

**Objective.** Клиент без Skeleton читает skins и проверяет комплект на compiled asset.
**Work.**
- Добавить public value types и metadata исходного типа до свёртки linked meshes в `MeshAssetCompiler`/`CompiledAttachment`; сохранить старые construction paths/tests.
- Добавить единый pure resolver `Sources/Spine/Skins/SkinCompositionResolver.swift`: база, required states, защита, layers, first-error paths. Собрать fixtures и CI public пример.
**Dependencies.** Принятый ADR; существующий compiled asset.
**Risks.** Потеря linked metadata — проверка исходного типа на этапе compilation; расхождение validation/apply — результат resolver используется runtime без второй реализации правил.
**Validation.** Tests 2–8 и часть 1/18 для asset API; full suite green.
**Done.** Validation обнаруживает несовместимость старого предмета после нового ключа без создания Skeleton.

### Phase 2 — Атомарная смена на смешанной базе

**Objective.** Одна region-операция работает посреди клипа без повреждения неизменяемых областей.
**Work.**
- Добавить tracking запроса и composition state в `MeshRuntime`/`MeshSlotState`, public Skeleton API и transitions.
- Изменить `MeshSetupRenderer` на подготовку/commit region records с сохранением нетронутых records/proxies/points/bodies; убрать независимый skin merge из composition-пути.
- Ввести staging failure injection для тестов; защитить границу commit от throws/callbacks и очистить старые region references.
**Dependencies.** Phase 1 resolver/metadata.
**Risks.** `MeshSlotPhysicsState` имеет reference identity: копии slot state не изолируют её — staging её не мутирует; rebuild всего дерева — запрет detach защищённых nodes проверяется тестом.
**Validation.** Tests 1, 9–12, 15–17, включая rollback; full suite green.
**Done.** Region меняется на общем asset, body/point/mesh identity и deform соседних слотов остаются прежними.

### Phase 3 — Границы проигрывания и обратная совместимость

**Objective.** Полный жизненный цикл сохраняет комплект и единственное проигрывание событий.
**Work.**
- Провести composition через begin/sample/restoreSetup/stop/end; реализовать выход same-base через старые skins API.
- Проверить callback последнего события, несколько событий одного времени, паузу, native speed и stop/restart; завершить документацию сериализации/prepare.
**Dependencies.** Phase 2 transaction.
**Risks.** Повторный sampling/смена epoch — snapshots event cursors и native completion; старый early return single-skin — отдельная проверка выхода при одинаковом имени.
**Validation.** Tests 9–17 и native часть 13–14; full suite green.
**Done.** Смена одежды из callback и на паузе проходит без повторных событий и сброса позы.

### Phase 4 — Публичные примеры, каталог и контроль ресурсов

**Objective.** Внешний клиент воспроизводит гардероб и CI-проверку без internal-доступа.
**Work.**
- Завершить DocC и `Examples/SkinComposition`, public test и проверку всех fixture-комплектов; добавить примеры проверки областей/конфликтов каталога.
- Провести weak-reference/node/provider counters и 100/1000 циклы; подготовить сбор сырых measurements.
**Dependencies.** Phases 1–3.
**Risks.** Удержания тестовым harness — weak refs после drain без внешних владельцев; рост proxy дерева — сравнение одинаковых возвратных точек.
**Validation.** Tests 1, 8, 16, 18 и automated 1–17 целиком; full suite green.
**Done.** Самодостаточный пример запускается, public контракт используется обычным клиентским модулем, старые деревья освобождаются.

### Phase 5 — Изображение, устройства и выпуск

**Objective.** Получить воспроизводимые image/native/performance evidence и закрыть release gate.
**Work.**
- Снять контрольные кадры и native playback на macOS/физическом iPhone; сохранить raw data, commit и команды.
- Получить targets/workload игры, измерить полный каталог и совместно зафиксировать численные бюджеты до оценки pass/fail; проверить memory peak и все режимы переключения.
**Dependencies.** Phase 4; физический iPhone; входные данные владельца для release gate.
**Risks.** Нет устройства или нагрузки — оставить gate pending, не объявлять выпуск; exceeded budget — оптимизация в границах контракта и повтор затронутых проверок, при смене архитектуры новый ADR.
**Validation.** Tests 1–19, full suite green, старые mesh platform/image/physics gates; полный отчёт с pass/fail, без подмены physical-device simulator evidence.
**Done.** Все targets имеют заполненные бюджеты и положительные результаты; releaseGate=passed.

## Done criteria

- Публичные объявления Contract.1–4 реализованы; все Rules связаны с Tests и все tests 1–19 пройдены с evidence.
- Нет изменения legacy/single-skin поведения; mixed-base identity/physics/deform и reentrant playback подтверждены.
- Fixtures, DocC, запускаемый пример и CI-validation пример доступны в репозитории без соседнего проекта.
- Ни один контентный отказ не меняет живой комплект; no-op и lifetime/resource gates пройдены.
- macOS и физический iPhone проверены, measurements/снимки/команды привязаны к итоговому commit, releaseGate=passed. До этого функциональные фазы могут быть готовы, но фича не считается выпущенной.
