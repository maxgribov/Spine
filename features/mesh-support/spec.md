---
date: 2026-10-03
model: GPT-6
version: 5
description: "Spec: opt-in Spine 4.1 meshes в SpriteKit с неизменным legacy API и единым загрузчиком JSON 4.1"
---

# Spec: интеграция Spine meshes в библиотеку

Реализует [ADR](adr.md). Существующие ESS-анимации 4.1 работают без изменений клиентского кода. Changes from v4: receiver mesh-aware clip-action обязан быть создавшим его Skeleton; чужой receiver исключён из гарантий, границы execution используют SKAction.run, а pause/speed проверяются в native SKView. [Основание принятого уточнения](validation/phase2-action-investigation.md). Сохраняются порядок последнего prepare и поэтапные validation gates v4. Текущая библиотека и fixtures уже используют 4.1; смена формата, второй загрузчик, глобальный version gate и breaking release не планируются. Production-интеграция meshes ещё не завершена; прототип остаётся эталоном.

Проверка формата: README уже указывает 4.1+, оба ESS/Pro fixtures — 4.1.17. Между официальными 4.0 и 4.1 подтверждены изменения deform hierarchy и linked inheritance flag; текущие mesh-модели остались частично на старой форме. Отсутствующие deform vertices разрешены в обеих версиях. [Аудит с pinned sources](validation/json-format-audit.json).

## Goal

Добавить явно включаемую поддержку meshes Spine 4.1 в `Skeleton`, сохранив обычные SKView/SKAction. Сохранить клиентский API и воспроизведение region-only анимаций поддерживаемого формата; доработать единый JSON decoder для Spine 4.1. Не ужесточать существующие входы JSON ради новой функциональности; ограничения возможностей проверять при явном включении meshes. Владелец времени — SpriteKit; библиотека рассчитывает геометрию и готовит её к отрисовке после действий/физики/ручных правок.

## Glossary

- **Legacy** — прежний режим воспроизведения Skeleton из существующих конструкторов; это не отдельная версия JSON-загрузчика.
- **Mesh-aware** — Skeleton, созданный только через новый `init(meshAsset:skin:)`.
- **Clip** — одна именованная Spine-анимация; обычный SKAction перемещения skeleton не является вторым clip.
- **Execution** — одно выполнение clip-action; repeat создаёт последовательные executions одного действия.
- **Owner** — Skeleton, создавший clip-action; обязательный receiver каждого запуска этого действия и его copies/containers.
- **Epoch** — поколение clip-actions экземпляра skeleton; остановка инвалидирует действия предыдущего поколения.
- **Canonical texture** — отдельная полная SKTexture с premultiplied RGBA; не скрытый subtexture внутреннего атласа SpriteKit.
- **Frame context** — преобразование из локальных координат skeleton в реальные fragment coordinates целевого framebuffer.

## Contract

### 1. Существующий API: сигнатуры и поддерживаемое поведение сохраняются, decoder один

```swift
// Существующие public surfaces, НЕ новые перегрузки с изменёнными defaults.
Skeleton.init(_ model: SpineModel, atlas folder: String? = nil)
Skeleton.init(_ model: SpineModel, _ atlases: [String: SKTextureAtlas])
Skeleton.init(json name: String, folder: String? = nil, skin: String? = nil) throws
Skeleton.action(animation name: String) throws -> SKAction
Skeleton.run(animation name: String) throws
Skeleton.apply(skin name: String) throws
Skeleton.action(applySkin name: String) throws -> SKAction
Skeleton.dropToDefaultsAction() -> SKAction
Skeleton.boneNode(named: String) -> SKSpriteNode?
Skeleton.slotNode(named: String) -> SKNode?
Skeleton.regionAttachmentNode(named: String) -> SKSpriteNode?
// Также сохраняются deprecated API, события, points/physics/atlases extensions,
// JSONDecoder().decode(SpineModel.self, from: data) и прямой доступ к region texture.
```

### 2. Новая проверяемая загрузка — `Sources/Spine/Mesh/SpineMeshAsset.swift`

```swift
public final class SpineMeshAsset {
    public convenience init(json: Data, textures: SpineMeshTextureProvider) throws
    public init(model: SpineModel, textures: SpineMeshTextureProvider) throws
    public var animationNames: [String] { get }
    public var skinNames: [String] { get }
}
public enum SkeletonRuntimeMode { case legacy, meshes }
public extension Skeleton {
    convenience init(meshAsset: SpineMeshAsset, skin: String? = nil) throws
    var runtimeMode: SkeletonRuntimeMode { get }
    var meshPlaybackError: SpineRuntimeError? { get }
    var meshDiagnosticHandler: ((SpineRuntimeError) -> Void)? { get set }
    func meshAttachmentNode(named: String, inSlot: String) -> SKNode? // inspect-only
    func stopMeshAnimation(resetToSetupPose: Bool = false)
    #if os(iOS) || os(macOS) || os(tvOS)
    func prepareMeshes(in view: SKView) throws
    #endif
    func prepareMeshes(for context: SpineMeshFrameContext) throws
}
// action(animation:), apply(skin:) и eventTriggered остаются точками входа и в новом режиме.
// Precondition: mesh clip-action и его copies/containers запускаются только на создавшем их Skeleton.
// Для другого Skeleton необходимо вызвать его собственный action(animation:).
```

