# Spine meshes через SpriteKit nodes + shader

macOS-пример с двумя независимыми режимами: исходный **Prototype** и **Library** на production `Skeleton`. Оба запускаются в обычном `SKView`; исходные сцены и renderer прототипа сохранены.

Показывает официальный **Goblins Pro 4.1.17**, skins `goblin` и `goblingirl`, анимацию `walk`. В примере воспроизводятся обычные/weighted meshes, deform timelines, linked feet, переключение attachments при моргании и rotated atlas regions. Regions рисуются тем же треугольным renderer, что и meshes: порядок слотов сохраняется.

## Production Library

Переключатель **Prototype / Library** (клавиша **L**) выбирает renderer, а
**Mesh demo / Integration scene** (**Tab**) — сцену. Все четыре сцены кешируются.
Для прямого запуска production-окружения:

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --library --integration
```

Library использует общий `SpineMeshAsset`, независимые `Skeleton`, обычные
`SKAction` и финальный `prepareMeshes(in:)` в `didFinishUpdate`. Здесь доступны
Space, A, R, 0; в окружении также C и +/−. Покадровый seek и wireframe остаются
управлением исходного Prototype. Прежние `--verify`, `--verify-integration` и
benchmark-команды по-прежнему проверяют Prototype.

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify-library-scenes /tmp/spine-library-scenes
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify-library-mesh /tmp/spine-library-mesh
```

Первая команда проверяет сохранение четырёх сцен при Tab/L, сохраняет оба
production-скриншота и сравнивает восемь кадров окружения с исходным независимым
mesh-bounds renderer. Вторая также запускает GPU/state checks и экспортирует
полную сетку времён для внешнего oracle 4.1.56. Это автоматические readback-проверки,
не интерактивный UI review. Правила API описаны в
[Meshes.md](../../Sources/Spine/Documentation.docc/Meshes.md).

## Запуск

Из корня репозитория, на macOS с установленным Xcode:

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype
```

Для сравнения со старым режимом добавьте `--bounds mesh`; по умолчанию используется `--bounds triangle`.

По умолчанию используется `--group-size 2`: до двух последовательных треугольников на один node. Для сравнения доступны исходный renderer `--group-size 1` и экспериментальный `--group-size 4`. Результаты сравнения — в [GROUP-PERFORMANCE.md](GROUP-PERFORMANCE.md).

Либо открыть `Examples/MeshPrototype/Package.swift` в Xcode и запустить схему `MeshPrototype` на My Mac. Внизу окна SpriteKit показывает FPS, число узлов и draw calls; эти показатели относятся к двум персонажам и интерфейсу примера.

| Клавиша | Действие |
|---|---|
| Space | Пауза / воспроизведение |
| ← / → | Пауза и шаг на 1/30 секунды |
| W | Рёбра треугольников |
| A | Прозрачность персонажей 50% / 100% |
| R | Отражение |
| + / − | Масштаб |
| 0 | Начальная поза анимации и масштаб |

## Дополнительная интеграционная сцена

Окно содержит переключатель **Mesh demo / Integration scene**; клавиша **Tab** переключает те же сцены. Исходная сцена и её управление сохранены. Сцены кешируются: пауза, playhead и настройки сохраняются при переключении; время не накапливается, пока сцена не показана.

**Integration scene**: два Goblins обходят забор и дерево, перекрывают друг друга и обычные SpriteKit-объекты. Камера плавно перемещается, поворачивается и меняет масштаб; полупрозрачные спрайты переднего плана и движущиеся светлячки рисуются вместе с meshes. По умолчанию приложение открывает исходное демо. Для прямого запуска новой сцены:

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --integration
```

