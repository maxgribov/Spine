---
date: 2026-10-03
model: GPT-6
description: "Полная поддержка Spine meshes: пробелы текущего runtime, ограничения SpriteKit и варианты Metal-интеграции"
---

# Поддержка meshes в Spine для SpriteKit

## Цель и рекомендация

Определить, как добавить корректные mesh-анимации, сохранив ценность существующей библиотеки для SpriteKit. Это исследование и предложение, а не утверждённая спецификация. Код библиотеки не изменён. Основание: чтение исходников проекта, публичных Apple API и заголовков установленного macOS SDK Xcode 26.6, документации Esoteric Software и официального runtime ветки 4.1.

**При допустимости нового host рекомендую независимое вычисление позы Spine и рендеринг индексированных треугольников через Metal.** Это наиболее прямой путь к точной геометрии и управляемой производительности. Однако это не прозрачное расширение обычного `SKNode`: потребуется собственный цикл рендеринга и явный контракт совмещения со SpriteKit. До ответа о совместимости Metal остаётся условной рекомендацией, а не выбранным backend.

Если обязательны обычный `SKView`, существующая иерархия узлов и произвольное чередование meshes с другими SpriteKit-узлами, сначала нужен ограниченный прототип треугольного SpriteKit-рендерера. Его качество и скорость пока не доказаны. Нельзя обещать одновременно полную совместимость, неизменную интеграцию и высокую скорость на основании одного `SKWarpGeometryGrid`.

Рабочее предположение до уточнения владельцем: интеграция `Skeleton: SKNode` ценна; заменить весь проект отдельным Spine view недостаточно.

## Что обнаружено в проекте

| Участок | Факт | Последствие |
|---|---|---|
| `Sources/Spine/Skin.swift`, `attachment(_:)` | Для textured attachments создаётся только `RegionAttachment`; mesh/linked mesh — TODO | Сетка не появляется даже в setup pose |
| `Sources/Spine/Skeleton.swift`, `apply(skin:)` | Обрабатываются region, bounding box и point | Одного нового класса mesh недостаточно |
| `Sources/Spine/Animation.swift`, initializer | Выполняются bones, slots, events, drawOrder; остальные группы пропускаются | Deform не исполняется и не участвует в общей длительности |
| `Sources/Spine/Slot.swift` | Сброс видимости/цвета ориентирован на `RegionAttachment` | Требуется общее состояние активного attachment |
| `Sources/Spine/Animation.swift`, color actions | Цвет меняется у первого дочернего `SKSpriteNode` | При переключении attachment цвет может попадать не в активный объект |
| `Sources/Spine/Bone.swift` | В setup pose применяются position, rotation, scale | Нет полной affine-математики Spine; shear и transform inheritance не воспроизведены |
| `Sources/Spine/Animation.swift` | Shear action — заглушка; IK/transform не исполняются | Правильно рассчитанные веса не исправят неправильную позу костей |
| `Sources/Spine/Model/SlotModel.swift` | Blend mode и dark tint декодируются | В просмотренном runtime нет полного исполнения этих свойств |
| `Package.swift` | iOS 13, macOS 10.15, tvOS 13, watchOS 6 | Metal backend не покрывает watchOS; README содержит более старые минимальные версии |