### 3. Ресурсы — `Sources/Spine/Mesh/Resources/`

```swift
public protocol SpineMeshTextureProvider {
    func region(named path: String) throws -> SpineMeshTextureRegion
}
public struct SpineMeshTextureRegion {
    public let texture: SKTexture
    public let pixelSize: CGSize       // размер полной texture в пикселях
    public let originalSize: CGSize    // размер untrimmed attachment image
    public let trimRect: CGRect        // видимый прямоугольник в original image, origin bottom-left
    public let uvTransform: CGAffineTransform // untrimmed normalized UV bottom-left -> page UV bottom-left
    public init(texture: SKTexture, pixelSize: CGSize, originalSize: CGSize,
                trimRect: CGRect, uvTransform: CGAffineTransform) throws
}
public final class SpineAtlasTextureProvider: SpineMeshTextureProvider {
    public init(atlasText: String, pageData: [String: Data]) throws
    public func region(named path: String) throws -> SpineMeshTextureRegion
}
// SKTextureAtlas не подставляется автоматически вместо canonical texture.
// Custom provider материализует его изображение при загрузке и передаёт явные metadata.
```

### 4. Подготовка кадра и ошибки — `Sources/Spine/Mesh/Runtime/`

```swift
public struct SpineMeshFrameContext {
    // Maps skeleton-local points to gl_FragCoord.xy of THIS target.
    // Native Metal / SKRenderer: origin top-left, x right, y down, centers n+0.5.
    // SKView.texture capture: origin bottom-left, y up. Caller supplies actual convention.
    // Viewport/crop offsets and pixel density are already included in this matrix.
    public let skeletonToPixels: CGAffineTransform
    public let pixelSize: CGSize // whole framebuffer, positive integer pixels
    public init(skeletonToPixels: CGAffineTransform, pixelSize: CGSize)
}
public struct SpineRuntimeError: Error, LocalizedError {
    public enum Code: String {
        case unsupportedPlatform, unsupportedVersion, unsupportedFeature
        case invalidData, invalidGeometry, invalidTimeline, linkedMeshCycle, missingAttachment
        case missingTexture, invalidTextureRegion, missingSkin, missingAnimation
        case concurrentClip, invalidRenderContext, mutatedNodeContract
        case wrongSkeleton // reserved; наличие case не обещает проверки чужого receiver
    }
    public let code: Code
    public let path: String            // JSON Pointer; node/slot path для runtime ошибок
    public let message: String         // диагностический текст, не ключ для обработки ошибки
    public var errorDescription: String? { get }
}
// Example: skeleton (0,0) = bottom-left of a 200x100-point image at 2x density,
// full 400x200 Metal target: xPixel=2*x, yPixel=200-2*y.
let metalContext = SpineMeshFrameContext(
    skeletonToPixels: CGAffineTransform(a: 2,b: 0,c: 0,d: -2,tx: 0,ty: 200),
    pixelSize: CGSize(width: 400,height: 200))
// Clock не передаётся в prepareMeshes: вызов не продвигает анимацию.
let asset = try SpineMeshAsset(json: jsonData, textures: textureProvider)
let character = try Skeleton(meshAsset: asset, skin: "goblin")
scene.addChild(character)
// Action получает и запускает один и тот же character (обязательное предусловие).
character.run(.repeatForever(try character.action(animation: "walk")), withKey: "walk")
// В SKScene.didFinishUpdate(), после собственных правок костей:
try character.prepareMeshes(in: view)
// Досрочная остановка clip, затем удаление его внешнего SKAction-контейнера:
character.stopMeshAnimation()
character.removeAction(forKey: "walk")
```

Ошибки нового API (существующие вызовы общего decoder сохраняют прежние DecodingError/SpineError):

| Failure | Code | Path |
|---|---|---|
| Malformed JSON / неверный тип | invalidData | JSON Pointer из codingPath; корень `""` |
| Missing/malformed version или не 4.1.x (включая decoding error ровно этого поля) | unsupportedVersion | `/skeleton/spine` |
| Known unsupported 4.1 feature | unsupportedFeature | точное поле feature |
| Obsolete mesh layout | invalidData | старое поле; без автоконвертации |
| Bad vertices/indices/weights | invalidGeometry | соответствующий массив/индекс |
| Deform offset/curve/time invalid | invalidTimeline | ключ timeline; время finite ≥0, ключи строго возрастают |
| Missing linked parent / cycle | missingAttachment / linkedMeshCycle | поле `parent` проблемного attachment |
| MeshAsset на tvOS/watchOS | unsupportedPlatform | `/runtime/platform` |
| Missing texture/page | missingTexture | `/textures/<escaped-name>` |
| Corrupt PNG/metadata/provider error | invalidTextureRegion | `/textures/<escaped-name>`; message содержит исходную причину |
| Missing skin/animation | missingSkin / missingAnimation | `/skins/<name>` или `/animations/<name>` |
| Async conflict на owner | concurrentClip | `/runtime/animations/<name>` |
| Bad frame context / mutated nodes | invalidRenderContext / mutatedNodeContract | `/runtime/frame` или `/runtime/nodes/<name>` |