В новой сцене: **Space** — пауза, **← / →** — шаг, **C** — движение камеры, **+ / −** — приближение/отдаление, **A** — 50% прозрачности персонажей, **W** — wireframe, **R** — отражение, **0** — сброс. Детали порядка слоёв и проверок — в [INTEGRATION.md](INTEGRATION.md).

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify-integration Examples/MeshPrototype/output/integration
```

## Как устроен прототип

- `Sources/TriangleRenderer/TriangleMeshNode.swift`: по умолчанию один `SKSpriteNode` на группу до двух последовательных треугольников, общий `SKShader` через `TriangleMeshNode.Material` для meshes одного atlas page и bounds mode. Shader вычисляет barycentric UV и отсекает внешние пиксели. Индексы, UV и меняющиеся позиции принимаются независимо от Spine.
- Общие рёбра имеют одинаковые коэффициенты с противоположными знаками. Полуоткрытое правило покрытия отдаёт граничный пиксель только одному из соседей. Порядок winding нормализуется; вырожденные треугольники скрываются и могут восстановиться на следующем кадре.
- По умолчанию прямоугольник покрывает только bounds своего треугольника с защитным отступом примерно в один экранный пиксель. Старый `.mesh` режим с общими bounds сохранён для A/B-сравнения.
- В `.triangle` режиме shader использует `gl_FragCoord` и общую для mesh матрицу перехода из framebuffer в координаты сетки. Матрица передаётся через per-node attributes: общие uniforms материала не меняются между meshes. Это устраняет несовпадение покрытия соседних треугольников из-за раздельной интерполяции UV внутри разных прямоугольников. Геометрия и UV по-прежнему заданы исходными vertices/indices.
- После изменения позы, камеры или трансформаций предков нужно вызвать `prepareForRendering(localToPixels:)`. В демо это делает `prepareRasterCoordinates(scene:view:)` из `didFinishUpdate`. Для offscreen-рендера требуется матрица именно его render target; helper `capture` учитывает crop и pixel density. Не следует применять матрицу окна к другому framebuffer.
- Primary texture — белый texel. Atlas page передаётся отдельным texture uniform. UV имеют начало снизу слева и адресуют полную текстуру. Режим `.nearest` реализован явным выбором центра texel, поскольку в проверенной конфигурации SpriteKit texture uniform иначе использовал linear sampling.
- `Sources/MeshPrototype/Goblin.swift`: отдельный проигрыватель **только bundled fixture 4.1.17**; матрицы костей, skinning, sparse deform и linked meshes вычисляются на CPU. При загрузке JSON преобразуется в числовые timelines, sparse deform разворачивается, а Bezier заранее аппроксимируется десятью сегментами для совпадения с runtime 4.1. В цикле кадра нет повторного разбора JSON/NSNumber. Это не новая версия production parser.
- `Sources/MeshPrototype/main.swift`: демонстрационная сцена и автоматические GPU-проверки.

Для подключения renderer нужно передать `positions`, `uvs`, `indices` и полную `SKTexture`, вызывать `updatePositions` после расчёта позы и подготовить экранную матрицу перед рисованием в `.triangle` режиме. Для совместного использования shader создайте один `TriangleMeshNode.Material(texture:boundsMode:)` и передавайте его в `TriangleMeshNode(material:positions:uvs:indices:)`. Старый initializer с `texture:` создаёт отдельный материал. Материал фиксирует texture/filtering/bounds mode/group size; управляйте им и узлами на потоке SpriteKit. `groupSize: .two` используется по умолчанию и в материале, и в initializer с `texture:`; `.one` и `.four` доступны явно. В bundled Goblins материал кешируется на время процесса отдельно для каждой пары bounds mode/group size.

`TriangleRenderer` пока находится внутри пакета примера и не экспортируется основной библиотекой.

## Проверки

```sh
swift test --package-path Examples/MeshPrototype
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify Examples/MeshPrototype/output
```

Второй запуск ненадолго открывает окно, затем завершает процесс с кодом 0 при успехе. Нужна графическая macOS-сессия. Он рисует через `SKView.texture(from:crop:)`, сохраняет PNG и сравнивает пиксели с обычным `SKSpriteNode`: квадрат, обратный winding, центрированный/смещённый стык четырёх треугольников, parent alpha, отражение, уменьшение, поворот, субпиксельное смещение, nearest/linear filtering. Проверяется и прозрачная область снаружи. Основной допуск — 2/255 на канал; тест отклоняет пустой рендер. При nearest filtering отдельно считаются пограничные texel-пиксели: alpha должна совпасть, цвет — совпасть с непосредственным соседом эталона. Такие случаи не называются побитовым совпадением.

Дополнительно выполняются 128 сравнений движущихся сеток: 48 деформаций fan при поворотах, отражениях, масштабировании и субпиксельном перемещении в двух режимах, затем 16 поз каждого Goblin skin. Внутренние швы проверяются строго; на существующем крае прозрачности допускается отличие в пределах одного пикселя и диапазона его соседей. Число таких отличий выводится отдельно. Начало fragment coordinates у native SKView/SKRenderer и захвата `SKView.texture(from:)` различается; helper выбирает соответствующее преобразование. В Debug эти большие попиксельные сравнения заметно медленнее, поэтому выше указан Release.

Группы по 2/4 треугольника сравниваются с исходным renderer в 160 случаях: деформации/folds, смена winding, отражение, вращение, прозрачность предков, вырождение и восстановление, неполная последняя группа, оба bounds modes и обе Goblins skins. Допуск — 2/255 на канал без исключений для границ.

Общий материал проверяется ещё на 16 кадрах перекрывающихся полупрозрачных meshes с разными трансформациями и сменой winding: сравнение с отдельными материалами допускает не более 2/255, без исключений для границ.

Дополнительно сохраняются восемь моментов `walk`, wireframe и `vertices.json` с координатами/UV обоих skins. Изменение кадров — smoke check, не само по себе проверка правильности позы.

Для независимого сравнения позы используется официальный JS runtime. Он нужен только для проверки и не входит в Swift-приложение:

```sh
npm install --prefix /tmp/spine-mesh-oracle --ignore-scripts --no-audit --no-fund @esotericsoftware/spine-core@4.1.56
node Examples/MeshPrototype/Scripts/compare-reference.mjs /tmp/spine-mesh-oracle/node_modules/@esotericsoftware/spine-core/dist/index.js
```

Скрипт проверяет активные attachments, позиции каждой вершины и UV. Допуск координат — 0.005 единиц Spine, UV — 1e-6. Результат — `output/reference-comparison.json`. Установленный официальный runtime сопровождается собственной лицензией; его код в прототип не скопирован.

Изображения, отчёты и build artifacts находятся в игнорируемых `output/` и `.build/`. Результаты первой итерации — в [RESULTS.md](RESULTS.md), уменьшение overdraw — в [PERFORMANCE.md](PERFORMANCE.md), CPU и общий материал — в [CPU-PERFORMANCE.md](CPU-PERFORMANCE.md).

## Измерение производительности

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --benchmark Examples/MeshPrototype/output/benchmark
```