Отдельно обнаружено **несоответствие формата данных**. Локальные fixtures указывают Spine 4.1.17, но `AnimationModel.Keys` содержит `deform`, а не `attachments`. У официального `spineboy-pro.json` 4.1.17 есть путь `animations.hoverboard.attachments.default.front-foot.front-foot.deform`. Это проверено загрузкой JSON и обходом ключей небольшим Python-скриптом. По структуре текущего Swift decoder неизвестная группа `attachments` будет проигнорирована; end-to-end запуск этого файла библиотекой не выполнялся. [Официальный пример 4.1](https://github.com/EsotericSoftware/spine-runtimes/blob/4.1/examples/spineboy/export/spineboy-pro.json).

Сверка с `SkeletonJson.ts` 4.1 также показывает: linked mesh использует `timelines`, тогда как локальная модель читает `deform`; отсутствие `vertices` в deform key допустимо, а локальный `DeformKeyframeModel` требует массив. Поэтому формулировка «данные уже парсятся» верна только частично. Сначала нужно зафиксировать поддерживаемую версию экспорта, затем нормализовать её в внутреннюю модель. Общая веб-страница JSON не заменяет исходники runtime соответствующей версии. [Парсер 4.1](https://github.com/EsotericSoftware/spine-runtimes/blob/4.1/spine-ts/spine-core/src/SkeletonJson.ts).

В `Tests/SpineTests/Resources/skins.json` mesh содержит `hull: 100` при шести вершинах, а linked mesh ссылается на отсутствующий skin `test`. Это fixtures для декодирования полей, не доказательство корректного mesh-runtime. Визуальных mesh-тестов и проверок world vertices в просмотренном наборе нет.

## Что означает «полная поддержка»

Нужны произвольные экспортированные треугольники и UV, обычные и weighted meshes, deform timelines, linked meshes, переключение skins/attachments и корректный порядок рисования. Массив weighted vertices содержит переменное число влияний костей на вершину; нельзя вводить неоговорённое ограничение в четыре влияния. `width`, `height`, `edges` — необязательные экспортные данные, на них нельзя основывать обязательный рендеринг. [JSON format](https://esotericsoftware.com/spine-json-format).

Следует различать два результата:

- **Mesh-геометрия корректна при заданной позе:** веса, deform, UV и треугольники вычисляются верно.
- **Персонаж воспроизводится как в Spine:** дополнительно нужны все используемые его ригом constraints, shear, правила наследования, clipping, цвета, blending и attachment sequences соответствующей версии.

Первый результат не означает второй. Для первой версии разумно зафиксировать 4.1.x, соответствующую существующим assets, и явно отклонять неподдерживаемые возможности. Поддержку 4.2/4.3 следует оценивать отдельно, включая новые timelines и physics constraints. Esoteric требует согласования major/minor экспорта и runtime. [Versioning](https://esotericsoftware.com/spine-versioning).

До покрытия всех перечисленных mesh-возможностей для выбранной версии промежуточные этапы следует называть ограниченной поддержкой. ESS далее означает существующий набор возможностей Spine Essential; Pro — расширенные возможности Spine Professional. Mixing означает смешивание нескольких анимаций или переходов между ними.

## Возможности SpriteKit и Metal

`SKWarpGeometryGrid` принимает сетку rows/columns с source/destination positions, но не экспортированный Spine index buffer. Одна такая сетка не является универсальной заменой произвольной triangulation. `SKShader` — fragment shader: он может вычислять цвет/маску/UV пикселя, но не предоставляет пользовательский vertex shader и произвольную геометрию. [SKWarpGeometryGrid](https://developer.apple.com/documentation/spritekit/skwarpgeometrygrid), [SKShader](https://developer.apple.com/documentation/spritekit/skshader).

В изученном публичном `SKNode` API нет callback для собственных Metal draw calls. `SKRenderer` работает в обратную сторону: рисует SpriteKit-сцену внутри управляемого приложением Metal-цикла. Он не вставляет Metal attachment между любыми двумя узлами одной сцены. В публичном `SKTexture.h` нет конструктора из `MTLTexture`; `SKMutableTexture` даёт изменение CPU pixel data. Поэтому схему «Metal → texture → обычный SKSpriteNode без копирования» нельзя считать доступным готовым мостом. Это вывод из проверенной поверхности API, а не утверждение о внутренних механизмах SpriteKit. [SKRenderer](https://developer.apple.com/documentation/spritekit/skrenderer), [SKTexture](https://developer.apple.com/documentation/spritekit/sktexture), [SKMutableTexture](https://developer.apple.com/documentation/spritekit/skmutabletexture).

Metal предоставляет indexed triangle draws, собственные vertex/fragment shaders и blend state. Для Spine достаточно обычного triangle pipeline; специальные Metal mesh shaders не нужны. [drawIndexedPrimitives](https://developer.apple.com/documentation/metal/mtlrendercommandencoder/drawindexedprimitives(type:indexcount:indextype:indexbuffer:indexbufferoffset:)).

## Сравнение направлений

| Направление | Геометрия и скорость | Интеграция | Оценка |
|---|---|---|---|
| Один `SKWarpGeometryGrid` на mesh | Не выражает произвольную triangulation напрямую | Очень близка к текущей | Не подходит как универсальная основа |
| Треугольники через `SKSpriteNode` + fragment shader | Возможно явно вычислять barycentric UV и маску каждого треугольника; много узлов, overdraw и обновлений параметров | Сохраняет обычный `SKView` | Кандидат для обязательной SpriteKit-совместимости; нужен PoC |
| `SK3DNode` + SceneKit geometry | Indexed geometry доступна, но результат уплощается в sprite; дополнительные render targets | Узел остаётся в SpriteKit | Возможный эксперимент, слабый выбор для нового долгосрочного backend |
| Metal offscreen → CPU readback → `SKTexture` | Геометрия точная, но синхронизация и копирование каждого кадра | Сохраняет узел | Ограниченный fallback; не обещать масштабируемость |
| Metal + `SKRenderer` | Прямые indexed draws, batching и полный контроль blending | Требует нового host и явных слоёв | Основная рекомендация при допустимости изменения интеграции |

`SK3DNode` документирован как уплощённое SceneKit-содержимое; сам SceneKit сейчас отмечен Apple как deprecated. Это не означает немедленную неработоспособность существующих приложений, но ухудшает перспективу новой зависимости. [SK3DNode](https://developer.apple.com/documentation/spritekit/sk3dnode), [SceneKit](https://developer.apple.com/documentation/scenekit).

Стоимость направлений различается прежде всего миграцией. Triangle-shader backend сохраняет view, но всё равно требует изменения attachments, состояния анимации и подключения финального обновления кадра. Metal host дополнительно затрагивает камеры, ввод, композицию слоёв, эффекты и загрузку текстур приложений-потребителей. Собственное полное ядро требует существенно больше работы, чем один renderer: constraints и mixing — самостоятельные подсистемы. Официальный core сокращает этот объём, но требует адаптации API, сборки зависимости и согласования версии assets. Календарную оценку до прототипа и выбора этих границ дать обоснованно нельзя.

Для треугольного SpriteKit PoC конкретная гипотеза: один quad покрывает bounding box треугольника; shader отбрасывает внешние пиксели и интерполирует UV по трём вершинам. Нужны согласованные правила покрытия общих рёбер, отсутствие двойного alpha на швах, обработка вырожденных/перевёрнутых треугольников, проверка minification и atlas UV. Это аналитическая растеризация во fragment shader, а не аппаратная mesh-поддержка. Сохранение topology возможно концептуально, качество и производительность здесь не измерены. Полный набор Spine blend modes также требует отдельной сверки с `SKBlendMode`.

## Предлагаемое устройство решения

Это рекомендуемое разделение ответственности; названия условны и не являются обязательным API.

```text
Версионированный JSON + текстуры
               ↓
Неизменяемые SkeletonData / MeshGeometry / Timelines
               ↓
SkeletonPose: кости, активные attachments, deform, draw order
               ↓
World transforms → skinning → clipping
               ↓
Общий упорядоченный список region + mesh команд
               ↓
Metal backend   /   экспериментальный SpriteKit backend
```

### Независимая математика и состояние

Кости следует вычислять как affine-матрицы Spine, отдельно от дерева `SKNode`. Mesh geometry разделяется между экземплярами; текущая деформация принадлежит конкретному skeleton/slot. Linked mesh разделяет исходную геометрию, но может иметь другую texture region и правила наследования timelines. Связи разрешаются после загрузки всех skins, с диагностикой отсутствующих parents и циклов. [Runtime architecture](https://esotericsoftware.com/spine-runtime-architecture), [MeshAttachment 4.1](https://github.com/EsotericSoftware/spine-runtimes/blob/4.1/spine-ts/spine-core/src/attachments/MeshAttachment.ts).

Рекомендуемая внутренняя модель хранит deform как смещения. Тогда:

```text
unweighted: p[i] = M[slotBone] · (bind[i] + deform[i])
weighted:   p[i] = Σ weight[i,j] · M[bone[i,j]] · (bind[i,j] + deform[i,j])
```

Для weighted mesh deform относится к каждому влиянию, а не только к итоговой вершине. Матрицы включают перенос; результат — в координатах skeleton. Нельзя повторно применить к нему transform slot bone. Официальный runtime для unweighted случая может хранить уже сложенные с bind координаты; выбранное внутреннее представление должно учитывать эту разницу. [VertexAttachment 4.1](https://github.com/EsotericSoftware/spine-runtimes/blob/4.1/spine-ts/spine-core/src/attachments/Attachment.ts).

Деформация должна учитывать sparse offset, пустой key, линейные/stepped/Bezier переходы, состояние до первого и после последнего ключа, reset и смену attachment. Кривая относится к переходу от текущего ключа к следующему. Нельзя автоматически переносить существующий шаблон SKAction, где timingFunction берётся у ключа назначения. Длительность берётся по всем timelines. Разрешение simultaneous animations/mixing нужно определить явно; несколько `SKAction`, одновременно пишущих позу, не заменяют animation mixer.

### Обновление кадра и публичный API

Один источник времени должен управлять sampling timelines, затем world transforms/constraints, deform/skinning и render commands. Геометрия пересчитывается и при движении костей без deform keys, ручной смене позы/skin и constraints, даже если animation не запущена.

`Skeleton: SKNode` можно сохранить как facade для placement, событий и точек крепления. Для сохранения `action(animation:)` возможен action-адаптер, который продвигает playhead; состояния исполнения должны быть отдельными у каждого экземпляра и запуска. Геометрию следует завершать после актуальных actions/physics через согласованный scene callback, например `didFinishUpdate`, а не надеяться на порядок параллельных custom actions. Это уже дополнительный контракт интеграции, даже при SpriteKit backend. [didFinishUpdate](https://developer.apple.com/documentation/spritekit/skscene/didfinishupdate()).

Для Metal host нужно отдельно перенести правила камеры, scene scaleMode, преобразований родителей, alpha/hidden и bounds. Физические/служебные узлы могут оставаться в SpriteKit, но их синхронизация с позой требует явного направления обмена. Существующее редактирование bone nodes пользователем нельзя молча перестать учитывать.

### Рендеринг и ресурсы

В Metal должны рисоваться **и regions, и meshes одного персонажа** в едином draw order: region — quad из двух треугольников. Иначе рука-mesh не сможет корректно проходить между region-туловищем и region-оружием. Начать с CPU skinning: это проще проверять и не требует ограничения количества влияний. GPU skinning — последующая оптимизация по профилю.

Рекомендуемые свойства backend: статические UV/index buffers, переиспользуемые dynamic vertex buffers, объединение только соседних совместимых команд, отключённый face culling для отражений, контроль premultiplied alpha и цветового пространства, отдельные blend states normal/additive/multiply/screen и light/dark tint. Вершины не перезаписываются, пока GPU читает их; подходит ring buffer с несколькими кадрами in flight. [CPU/GPU synchronization](https://developer.apple.com/documentation/metal/synchronizing-cpu-and-gpu-work).

Clipping применяется в пределах слотов Spine до end slot. CPU clipping — наиболее проверяемый начальный вариант; stencil — отдельная оптимизация. Clip polygon также может зависеть от костей. Нельзя заменять такую семантику одной маской на целого персонажа. [Clipping attachments](https://esotericsoftware.com/spine-clipping).

Существующие Xcode `SKTextureAtlas` и Spine `.atlas` — разные пути загрузки. Metal backend нужен собственный texture provider. Для старых assets можно оценить одноразовый `SKTexture.cgImage()` → Metal upload при загрузке; его стоимость/сохранение размеров надо проверить, это не обмен GPU-ресурсами. Долгосрочно удобны исходные PNG или Spine atlas pages. В последнем случае нужны trim offsets, original size, atlas rotation и корректный переход region UV → page UV. У linked meshes UV рассчитываются для собственной region. [MeshAttachment UV logic](https://github.com/EsotericSoftware/spine-runtimes/blob/4.1/spine-ts/spine-core/src/attachments/MeshAttachment.ts).

### Главное ограничение Metal-интеграции

Практичная композиция: SpriteKit background → Metal characters → SpriteKit foreground/UI. Это явные слои/сцены с обновлением каждой логической сцены один раз за кадр. `SKRenderer` не предоставляет автоматического разделения существующей сцены по каждому `zPosition`.

`Skeleton` при таком подходе сохраняет логическую роль узла, но не все свойства рисуемого SpriteKit-поддерева: произвольное чередование с внешними узлами, родительские crop/effect nodes и lighting не возникают автоматически. Они требуют собственной реализации/ограничений host. Даже Metal offscreen flattening меняет взаимодействие multiply/screen с внешним фоном: смешивание с прозрачной текстурой не всегда эквивалентно смешиванию непосредственно со сценой. Поэтому offscreen-персонаж нельзя объявлять универсальным решением.

watchOS остаётся отдельной веткой поддержки: публичный `SKRenderer`/Metal rendering путь не доступен как на iOS/macOS/tvOS. Сохранить там текущий ESS backend возможно; обещать новые meshes можно лишь после отдельного SpriteKit-прототипа и проверки на устройстве.

## Собственное ядро или официальный runtime

Есть независимое от выбора renderer решение: продолжать писать математику на Swift либо использовать официальный runtime соответствующей версии. Для полного воспроизведения Pro-ригов официальный core снижает риск ошибок в constraints, mixing и version-specific поведении. Он не решает ограничение вставки meshes в SpriteKit.

Текущая документация spine-ios описывает Swift-обёртку над spine-c и Metal renderer; показывает ветку 4.3 и отдельно исключает tint black. Это полезный образец, но не готовая замена `Skeleton: SKNode` и не доказательство того же API/наборов платформ в ветке 4.1. Для assets 4.1 нужно выбрать совместимый core/bridge или отдельно согласовать переэкспорт. [spine-ios](https://esotericsoftware.com/spine-ios).

Рекомендация: если приоритет — полное визуальное совпадение реальных Pro-персонажей, сначала оценить официальный core + собственный backend/адаптер. Если самостоятельная Swift-библиотека без этой зависимости — существенное требование, оставить своё ядро и использовать официальный runtime как эталон результатов. Подключение или перенос его кода подчиняется Spine Runtimes License; текущая MIT-лицензия проекта не делает этот код MIT. [Условия runtime](https://esotericsoftware.com/spine-runtimes-license).

## Как снять оставшиеся риски до реализации

1. Зафиксировать версию и реальные Pro-assets. Сравнивать world vertices с runtime той же версии на фиксированных timestamps; screenshot без такого сравнения не отделяет ошибку skinning от ошибки renderer.
2. Проверить backend на одном сложном персонаже: weighted mesh + deform + linked mesh + region/mesh draw order. Для сохранения SKView отдельно проверить triangle-shader прототип на прозрачных общих рёбрах и мелком масштабе.
3. Проверить sparse/empty deform, более четырёх влияний, linked timelines true/false, смену skin, отрицательный и нулевой scale, shear и inheritance; constraints — все используемые выбранными assets.
4. Проверить rotated/trimmed textures, PMA/straight-alpha входы, dark tint, четыре blend modes и clipping. Sequence attachments включить в контракт 4.1 либо явно пометить неподдерживаемыми.
5. Проверить repeat/pause/speed/reset, копирование/reuse action, длительность deform-only animation и ручное перемещение костей. Отдельно ESS-регрессия.
6. Измерить CPU/GPU время, память, draw calls и allocations для 1/10/50 персонажей на целевых устройствах. Количества — предлагаемые сценарии, не обещание производительности; пороги FPS и памяти пока не заданы.

Предлагаемые условия прохождения PoC: все типы из выбранного контракта декодируются без молчаливого пропуска; ошибка координат против эталона укладывается в заранее зафиксированный допуск с учётом масштаба (начальная гипотеза — `max(1e-4 единиц, 1e-5 × размер skeleton)`); порядок команд и attachment identity совпадают точно. Для изображений отдельно сравниваются внутренние пиксели и границы с antialiasing, с заранее утверждённым порогом различий; видимые щели и двойная прозрачность на рёбрах означают провал triangle-shader PoC. Производительность считается пройденной только после выбора устройства, нагрузки и бюджета времени кадра; отсутствие этих данных нельзя трактовать как успешный benchmark.

Сборка, тесты проекта и визуальный прототип в рамках исследования не запускались: production-код не менялся. Выводы о существующем runtime основаны на чтении кода; сведения о форме официального 4.1 JSON дополнительно проверены скриптом. Оценки скорости — качественные до замеров.

## Открытые решения

- Обязателен ли обычный `SKView` и произвольный z-order с внешними узлами, включая crop/effect parents? Это главный критерий выбора backend; он задан владельцу отдельно.
- Какая версия Spine обязательна: существующая 4.1 или новый экспорт? Выбрать одну для первого контракта и эталонных fixtures.
- Нужна полная поддержка meshes на watchOS либо достаточно сохранить текущий ESS? Metal-путь этого обещания не покрывает.
- Допустима зависимость от официального core или самостоятельная реализация на Swift является частью ценности проекта?
- Какие гарантии старого API обязательны: существующие `SKAction` sequences/groups, одновременные анимации и ручная запись в bone nodes? Закрепить поддерживаемое поведение до выбора адаптера.
- Какие реальные Pro-assets и устройства определяют качество/скорость? Указать количество персонажей, целевой FPS и допустимую память до утверждения performance-критериев.

Следующий шаг — выбрать контракт интеграции по этим ограничениям и проверить его узким прототипом; затем оформить ADR/spec. При собственном ядре понадобятся исправление decoder и вычисление позы независимо от `SKNode`; при официальном core следует использовать его parser и pose state, не дублируя их собственной моделью без необходимости.