Во всех path действует JSON Pointer escaping: `~` → `~0`, `/` → `~1`. Runtime/load errors не включают адрес объекта или нестабильное описание texture. Format decoding errors оборачиваются только на входе MeshAsset; direct SpineModel decode сохраняет прежний error type. `wrongSkeleton` сохраняется как reserved case, без обязательного emission или гарантии validation чужого receiver.

### 5. Внутренние границы и диагностические данные

```swift
// Sources/Spine/Model/SpineModel.swift и вложенные модели — единый decoder 4.1 для всех входов.
// SpineMeshAsset(json:) вызывает JSONDecoder().decode(SpineModel.self, from: json).
struct SpineFeatureIssue { let path: String; let name: String; let kind: Kind
    enum Kind { case knownUnsupported, obsoleteMeshLayout }
}
// SpineModel хранит internal [SpineFeatureIssue]. Известные 4.1 types декодируются;
// раньше игнорируемые timeline names записываются в issues без исполнения legacy.
// Unknown attachment discriminator, который раньше не декодировался, по-прежнему throws.
// Raw payload не исполняется и не направляется в запасной decoder.
// Sources/Spine/Mesh/Compilation/ — валидированные неизменяемые данные и числовые timelines.
struct MeshInfluence { let boneIndex: Int; let position: SIMD2<Float>; let weight: Float }
enum MeshVertices {
    case unweighted(boneIndex: Int, positions: [SIMD2<Float>])
    case weighted(offsets: [Int], influences: [MeshInfluence]) // offsets.count = vertexCount+1
}
struct CompiledMesh {
    let vertices: MeshVertices
    let indices: [Int]
    let uvs: [SIMD2<Float>]
    let deformSourceID: Int
}
// Sources/Spine/Mesh/Geometry/: pure calculation; no SKNode/SKAction/texture access.
func computeMeshPositions(_ mesh: CompiledMesh, boneMatrices: [CGAffineTransform],
                          deform: [SIMD2<Float>], into output: inout [SIMD2<Float>]) throws
// Runtime/: per-skeleton slots/deform/clip lifecycle; Renderer/: SpriteKit nodes/materials.
// Diagnostics в тестовой сборке, не новый public API:
struct MeshSnapshot {
    let activeAttachments: [String?]; let drawOrder: [Int]
    let vertices: [[SIMD2<Float>]]; let uvs: [[SIMD2<Float>]]
}
```

### 6. Проверяемые артефакты

```text
Tests/SpineTests/Compatibility/                 # неизменённые client snippets, модели, state fixtures
Tests/SpineTests/Mesh/                          # новые decoder/geometry/lifecycle/resource tests
Tests/SpineTests/Resources/Mesh41/               # Goblins и два authored synthetic fixtures, лицензии
Examples/MeshPrototype --verify-library-legacy <output>
Examples/MeshPrototype --verify-library-mesh <output>
Examples/MeshPrototype --benchmark-library-mesh <output>
features/mesh-support/validation/json-format-audit.json # проверенное сравнение 4.0/4.1 и текущих fixtures
features/mesh-support/validation/baseline.json  # commit, SDK/OS/device, timings, fixture hashes
features/mesh-support/validation/compatibility.json
features/mesh-support/validation/mesh-parity.json
features/mesh-support/validation/platforms.json
Sources/Spine/Documentation.docc/Meshes.md       # единый формат 4.1, opt-in API, версия текущих assets не меняется
```

## Rules

### C — Совместимость и изоляция

| # | Rule |
|---|---|
| C.1 | Все старые конструкторы создают legacy playback, новый — mesh-aware. Имя файла/PRO/ESS не выбирает decoder: все JSON-входы используют один SpineModel 4.1. Hook не нужен прежним region-only клиентам с поддерживаемыми данными. |
| C.2 | `SpineModel.Decodable` и вложенные модели дорабатываются как единственный decoder. Изменения ограничены поддержкой mesh-полей schema 4.1 и их optional defaults; старые ESS defaults/ошибки/unknown-field policy сохраняются; второй frozen/legacy decoder, autodetection и fallback по старым layouts не создаются. Непричастные к mesh/schema изменения legacy animation запрещены. |
| C.3 | У legacy сохраняются типы/имена/иерархия публичных nodes, z-order, texture replacement, skin selection, события, action duration/composition/removal/reuse, pause/speed/reset и физические/point attachments. Нет обязательных новых настройщиков, ресурсов или mesh capability validation; нового глобального version/schema gate не добавляется. |
| C.4 | Baseline снимается до изменения production-кода на `d1cbd6e`; сравнение выполняется тем же SDK/renderer и фиксированными timestamps. Existing suite failures регистрируются отдельно. Прежние failures фиксируются до работы и устраняются отдельно; регрессию нельзя маскировать обновлением golden files. |
| C.5 | Изменения общего кода допускаются только с проверкой обоих режимов; mutable clip/slot/deform state не разделяется между skeleton. Иммутабельный asset и canonical textures/materials можно разделять. |
| C.6 | JSON major/minor не меняется: текущие ESS/Pro fixtures — 4.1.17. Документация не требует их re-export или major-релиза библиотеки для этой задачи. Совместимость других форматов не расширяется; будущая смена target рассматривается отдельно как возможный breaking change без параллельных loaders. |

### D — Единый JSON 4.1 и ресурсы

