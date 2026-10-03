# Spine meshes через SpriteKit nodes + shader

Изолированный macOS-прототип. Запускается в обычном `SKView`, без Metal host и без изменений основного target `Spine`.

Показывает официальный **Goblins Pro 4.1.17**, skins `goblin` и `goblingirl`, анимацию `walk`. В примере воспроизводятся обычные/weighted meshes, deform timelines, linked feet, переключение attachments при моргании и rotated atlas regions. Regions рисуются тем же треугольным renderer, что и meshes: порядок слотов сохраняется.

## Запуск

Из корня репозитория, на macOS с установленным Xcode:

```sh
swift run -c release --package-path Examples/MeshPrototype MeshPrototype
```

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
- Все прямоугольники одного mesh пока покрывают **его общий bounding box**. Это обеспечивает одинаковые координаты пикселя для обеих сторон ребра, но увеличивает overdraw. Размер зоны обработки приблизительно пропорционален `число треугольников × площадь bounds mesh`.
- Primary texture — белый texel. Atlas page передаётся отдельным texture uniform. UV имеют начало снизу слева и адресуют полную текстуру. Режим `.nearest` реализован явным выбором центра texel, поскольку в проверенной конфигурации SpriteKit texture uniform иначе использовал linear sampling.
- `Sources/MeshPrototype/Goblin.swift`: отдельный проигрыватель **только bundled fixture 4.1.17**; матрицы костей, skinning, sparse deform и linked meshes вычисляются на CPU. Bezier аппроксимируется десятью сегментами для совпадения с runtime 4.1. Это не новая версия production parser.
- `Sources/MeshPrototype/main.swift`: демонстрационная сцена и автоматические GPU-проверки.

Для подключения renderer достаточно передать `positions`, `uvs`, `indices` и полную `SKTexture`, затем вызывать `updatePositions` после расчёта позы. `TriangleRenderer` пока находится внутри пакета примера и не экспортируется основной библиотекой.

## Проверки

```sh
swift test --package-path Examples/MeshPrototype
swift run --package-path Examples/MeshPrototype MeshPrototype --verify Examples/MeshPrototype/output
```

Второй запуск ненадолго открывает окно, затем завершает процесс с кодом 0 при успехе. Нужна графическая macOS-сессия. Он рисует через `SKView.texture(from:crop:)`, сохраняет PNG и сравнивает пиксели с обычным `SKSpriteNode`: квадрат, обратный winding, центрированный/смещённый стык четырёх треугольников, parent alpha, отражение, уменьшение, поворот, субпиксельное смещение, nearest/linear filtering. Проверяется и прозрачная область снаружи. Допуск — 2/255 на канал; тест отклоняет пустой рендер.

Дополнительно сохраняются восемь моментов `walk`, wireframe и `vertices.json` с координатами/UV обоих skins. Изменение кадров — smoke check, не само по себе проверка правильности позы.

Для независимого сравнения позы используется официальный JS runtime. Он нужен только для проверки и не входит в Swift-приложение:

```sh
npm install --prefix /tmp/spine-mesh-oracle --ignore-scripts --no-audit --no-fund @esotericsoftware/spine-core@4.1.56
node Examples/MeshPrototype/Scripts/compare-reference.mjs /tmp/spine-mesh-oracle/node_modules/@esotericsoftware/spine-core/dist/index.js
```

Скрипт проверяет активные attachments, позиции каждой вершины и UV. Допуск координат — 0.005 единиц Spine, UV — 1e-6. Результат — `output/reference-comparison.json`. Установленный официальный runtime сопровождается собственной лицензией; его код в прототип не скопирован.

Изображения, отчёты и build artifacts находятся в игнорируемых `output/` и `.build/`. Зафиксированные результаты этой итерации — в [RESULTS.md](RESULTS.md).

## Границы результата

Это проверка жизнеспособности renderer на одном реальном Pro-примере, **не полная поддержка Spine Pro в библиотеке**.

- Нет IK/path/transform constraints, animation mixing, clipping, dark tint и специальных blend modes; fixture их не использует. Нет загрузки произвольных файлов через UI. Собственный fixture player принимает только нужные этому примеру каналы и normal transform inheritance.
- Atlas parser поддерживает одну страницу, untrimmed regions и rotation 0/90. `SKTextureAtlas`, subtextures и trimmed atlas не проверены. Texture/filtering задаются при создании mesh; изменения режима после создания не синхронизируются.
- Внешние края shader-треугольников имеют жёсткое покрытие без отдельного сглаживания. Не заявлена устойчивость всех произвольных тонких сеток и всех масштабов/устройств.
- Overdraw, число узлов и CPU-обновления атрибутов пока не оптимизированы. Проверки offscreen-рендера не являются benchmark FPS. Нагрузки 10/50 персонажей, iOS/tvOS/watchOS не проверены.
- Поведение `Skeleton.action(animation:)` основного проекта не затронуто: пример использует свой playhead. Интеграция с production skeleton — следующий самостоятельный этап.
- Автоматическая проверка живого интерфейса/клавиатуры по `code:visual-check` не выполнена: в среде отсутствует `macos-use`. Настройка инструмента описана в навыке `references/macos/setup.md`. GPU-изображения получены интеграционными render-тестами; это не скриншоты экрана и не замена UI automation.

Дальнейший эксперимент: уменьшить прямоугольники до bounds каждого треугольника и повторить проверки общих рёбер при движении, после чего измерить время кадра и draw calls на целевых устройствах.

## Источник ассетов

Официальная [страница примеров Spine](https://esotericsoftware.com/spine-examples) ссылается на экспорт в репозитории runtimes. Здесь сохранены JSON, atlas, PNG и лицензия из [Goblins, revision 77a5db0ec6d16331f5efbaa7662bba9355bd3424](https://github.com/EsotericSoftware/spine-runtimes/tree/77a5db0ec6d16331f5efbaa7662bba9355bd3424/examples/goblins), ветка 4.1. Загрузчик не скачивает ничего при запуске.

Copyright © 2013 Esoteric Software LLC. Изображения распространяются с оригинальным [goblins-license.txt](Sources/MeshPrototype/Resources/goblins-license.txt): разрешена передача вместе с лицензией, коммерческое использование изображений запрещено. Поэтому это демонстрационные assets, не графика для коммерческой игры. Лицензия корневой библиотеки не заменяет лицензию этих изображений.