Измеряются 1/10/50 персонажей в режимах `mesh` и `triangle`, два раунда с обратным порядком режимов. Запуск занимает несколько минут. На время измерения следует закрыть другие экземпляры прототипа и не сворачивать окно. Стенд временно держит своё окно поверх других и использует `ProcessInfo.beginActivity` для предотвращения App Nap; также записывает occlusion и thermal state. Эти настройки действуют только в benchmark-режиме.

- Обычный `SKView`: 30 прогревочных и 120 измеряемых кадров; CPU pose + geometry + подготовка framebuffer-матриц, интервалы scene update при запросе 60 FPS.
- Отдельный `SKRenderer`: те же SpriteKit-узлы, фиксированный target 1920×1080, 30 прогревочных и 60 измеряемых кадров; GPU timestamps Metal command buffer, CPU подготовки/encoding. Буферы исполняются последовательно; их wall time не эквивалентен FPS приложения.
- Площадь прямоугольников и треугольников — геометрические показатели, не аппаратный счётчик фрагментов. Число узлов/треугольников не равно draw calls.
- GPU PNG сохраняется после измерения, readback не входит в измеряемые интервалы. Перед успешным завершением сравниваются контрольные кадры обоих modes; неполный/неправильно спроецированный рендер отклоняется. SwiftUI, Metal host или собственные Metal draw calls для самого renderer не добавлены: `SKRenderer` используется только измерительным стендом.

Результат записывается в `benchmark.json` после каждого завершённого сценария. Полный отчёт должен содержать 12 записей. `effectiveFPS` — частота callback сцены, не подтверждённая частота показа завершённых GPU-кадров; интервалы зависят от vsync и планировщика.

Для эксперимента с сортировкой доступен `--ignore-sibling-order` (и в benchmark, и в demo/verify). По умолчанию он выключен: на проверенном стенде выигрыша не дал. Уникальные `zPosition` треугольников/слотов сохраняются; глобально объединять прозрачные треугольники в один z-слой нельзя без проверки перекрытий.

Сравнение контрольных изображений двух ревизий или настроек (12 PNG, строгий допуск 2/255):

```sh
Examples/MeshPrototype/.build/release/MeshPrototype --compare-benchmarks Examples/MeshPrototype/output/cpu-final-before Examples/MeshPrototype/output/cpu-final-after
```

В benchmark дополнительно сохраняется число уникальных shader/primary texture objects. Это счётчики состояния сцены, **не draw calls**.