| # | Rule |
|---|---|
| D.1 | Все входы JSON используют один SpineModel decoder с полями 4.1. Он читает version metadata как прежде, без новых глобальных отказов. Только SpineMeshAsset проверяет объявленную версию по `^4\.1\.[0-9]+$`; отсутствие/другая версия → unsupportedVersion в новом API. Старый путь загрузки не вызывает этот validator. |
| D.2 | Общая модель читает `animations.*.attachments.*.*.*.deform`, linked `timelines` (default true), `offset` (default 0), отсутствующие `vertices` как пустые. Семантика — pinned spine-core 4.1.56. Старые Pro layouts не преобразуются fallback-декодером; их наличие записывается как format issue и отклоняется MeshAsset как invalidData, без нового отказа legacy playback. |
| D.3 | После общего decode mesh-aware compiler до создания Skeleton проверяет все skins/animations и ссылки: обычные/weighted/linked meshes, region, unweighted bounding box и point; normal bone inheritance, нулевой shear, normal blending, RGBA. Допустимые bone timelines: rotate/translate/translatex/translatey/scale/scalex/scaley; slot: attachment/rgb/alpha/rgba, плюс events/drawOrder/deform. Constraints Spine, sequences, clipping, dark tint, weighted bounding box, известные, но не реализованные 4.1 attachment/timeline виды → `unsupportedFeature` с точным path, включая невыбранные skins. Несущественные metadata разрешены. Эта runtime capability-проверка не вводит новые ограничения воспроизведения ESS через legacy playback. |
| D.4 | Все числа геометрии/ключей finite; UV — пары по числу vertices, triangle indices — целые в диапазоне, число индексов кратно 3. Веса finite ≥0, влияния не ограничиваются четырьмя и не нормализуются; count/indices/offsets проверяются. Hull/edges/width/height не обязательны для рендера. Invalid данные дают error до node allocation; нет обрезания индексов/массивов. |
| D.5 | Linked geometry разрешается до конца цепи с обнаружением циклов/отсутствующих parents. Геометрия общая immutable, texture region выбирается по собственному path linked attachment; timeline source учитывает `timelines` каждого звена по 4.1. |
| D.6 | Atlas provider поддерживает несколько PNG pages, rotations 0/90, trim/original size и page PMA metadata; выдаёт canonical PMA ровно один раз. Pixel sizes положительные целые, trim внутри originalSize, uvTransform finite. Неизвестное размещение SKTextureAtlas, rotation иной величины, отсутствующая page/region → typed error. Модельные UV и итоговые page UV не смешиваются. |
| D.7 | Resource resolution/decode/precompute выполняются при загрузке; на кадре нет JSON parsing, cgImage readback, создания texture или shader compilation. Поза не хранится в общем material. |
| D.8 | Один общий decoder сохраняет известные 4.1 types и internal feature issues; malformed/неизвестный attachment discriminator сохраняет прежний decoding failure. Раньше игнорируемые timeline виды могут быть зарегистрированы как issue, но не начинают исполняться в legacy. MeshAsset оборачивает decoding errors и проверяет issues по таблице ошибок Contract. |

### A — Действия, состояние и ошибки

| # | Rule |
|---|---|
| A.1 | Mesh-aware `action(animation:)` возвращает новое SKAction с immutable owner/epoch/clip binding, захваченным при создании; mutable execution ID/cursors создаются на owner при каждом begin; action хранит weak owner. Begin/end выполняются однократно через `SKAction.run`, sample — через timed `SKAction.customAction`; elapsed time sample — единственный clock. Compiled curves 4.1 и bone TRS/slot/deform применяются в фазе actions. `prepareMeshes` никогда повторно не оценивает timeline. |
| A.2 | На старте execution восстанавливается setup state костей/слотов/deform, затем применяется t=0; transform самого Skeleton не сбрасывается. Duration — max timestamp всех поддержанных timelines, включая deform-only/events/drawOrder. Интерполяция per-channel linear/stepped/10-segment Bezier соответствует 4.1; после последнего ключа значение удерживается. |
| A.3 | Sequence, finite repeat, repeatForever положительной duration, pause/resume и nonnegative speed поддерживаются; каждый повтор имеет свежие cursors и стартовые события. Допустима одна execution Spine clip; другая одновременная execution → `concurrentClip` до её записи. Последовательный повторный запуск того же action/его copy в текущем epoch разрешён; одновременные копии конфликтуют как разные executions. Обязательное предусловие: receiver каждого запуска action, его copy и внешнего container — создавший action owner. Запуск на другом Skeleton или любом другом SKNode не поддерживается; гарантии no-op, diagnostic и отсутствия мутаций не предоставляются, включая одновременное выполнение на owner и чужом receiver. Для другого Skeleton запрашивается его собственный action. Если owner освобождён — callbacks no-op. |
| A.4 | `stopMeshAnimation` увеличивает epoch, очищает lease/error/deform cursors, сохраняет текущие TRS/slot/deform при reset=false, а при true восстанавливает setup. Все ранее полученные clip-actions этого owner становятся no-op, включая ещё не запущенные; для нового запуска запрашивается новый action. Внешние SKAction-контейнеры и обычные действия метод не удаляет. |
| A.5 | В новом режиме досрочное удаление внешнего clip-action сопровождается `stopMeshAnimation`; один `removeAction` замораживает позу, но не считается освобождением lease. Это ограничение не относится к legacy. `dropToDefaultsAction` останавливает действия как раньше и дополнительно сбрасывает mesh epoch/state. Завершение execution освобождает lease без ручного stop. |
| A.6 | События идут в порядке ключей на интервале `(previousTime, currentTime]`, плюс t=0 один раз на execution; пропущенные между кадрами события не теряются, последний ключ не дублируется и не удлиняет duration. Перед/после каждого event callback проверяются epoch/execution ID: reentrant stop/reset прекращает оставшиеся события и записи старого execution; новый action из callback получает текущий epoch. Простая подготовка/пауза не генерирует события. Нулевая duration выполняется однократно; её повтор, reversed и пользовательская перенастройка timing/duration самого clip вне контракта. |
| A.7 | У слота одно состояние active attachment/color/deform. Skin switch атомарно объединяет default skin с выбранным, сохраняет active key если доступен, иначе setup key/none; совместимый deform сохраняется только при одинаковом deformSourceID, иначе сбрасывается. На смене attachment состояние управляется идентичностью источника, не размером массива. |
| A.8 | Ошибки загрузки/skin selection синхронно throwing и атомарны. Fatal ошибка callback SKAction (`concurrentClip` при соблюдении предусловия receiver) записывается в `meshPlaybackError` без throw через SpriteKit; последующие mesh clip callbacks no-op, управляемые visuals скрываются, prepare бросает ту же ошибку до stop/reset. Поля code/path стабильны; human-readable message не сравнивается целиком. Все предусмотренные контрактом diagnostics доставляются через meshDiagnosticHandler owner один раз на incident; handler не сохраняется в общем asset. Ошибки существующих legacy API сохраняются. |

