# Spine meshes через SpriteKit nodes + shader

Изолированный macOS-прототип. Запускается в обычном `SKView`, без Metal host и без изменений основного target `Spine`.

Показывает официальный **Goblins Pro 4.1.17**, skins `goblin` и `goblingirl`, анимацию `walk`. В примере воспроизводятся обычные/weighted meshes, deform timelines, linked feet, переключение attachments при моргании и rotated atlas regions. Regions рисуются тем же треугольным renderer, что и meshes: порядок слотов сохраняется.

## Запуск

Из корня репозитория, на macOS с установленным Xcode:

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype
```

Для сравнения со старым режимом добавьте `--bounds mesh`; по умолчанию используется `--bounds triangle`.

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

## Как устроен прототип

- `Sources/TriangleRenderer/TriangleMeshNode.swift`: один `SKSpriteNode` на треугольник, один `SKShader` на mesh. Shader вычисляет barycentric UV и отсекает внешние пиксели. Индексы, UV и меняющиеся позиции принимаются независимо от Spine.
- Общие рёбра имеют одинаковые коэффициенты с противоположными знаками. Полуоткрытое правило покрытия отдаёт граничный пиксель только одному из соседей. Порядок winding нормализуется; вырожденные треугольники скрываются и могут восстановиться на следующем кадре.
- По умолчанию прямоугольник покрывает только bounds своего треугольника с защитным отступом примерно в один экранный пиксель. Старый `.mesh` режим с общими bounds сохранён для A/B-сравнения.
- В `.triangle` режиме shader использует `gl_FragCoord` и общую для mesh матрицу перехода из framebuffer в координаты сетки. Это устраняет несовпадение покрытия соседних треугольников из-за раздельной интерполяции UV внутри разных прямоугольников. Геометрия и UV по-прежнему заданы исходными vertices/indices.
- После изменения позы, камеры или трансформаций предков нужно вызвать `prepareForRendering(localToPixels:)`. В демо это делает `prepareRasterCoordinates(scene:view:)` из `didFinishUpdate`. Для offscreen-рендера требуется матрица именно его render target; helper `capture` учитывает crop и pixel density. Не следует применять матрицу окна к другому framebuffer.
- Primary texture — белый texel. Atlas page передаётся отдельным texture uniform. UV имеют начало снизу слева и адресуют полную текстуру. Режим `.nearest` реализован явным выбором центра texel, поскольку в проверенной конфигурации SpriteKit texture uniform иначе использовал linear sampling.
- `Sources/MeshPrototype/Goblin.swift`: отдельный проигрыватель **только bundled fixture 4.1.17**; матрицы костей, skinning, sparse deform и linked meshes вычисляются на CPU. Bezier аппроксимируется десятью сегментами для совпадения с runtime 4.1. Это не новая версия production parser.
- `Sources/MeshPrototype/main.swift`: демонстрационная сцена и автоматические GPU-проверки.

Для подключения renderer нужно передать `positions`, `uvs`, `indices` и полную `SKTexture`, вызывать `updatePositions` после расчёта позы и подготовить экранную матрицу перед рисованием в `.triangle` режиме. `TriangleRenderer` пока находится внутри пакета примера и не экспортируется основной библиотекой.

## Проверки

```sh
swift test --package-path Examples/MeshPrototype
swift run -c release --package-path Examples/MeshPrototype MeshPrototype --verify Examples/MeshPrototype/output
```

Второй запуск ненадолго открывает окно, затем завершает процесс с кодом 0 при успехе. Нужна графическая macOS-сессия. Он рисует через `SKView.texture(from:crop:)`, сохраняет PNG и сравнивает пиксели с обычным `SKSpriteNode`: квадрат, обратный winding, центрированный/смещённый стык четырёх треугольников, parent alpha, отражение, уменьшение, поворот, субпиксельное смещение, nearest/linear filtering. Проверяется и прозрачная область снаружи. Основной допуск — 2/255 на канал; тест отклоняет пустой рендер. При nearest filtering отдельно считаются пограничные texel-пиксели: alpha должна совпасть, цвет — совпасть с непосредственным соседом эталона. Такие случаи не называются побитовым совпадением.

Дополнительно выполняются 128 сравнений движущихся сеток: 48 деформаций fan при поворотах, отражениях, масштабировании и субпиксельном перемещении в двух режимах, затем 16 поз каждого Goblin skin. Внутренние швы проверяются строго; на существующем крае прозрачности допускается отличие в пределах одного пикселя и диапазона его соседей. Число таких отличий выводится отдельно. Начало fragment coordinates у native SKView/SKRenderer и захвата `SKView.texture(from:)` различается; helper выбирает соответствующее преобразование. В Debug эти большие попиксельные сравнения заметно медленнее, поэтому выше указан Release.

Дополнительно сохраняются восемь моментов `walk`, wireframe и `vertices.json` с координатами/UV обоих skins. Изменение кадров — smoke check, не само по себе проверка правильности позы.

Для независимого сравнения позы используется официальный JS runtime. Он нужен только для проверки и не входит в Swift-приложение:

```sh
npm install --prefix /tmp/spine-mesh-oracle --ignore-scripts --no-audit --no-fund @esotericsoftware/spine-core@4.1.56
node Examples/MeshPrototype/Scripts/compare-reference.mjs /tmp/spine-mesh-oracle/node_modules/@esotericsoftware/spine-core/dist/index.js
```

Скрипт проверяет активные attachments, позиции каждой вершины и UV. Допуск координат — 0.005 единиц Spine, UV — 1e-6. Результат — `output/reference-comparison.json`. Установленный официальный runtime сопровождается собственной лицензией; его код в прототип не скопирован.

Изображения, отчёты и build artifacts находятся в игнорируемых `output/` и `.build/`. Результаты первой итерации — в [RESULTS.md](RESULTS.md), оптимизации — в [PERFORMANCE.md](PERFORMANCE.md).

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

## Границы результата

Это проверка жизнеспособности renderer на одном реальном Pro-примере, **не полная поддержка Spine Pro в библиотеке**.

- Нет IK/path/transform constraints, animation mixing, clipping, dark tint и специальных blend modes; fixture их не использует. Нет загрузки произвольных файлов через UI. Собственный fixture player принимает только нужные этому примеру каналы и normal transform inheritance.
- Atlas parser поддерживает одну страницу, untrimmed regions и rotation 0/90. `SKTextureAtlas`, subtextures и trimmed atlas не проверены. Texture/filtering задаются при создании mesh; изменения режима после создания не синхронизируются.
- Внешние края shader-треугольников имеют жёсткое покрытие без отдельного сглаживания. Не заявлена устойчивость всех произвольных тонких сеток и всех масштабов/устройств.
- Overdraw уменьшен; число узлов и CPU-обновления атрибутов пока не сокращены. 1/10/50 персонажей измерены на одной машине; результаты не переносятся автоматически на iOS/tvOS/watchOS.
- `.triangle` требует актуального framebuffer transform. Автоматическое определение промежуточных render targets внутри `SKEffectNode`/масок и других offscreen-эффектов не реализовано. Для этих случаев нужен отдельный контракт или прежний `.mesh` режим.
- Поведение `Skeleton.action(animation:)` основного проекта не затронуто: пример использует свой playhead. Интеграция с production skeleton — следующий самостоятельный этап.
- Автоматическая проверка живого интерфейса/клавиатуры по `code:visual-check` не выполнена: в среде отсутствует `macos-use`. Настройка инструмента описана в навыке `references/macos/setup.md`. GPU-изображения получены интеграционными render-тестами; это не скриншоты экрана и не замена UI automation.

Дальнейший эксперимент: уменьшить CPU-стоимость подготовки позы и SpriteKit render submission, число узлов/атрибутов и переключений shader state; отдельно проверить batching и реальные draw calls. Ограничение производительности теперь нужно искать по измеренным CPU/GPU показателям, а не по одной площади overdraw.

## Источник ассетов

Официальная [страница примеров Spine](https://esotericsoftware.com/spine-examples) ссылается на экспорт в репозитории runtimes. Здесь сохранены JSON, atlas, PNG и лицензия из [Goblins, revision 77a5db0ec6d16331f5efbaa7662bba9355bd3424](https://github.com/EsotericSoftware/spine-runtimes/tree/77a5db0ec6d16331f5efbaa7662bba9355bd3424/examples/goblins), ветка 4.1. Загрузчик не скачивает ничего при запуске.

Copyright © 2013 Esoteric Software LLC. Изображения распространяются с оригинальным [goblins-license.txt](Sources/MeshPrototype/Resources/goblins-license.txt): разрешена передача вместе с лицензией, коммерческое использование изображений запрещено. Поэтому это демонстрационные assets, не графика для коммерческой игры. Лицензия корневой библиотеки не заменяет лицензию этих изображений.