Отдельный эксперимент с группами (18 сценариев: 1/10/50 персонажей × группы 1/2/4 × два раунда, обратный порядок групп во втором раунде):

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --benchmark-groups Examples/MeshPrototype/output/groups-benchmark
```

Все варианты этого стенда используют tight bounds (`triangle`). Сравнение 12 пар контрольных PNG с группой 1 обязательно перед успешным завершением; результаты записываются в `group-image-validation.json`. В обычном `--benchmark` можно задать фиксированный `--group-size`: он по-прежнему сравнивает оба bounds modes в 12 сценариях. Новые отчёты имеют schema 2, `benchmarkType`, `groupSizes` и `groupSize` в каждой записи.

## Границы результата

Это проверка жизнеспособности renderer на одном реальном Pro-примере, **не полная поддержка Spine Pro в библиотеке**.

- Нет IK/path/transform constraints, animation mixing, clipping, dark tint и специальных blend modes; fixture их не использует. Нет загрузки произвольных файлов через UI. Собственный fixture player принимает только нужные этому примеру каналы и normal transform inheritance.
- Atlas parser поддерживает одну страницу, untrimmed regions и rotation 0/90. `SKTextureAtlas`, subtextures и trimmed atlas не проверены. Texture/filtering задаются при создании mesh; изменения режима после создания не синхронизируются.
- Внешние края shader-треугольников имеют жёсткое покрытие без отдельного сглаживания. Не заявлена устойчивость всех произвольных тонких сеток и всех масштабов/устройств.
- Overdraw и CPU-работа уменьшены; экспериментальные группы сокращают число узлов, увеличивая работу fragment shader. UV обновляются при смене winding, framebuffer attributes — при изменении матрицы или bounds. 1/10/50 персонажей измерены на одной машине; результаты не переносятся автоматически на iOS/tvOS/watchOS.
- `.triangle` требует актуального framebuffer transform. Автоматическое определение промежуточных render targets внутри `SKEffectNode`/масок и других offscreen-эффектов не реализовано. Для этих случаев нужен отдельный контракт или прежний `.mesh` режим.
- Поведение `Skeleton.action(animation:)` основного проекта не затронуто: пример использует свой playhead. Интеграция с production skeleton — следующий самостоятельный этап.
- Автоматическая проверка живого интерфейса/клавиатуры по `code:visual-check` не выполнена: в среде отсутствует `macos-use`. Настройка инструмента описана в навыке `references/macos/setup.md`. GPU-изображения получены интеграционными render-тестами; это не скриншоты экрана и не замена UI automation.

Эксперимент с уменьшением числа SpriteKit nodes выполнен через группы 2/4; далее стоит проверить другие meshes/устройства и измерить реальные draw calls. Общий shader создаёт условия для batching, но сам по себе не доказывает число объединённых draw calls. Ограничение производительности теперь нужно искать по измеренным CPU/GPU показателям, а не по одной площади overdraw.

## Источник ассетов

Официальная [страница примеров Spine](https://esotericsoftware.com/spine-examples) ссылается на экспорт в репозитории runtimes. Здесь сохранены JSON, atlas, PNG и лицензия из [Goblins, revision 77a5db0ec6d16331f5efbaa7662bba9355bd3424](https://github.com/EsotericSoftware/spine-runtimes/tree/77a5db0ec6d16331f5efbaa7662bba9355bd3424/examples/goblins), ветка 4.1. Загрузчик не скачивает ничего при запуске.

Copyright © 2013 Esoteric Software LLC. Изображения распространяются с оригинальным [goblins-license.txt](Sources/MeshPrototype/Resources/goblins-license.txt): разрешена передача вместе с лицензией, коммерческое использование изображений запрещено. Поэтому это демонстрационные assets, не графика для коммерческой игры. Лицензия корневой библиотеки не заменяет лицензию этих изображений.

## Production performance validation

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --benchmark-library-mesh /tmp/spine-library-performance
python3 Examples/MeshPrototype/Scripts/benchmark-library-legacy-matched.py --output /tmp/spine-legacy-matched
```

Use fresh output directories and run these sequentially, without concurrent
builds or other benchmarks. The mesh command generates independent single-triangle
reference PNGs using a Release XCTest host **before** timing, then measures
1/10/50 characters in two reversed variant rounds (30+120 native,30+60 offscreen).
It validates all six pair/single images before accepting performance thresholds.
Raw prototype comparisons remain separate diagnostics; callback FPS is not
presented FPS. The native prototype reference now follows elapsed time, whereas
the historical benchmark used tick/60 and slowed animation at lower cadence.

The legacy script exports exact `d1cbd6e` library sources into its new temporary
output directory, adds the identical validation harness, builds both revisions,
and runs baseline/current then current/baseline. It creates no branch/worktree
and never modifies library sources or immutable PNG goldens. Results include
source hashes, explicit command exit codes, raw samples and CPU ratios.

Current acceptance status and unresolved gates are recorded in
[phase5.md](../../features/mesh-support/validation/phase5.md). A failed threshold
makes the mesh command exit nonzero; a nearly30FPS callback result is not silently
rounded into a pass.

The approved spec v6 nominal30 callback criterion is an unrounded two-round mean
of at least29.97FPS (0.1% allowance). Other CPU/GPU/image budgets are unchanged.
The acceptance script applies this criterion to raw values. Keep the benchmark
window active for the measured run (about60–90seconds); any inactive, occluded or
non-nominal thermal sample rejects conditions without removing samples. Old v5
failed measurements remain preserved as historical evidence.