### G — Геометрия и публичные узлы нового режима

| # | Rule |
|---|---|
| G.1 | Для unweighted vertex `p = boneMatrix * (setup + deformDelta)`; для weighted — сумма `weight * boneMatrix * (influencePosition + influenceDelta)`. Деформация хранится в input space, sparse offsets считаются в скалярных компонентах; odd offsets разрешены при допустимом диапазоне. Пустой ключ — zero deltas, не отсутствие timeline. |
| G.2 | Финальные матрицы строятся прямым перемножением актуальных локальных TRS по bone hierarchy, исключая Skeleton и внешних предков. Обращение нулевой матрицы кости не требуется. Mesh positions — skeleton-local; renderer branch под Skeleton применяет его transform ровно один раз. |
| G.3 | Ручные bone TRS после actions/physics и до prepare учитываются в текущем кадре. Alpha/hidden костей и slot nodes одинаково влияют на regions/meshes, перемножаются до Skeleton, чьи внешние свойства SpriteKit применяет отдельно. Нулевой scale скрывает вырожденную геометрию без NaN и позволяет восстановление. |
| G.4 | Bone/slot nodes сохраняют lookup names и реальные типы. В новом режиме slot TRS остаётся identity; ручная смена hierarchy/slot TRS/internal z → `mutatedNodeContract`. Mesh accessor возвращает служебный SKNode для чтения; legacy region accessor не возвращает mesh. Внутренняя render branch не участвует в поиске логических slots/bones. |
| G.5 | Bounding box/point attachments в новом режиме сохраняют логическое размещение под slots; skin replacement атомарно обновляет соответствующие physics/point nodes. Новая physics mesh-форма из треугольников не создаётся. |
| G.6 | Nonfinite runtime bone TRS/matrices → invalidGeometry с `/runtime/nodes/<name>` до записи результата; managed visuals скрываются, прежние buffers не заменяются NaN. Исправление TRS и успешный prepare восстанавливают картинку без сброса времени. |

### R — Отрисовка и кадр

| # | Rule |
|---|---|
| R.1 | Production default — последовательные пары треугольников одного attachment/texture/material; хвост из одного треугольника отключает пустой shader slot. `.one`/`.four` остаются внутренними диагностическими вариантами. Regions рисуются одним SKSpriteNode с корректной trim/rotation геометрией; при необходимости отдельный tint shader использует его primary texture. |
| R.2 | Цвет — покомпонентное произведение slot RGBA и attachment RGBA. Для PMA sample: RGB умножается на tintRGB × tintAlpha × effectiveOpacity, alpha — на tintAlpha × effectiveOpacity. Для пары alpha применяется к каждому треугольнику ДО source-over; material uniforms immutable, per-instance параметры — attributes. |
| R.3 | У нового skeleton drawOrder задаёт slot rank в `[0,1)`; весь slot и его группы помещаются в непересекающийся поддиапазон этого интервала. Ancestor bone z остаётся 0. Порядок attachment/group/triangle сохраняется при отражении/skin/deform; библиотека не изменяет ignoresSiblingOrder сцены. |
| R.4 | Native prepare требует `skeleton.scene === view.scene`; учитывает camera/anchorPoint/scaleMode/resize/backingScale и актуальных предков. Custom context задаёт actual fragment convention и pixel size явно. Вызов выполняется на потоке SpriteKit после всех правок; повтор с той же позой/context идемпотентен, включая paused scene. |
| R.5 | Invalid/nonfinite context → `invalidRenderContext` и скрытие managed visuals до следующего успешного prepare; finite singular projection скрывает mesh geometry без ошибки и восстанавливается после исправления. Legacy prepare/stop — no-op. Подготовка не меняет scene delegate, clock, physics или чужие nodes. |
| R.6 | Вычисленные mesh buffers меняются только при prepare. SpriteKit может немедленно применить изменения самих nodes/предков/camera; после любой влияющей на изображение правки после hook требуется повторный prepare до рисования. Иначе согласованность регионов/meshes и framebuffer coordinates не гарантируется. Автоматический phase guard не обещается; examples выполняют hook последним. Effect/crop ancestors нового skeleton отклоняются как unsupportedFeature; custom context не объявляет автоматическую поддержку intermediate framebuffer. |
| R.7 | Topology/UV/material переиспользуются, динамические буферы принадлежат экземпляру; не создаются новые triangle nodes при каждом кадре. Skin load/replacement освобождает недостижимые ресурсы; нет глобального бессрочного material cache. |

### V — Проверяемые гарантии

| # | Rule |
|---|---|
| V.1 | Legacy ABI не обещается, source compatibility обязательна: unchanged snippets/fixtures, timestamps/events/duration/order, snapshot numeric error ≤1e-6, RGBA channel max ≤1/255 на том же SDK. Golden поддерживаемых ESS 4.1 не обновляются для сокрытия регрессий; API/decoder breaking changes не допускаются этой задачей. Median frame CPU region-only не ухудшается >10% в том же стенде. |
| V.2 | World vertices против pinned 4.1.56: max error ≤0.005 Spine units, UV ≤1e-6, active identity/order exact. Fixtures: Goblins, authored weighted-link fixture (>4 влияний/сингулярные кости), authored deform/resources fixture (odd/sparse/empty offsets, curves, trim/rotation/multipage/tint). Все key times, середины интервалов, ±1e-5 около switching проверяются. |
| V.3 | Renderer baseline `d1cbd6e`: групповые сравнения max RGBA-channel ≤2/255, камера ≤3/255 с подсчётом >2; внутренние shared-edge alpha error ≤2/255. Прежние nearest/silhouette allowances применяются только к прежним тестам; новые fixtures не получают исключений автоматически. |
| V.4 | Для 50 Goblins на том же M1 Max Release: среднее двух p50 CPU pose ≤10.0 мс, scene update/encode ≤21.3 мс, GPU ≤0.52 мс, callback ≥30 FPS. Два раунда с обратным порядком вариантов, 30+120 native и 30+60 offscreen кадров, без timed readback; FPS callback не называется presented FPS. |
| V.5 | Существующие package targets/deployment minimums сохраняются. Mesh-aware loading на tvOS/watchOS → unsupportedPlatform; legacy собирается и работает по прежнему контракту. macOS/iOS требуют отдельных проверок; iOS release блокируется до real-device parity/lifecycle и 1/10/50 отчёта с моделью/OS. Симулятор не подменяет этот gate. |

## Out of scope

- Полный Spine Pro: shear, non-normal inheritance, Spine constraints, mixing, clipping, sequences, dark tint и ненормальные blend modes.
- Поддержка нескольких JSON major/minor версий, автоматический schema fallback и конвертация старых файлов внутри библиотеки. Target — 4.1; другой target требует новой версии контракта и migration notes.
- Автоматическая обработка SKCropNode/SKEffectNode, освещение/normal maps, собственный Metal host, GPU skinning.
- Несколько одновременных mesh-aware clips, reverse/negative time и повтор zero-duration clips.
- Запуск mesh clip-action/copy/container на любом узле, кроме его owner, включая параллельный запуск на owner и чужом receiver; проверки, diagnostics и безопасность такого нарушения предусловия не гарантируются.
- Генерация физических тел из meshes, поддержка новой mesh-функциональности на tvOS/watchOS до следующей итерации.
- Удаление прототипа, переименование текущих public region/bone/slot API, новые SwiftPM products или runtime-зависимость от официального core.

## Tests

| # | Where | Asserts | Maps to |
|---|---|---|---|
| 1 | `Compatibility/LegacyConstructionTests.swift` | Unchanged конструкторы/сниппеты/deprecated API; mesh-like keys и version не переключают режим; hook не нужен | C.1, C.3, V.1 |
| 2 | `Compatibility/UnifiedDecoderTests.swift` | Golden ESS 4.1 моделей/defaults; все loaders вызывают общий decoder; новый код не добавляет отказов прежнему decoder; version/capability validation применяется лишь MeshAsset | C.2, C.4, C.6, D.1, V.1 |
| 3 | `--verify-library-legacy` | Фиксированные action timestamps, repeat/group/sequence/reuse/removal, события, skins/color/texture, nodes/physics/points и snapshots против baseline | C.3, C.4, C.5, V.1 |
| 4 | `Mesh/Decoder41Tests.swift` | Один JSON через direct decode/legacy/MeshAsset: только MeshAsset применяет version/runtime gate; 4.1 attachments/timelines/empty deform; mesh-aware capability errors даже в невыбранном skin | D.1, D.2, D.3, D.8, A.8 |
| 5 | `Mesh/GeometryValidationTests.swift` | NaN/Inf, индексы, неверные counts, отрицательные веса, необязательные поля; ошибка до node creation | D.4, A.8 |
| 6 | `Mesh/LinkedMeshTests.swift` | Chains/cycles/missing parents, own path, timelines true/false, immutable sharing и isolated deform | C.5, D.5, A.7 |
| 7 | `Mesh/TextureProviderTests.swift` | Rotated/trimmed/multipage corners, straight/PMA pages, corrupt/missing resources, opaque SKTextureAtlas rejection | D.6, R.1, R.2 |
| 8 | `Mesh/ActionLifecycleTests.swift` | SKAction-only clock, positive repeat/sequence, native SKView pause/resume и initial/dynamic nonnegative speed (включая 0 и 0.5), ровно один begin/end и освобождение lease на каждом repeat при начальном speed 0.5 и изменении через 0, zero-duration once, independent owner state | A.1, A.2, A.3, A.6, C.5 |
| 9 | `Mesh/ActionConflictTests.swift` | Same/different concurrent clip/copies, все запускаются на создавшем их owner; fatal конфликт hides только owner visuals, другой Skeleton со своим action не затронут | A.3, A.8 |
| 10 | `Mesh/ActionCancellationTests.swift` | stop/reset/dropToDefaults epoch, stale copies/actions no-op, reacquisition, remove+explicit stop, reentrant event stop/restart, ordinary actions unaffected | A.4, A.5, A.8 |
| 11 | `Mesh/TimelineTests.swift` | Absolute multi-channel Bezier, stepped/linear, defaults, deform-only duration, event interval/last key/zero time | A.1, A.2, A.6, D.2 |
| 12 | `Mesh/SlotStateTests.swift` | Active/nil attachment, skin merge/fallback, compatible vs incompatible deform identity, atomic failure, RGBA across region↔mesh | A.7, A.8, R.2 |
| 13 | `Mesh/SkinningTests.swift` | Unweighted/weighted >4, odd/sparse/empty deform, nonuniform/negative/zero ancestor scales; reusable buffers | G.1, G.2, G.3, D.4 |
| 14 | `--verify-library-mesh` + external oracle | Three fixtures, complete timestamp grid, exact attachment/order, required position/UV tolerances | V.2, G.1, D.5, A.7 |
| 15 | `Mesh/NodeBridgeTests.swift` | Post-actions manual bone edits, inherited alpha/hidden, no double transforms; slot/hierarchy/z mutation и nonfinite TRS diagnostics/recovery | G.2, G.3, G.4, G.6, R.3, A.8 |
| 16 | `Mesh/AttachmentInteropTests.swift` | Real region sprite vs inspect-only mesh lookup, default skin, point/physics rebuilding without stale nodes | G.4, G.5, C.3, R.1 |
| 17 | `--verify-library-mesh` renderer cases | PMA/tint, folds/overlap, winding, degenerate recovery, tail slot, strict seam/coverage tests | R.1, R.2, V.3 |
| 18 | `--verify-library-mesh` integration cases | Tree/fence order, animated drawOrder, camera/resize/view scale, mixed legacy/new characters; foreign scene nodes unchanged | R.3, R.4, R.5, V.3 |
| 19 | `Mesh/FrameContextTests.swift` + GPU runner | Paused/manual/native/custom corner+pixel-center mapping, viewport offset/Y convention, legacy no-op, wrong view/NaN/singular recovery, repeated prepare после поздних bone/Skeleton/ancestor/camera правок, effect parents | R.4, R.5, R.6, G.6, A.1, A.6 |
| 20 | `Mesh/ResourceLifetimeTests.swift` | Per-frame reuse, no parsing/readback/shader compile; create/switch/destroy 100 times, weak refs released, state isolation | D.7, R.7, C.5 |
| 21 | `--benchmark-library-mesh` + legacy bench | 1/10/50 CPU/GPU/callback records, matched warmup/rounds, no legacy >10% regression, image validation before pass | V.1, V.4 |
| 22 | `validation/platforms.json` + build matrix | All legacy platform builds, unsupportedPlatform gate, real macOS/iOS device results and retained deployment targets | V.5 |
| 23 | Documentation/example smoke | ESS 4.1 examples unchanged/no hook; общий loader и новый asset/stop/reacquire/prepare работают; документация подтверждает owner receiver precondition, один формат 4.1 без обязательного re-export/изменения кода ESS | C.1, C.6, A.3, A.4, A.5, R.6, V.5 |

## Execution

### Lock

- Expected branch: `feat/mesh-support`; baseline production revision: `d1cbd6e`.
- Preflight implementation check: [ ] branch, working tree, pinned fixtures/oracle, SDK/device availability and baseline captured.
- Каждый phase commit — только после зелёного validation gate; этот документ не запускает реализацию и не разрешает push/release.
- Source/API changes вне этого контракта требуют обновления spec version; архитектурные изменения — следующей итерации ADR.

### Phase 1 — Зафиксировать неизменяемое старое поведение

**Objective.** Legacy characterization работает на baseline до интеграции.
**Work.**
- Добавить неизменённые client snippets и детерминированный action/render runner; записать baseline commit, fixture hashes, SDK, state/events/images и CPU.
- Проверить доступность четырёх SDK и устройства iOS; отсутствующий device отмечается release blocker, не успешной проверкой.
**Dependencies.** Нет.
**Risks.** Нестабильные timestamps — preload до запуска, фиксированный renderer clock; существующие failures — отдельный отчёт/исправление.
**Validation.** Только baseline characterization часть Tests 1–3, 21–23, без assertions нового API/валидации; full existing suite green. Если baseline suite красная, downstream phases не начинаются до отдельного исправления и явного обновления baseline revision.
**Done.** Baseline воспроизводится до изменения decoder; JSON audit зафиксирован; от baseline не требуется новый MeshAsset или новое поведение.

### Phase 2 — Проверить жизненный цикл нового SKAction на минимальном fixture

**Objective.** Owner/epoch/lease и frame hook работают до подключения реальных meshes.
**Work.**
- Добавить opt-in внутренний runtime shell и публичные сигнатуры; test-only compiled fixture с одной костью и deform channel.
- Реализовать begin/end через `SKAction.run`, timed sample через `SKAction.customAction`, sticky fault, stop/reset, stale action guards и snapshot; никаких независимых таймеров/дочерних actions, живущих дольше возвращённого clip-action.
**Dependencies.** Phase 1.
**Risks.** Repeat копирует closures, remove не вызывает completion — обязательные owner/cancel tests. Zero-duration custom callback не является once-only boundary; native pause/speed обязательны. Провал gate останавливает интеграцию, контракт не ослабляется молча.
**Validation.** Tests 8–11, 19 (state cases); Test 8 initial/dynamic speed и pause/resume — в native SKView, fixed-clock SKRenderer не заменяет эту проверку. Baseline characterization часть 1–3 (без нового decoder/MeshAsset gate) и full implemented suite green.
**Done.** Конфликты/отмена не оставляют невидимый active lease после предусмотренного stop и не затрагивают legacy.

### Phase 3 — Загрузить и показать реальную mesh setup pose

**Objective.** Новый Data→asset→Skeleton путь рисует статические ordinary/weighted/linked meshes.
**Work.**
- Доработать единый SpineModel decoder 4.1, strict mesh compiler, atlas provider и typed errors; подключить pure skinning и общий renderer групп 2.
- Проверить trim/rotation/PMA и singular transforms на synthetic fixtures; перенести переносимый renderer без AppKit/Metal dependency в production target.
**Dependencies.** Phases 1–2.
**Risks.** JSON-version/atlas неоднозначность — один общий decoder 4.1 и явные metadata; двойные transforms — skeleton-local snapshots и forward matrices.
**Validation.** Tests 4–7, 13, 15–17 (setup), 20; полные 1–3 и full implemented suite green. Ранний real-device iOS subset Test 22: одна пара треугольников, PMA/tint, trim/rotation и native frame mapping; без device gate phase не завершена.
**Done.** Goblins setup и synthetic geometry совпадают с oracle/эталонным изображением; ESS 4.1 проходит тот же decoder без регрессий; новые format/capability errors остаются на opt-in входе.

### Phase 4 — Подключить анимации, slots и окружение

**Objective.** Полный первый mesh-контракт работает через публичный API.
**Work.**
- Соединить compiled timelines с actions/runtime; реализовать colors, skin/deform identity, drawOrder, point/physics и bounded depth.
- Подключить native/custom prepare, camera/paused/error recovery; добавить library-backed варианты обоих демо, сохранив prototype reference mode.
**Dependencies.** Phase 3.
**Risks.** Attachment/skin меняется во время clip — атомарное slot state; scene ordering — полный depth-band и integration regression.
**Validation.** Tests 1–20, 23; full suite и прежние GPU tests green.
**Done.** Все три fixtures проходят oracle на полном timestamp grid; обе сцены работают с production Skeleton.

### Phase 5 — Проверить скорость и целевые платформы

**Objective.** Зафиксировать release evidence для заявленной поддержки.
**Work.**
- Выполнить matched legacy/mesh benchmarks, lifetime checks, четыре platform builds; исправлять измеренные регрессии без изменения старой семантики.
- На реальном iOS устройстве выполнить parity/lifecycle/render и 1/10/50 замеры; сохранить отчёты и документацию возможностей/ограничений.
**Dependencies.** Phase 4; устройство iOS выявляется ещё в Phase 1.
**Risks.** Нет device или shader отличается — release gate остаётся незавершённым; FPS только callback — не переименовывать в presentation rate.
**Validation.** Все Tests 1–23; full suite green; performance/image/platform gates соблюдены.
**Done.** macOS/iOS mesh-поддержка подтверждена отчётами, legacy работает без изменения кода на прежних платформах.

## Done criteria

- Tests 1–23 пройдены; значения public API совпадают с Contract; нет обязательных изменений legacy client snippets для ESS 4.1; переэкспорт текущих ESS 4.1 не требуется.
- Один JSON decoder 4.1 используется всеми loaders. Поддерживаемый ESS подтверждён baseline; нет глобального ужесточения версии, второго decoder, требования re-export или breaking changes этой задачи.
- Geometry, image, lifecycle, resource lifetime и performance пороги выполнены; нет неучтённых исключений в golden comparisons.
- Обе демо-сцены сохранены и имеют production-backed проверку; документация явно описывает hook, cancellation/reacquire, owner receiver precondition и ограничения нового режима.
- Сохранены JSON format audit, baseline, compatibility, parity, performance и platform отчёты; real-device iOS gate не заменён симулятором.
