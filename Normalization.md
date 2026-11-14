# Нормализация

## 1. Приведение схемы к пятой нормальной форме

### 1.1. Исходная схема

Исходные атрибуты, ФЗ и кандидатные ключи приведены в [Functionla_dependencies.md](Functionla_dependencies.md). Рассматриваются все 27 исходных отношений, включая таблицы ассоциаций. Исходная SQL-схема и наполнение сохранены в каталоге [befor_noramalization](befor_noramalization/).

Нормализованная схема из 28 таблиц реализована в корневом `ddl.sql`, её тестовое наполнение - в `insert.sql`. Таблицы `repair_with_inspection` и `repair_without_inspection` заменяют исходную таблицу `repair`. Дополнительные межтабличные проверки реализованы в `update.sql`.

ФЗ записываются через `->`, многозначные зависимости - через `->>`. `pi_X(R)` - проекция отношения на атрибуты X, `JOIN` - естественное соединение, `UNION` - объединение совместимых отношений. Ключом называется минимальный надключ.

Классические нормальные формы рассматриваются для отношений с определёнными значениями. Необязательные описательные поля SQL не становятся новыми определителями. Случай `repair.inspection_id IS NULL` разобран отдельно: неизвестное значение не рассматривается как общий идентификатор проверки для разных ремонтов.

### 1.2. Правила предметной области

- Номер чертежа уникален; чертёж относится к одному трубопроводу. Ревизия относится к одному чертежу; пара «чертёж + номер ревизии» уникальна.
- Спул использует одну ревизию и относится к одному объекту. Несколько спулов могут использовать одну ревизию. Объект должен входить в маршрут трубопровода, определяемого чертежом.
- Один компонент входит в один спул. Материал компонента может быть не указан. Запись изоляции хранит одну комбинацию утеплителя, защитного слоя и фактических толщин конкретного компонента.
- `pipeline_area` хранит характеристики конкретной пары «трубопровод + объект». Наличие трубопровода на одном объекте не означает наличие на всех остальных объектах.
- У одного сварщика могут быть разные сертификаты. Разные сварщики могут иметь одинаковое ФИО или номер удостоверения; уникальность удостоверения в SQL не задана.
- Поставщик определяется ID, кодом или парой «страна + налоговый номер». Названия поставщиков могут повторяться. Для одной поставки может быть несколько документов; документ уникален по поставке, типу и номеру.
- Сварное или фланцевое соединение связывает два разных компонента. Проверка относится к одному сварному соединению; проверок одного соединения может быть несколько.
- Ремонт относится к одному соединению. Ссылка на проверку необязательна; если она указана, проверка относится к ремонтируемому соединению.
- Участие сварщика и включение объектов в пакеты испытаний - конкретные зарегистрированные пары. Совпадение отдельных участников не создаёт автоматически новые пары.

Комбинации материалов изоляции, реквизитов поставщика, атрибутов ревизии и документа являются характеристиками одной записи. Модель не задаёт независимые множества таких характеристик и не требует образования всех комбинаций между ними. Отдельных правил совместимости проекций, порождающих новые записи, нет. Эти семантические условия используются при анализе МЗ и зависимостей соединения; они не выводятся из совпадений тестовых данных.

### 1.3. Первая нормальная форма

Каждая строка описывает один объект, событие или одну зарегистрированную связь. Атрибуты атомарны в принятой модели: в полях нет списков компонентов, сварщиков, проверок или документов. Повторяющиеся группы отсутствуют; сертификаты, документы, проверки и участники вынесены в отдельные отношения. У каждого отношения есть кандидатный ключ.

Исходные 27 отношений находятся в 1НФ. На этом этапе декомпозиция не выполняется.

### 1.4. Вторая нормальная форма

Для 2НФ каждый неключевой атрибут должен зависеть от полного кандидатного ключа, а не от его собственного подмножества. Проверяются все кандидатные ключи, включая альтернативные.

| Отношение | Кандидатные ключи | Проверка |
| --- | --- | --- |
| `area` | `{area_id}`; `{area_code}` | Все ключи простые; частичных зависимостей нет. |
| `pipeline` | `{pipeline_id}`; `{pipeline_code}` | Все ключи простые; частичных зависимостей нет. |
| `pipeline_area` | `{pipeline_id, area_id}` | `{area_id}+`, `{pipeline_id}+` не содержат неключевых атрибутов; ключ используется полностью. |
| `isometric_drawing` | `{isometric_id}`; `{isometric_number}` | Все ключи простые; частичных зависимостей нет. |
| `isometric_revision` | `{isometric_revision_id}`; `{isometric_id, revision}` | `{revision}+`, `{isometric_id}+` не содержат неключевых атрибутов; ключ используется полностью. |
| `spool` | `{spool_id}`; `{spool_code}` | Все ключи простые; частичных зависимостей нет. |
| `welder` | `{welder_id}`; `{welder_employer_no}` | Все ключи простые; частичных зависимостей нет. |
| `welder_certificate` | `{certificate_id}` | Все ключи простые; частичных зависимостей нет. |
| `component_type` | `{component_type_id}`; `{type_code}` | Все ключи простые; частичных зависимостей нет. |
| `material` | `{material_id}`; `{material_code}` | Все ключи простые; частичных зависимостей нет. |
| `insulation_material` | `{insulation_material_id}`; `{material_code}` | Все ключи простые; частичных зависимостей нет. |
| `cladding_material` | `{cladding_material_id}`; `{material_code}` | Все ключи простые; частичных зависимостей нет. |
| `vendor` | `{vendor_id}`; `{vendor_code}`; `{country, tax_id}` | `{tax_id}+`, `{country}+` не содержат неключевых атрибутов; ключ используется полностью. |
| `delivery` | `{delivery_id}`; `{delivery_code}` | Все ключи простые; частичных зависимостей нет. |
| `delivery_document` | `{delivery_document_id}`; `{delivery_id, document_type, document_number}` | `{document_type, document_number}+`, `{delivery_id, document_number}+`, `{delivery_id, document_type}+` не содержат неключевых атрибутов; ключ используется полностью. |
| `component` | `{component_id}`; `{component_no}` | Все ключи простые; частичных зависимостей нет. |
| `component_insulation` | `{component_id}` | Все ключи простые; частичных зависимостей нет. |
| `weld_joint` | `{weld_joint_id}`; `{weld_joint_no}` | Все ключи простые; частичных зависимостей нет. |
| `weld_assignment` | `{weld_joint_id, welder_id}` | Оба атрибута входят в единственный ключ; неключевых атрибутов нет. |
| `flange_connection` | `{flange_connection_id}`; `{flange_connection_no}` | Все ключи простые; частичных зависимостей нет. |
| `equipment` | `{equipment_id}`; `{equipment_code}` | Все ключи простые; частичных зависимостей нет. |
| `inspection` | `{inspection_id}` | Все ключи простые; частичных зависимостей нет. |
| `repair` | `{repair_id}` | Все ключи простые; частичных зависимостей нет. |
| `test_package` | `{test_package_id}`; `{test_package_code}` | Все ключи простые; частичных зависимостей нет. |
| `test_package_spool` | `{test_package_id, spool_id}` | Оба атрибута входят в единственный ключ; неключевых атрибутов нет. |
| `test_package_flange_connection` | `{test_package_id, flange_connection_id}` | Оба атрибута входят в единственный ключ; неключевых атрибутов нет. |
| `test_package_equipment` | `{test_package_id, equipment_id}` | Оба атрибута входят в единственный ключ; неключевых атрибутов нет. |

Все исходные отношения находятся в 2НФ. Декомпозиция, устраняющая транзитивные зависимости, относится к следующему этапу.

### 1.5. Третья нормальная форма

Для каждой нетривиальной ФЗ `X -> a` должно выполняться хотя бы одно условие: X является надключом или a входит в некоторый кандидатный ключ.

#### 1.5.1. Спул

```text
spool(spool_id, spool_code, isometric_revision_id, isometric_id, pipeline_id, area_id, weight_ton, fabrication_status)

Ключи: {spool_id}; {spool_code}

spool_id -> spool_code, isometric_revision_id, area_id, weight_ton, fabrication_status
spool_code -> spool_id
isometric_revision_id -> isometric_id
isometric_id -> pipeline_id
```

`isometric_revision_id` и `isometric_id` не являются надключами `spool`, а `isometric_id` и `pipeline_id` не входят в его кандидатные ключи. Последние две ФЗ нарушают 3НФ.

**Первое разбиение.** Устраняем `isometric_id -> pipeline_id`. Получены два отношения: `spool_step1` и `drawing_pipeline`.

```text
spool
-> spool_step1(spool_id, spool_code, isometric_revision_id, isometric_id, area_id, weight_ton, fabrication_status)
   drawing_pipeline(isometric_id, pipeline_id)
```

Общий атрибут - `isometric_id`. Он является ключом `drawing_pipeline`, поэтому соединение проекций не создаёт лишних строк и восстанавливает исходный `spool`.

**Второе разбиение.** Устраняем `isometric_revision_id -> isometric_id`. Получены два отношения: итоговый `spool` и `revision_drawing`.

```text
spool_step1
-> spool(spool_id, spool_code, isometric_revision_id, area_id, weight_ton, fabrication_status)
   revision_drawing(isometric_revision_id, isometric_id)
```

Общий атрибут - `isometric_revision_id`, ключ `revision_drawing`. Второе разбиение также выполняется без потерь.

`drawing_pipeline` уже содержится как проекция `isometric_drawing`, а `revision_drawing` - как проекция `isometric_revision`. Дополнительные таблицы для этих проекций не нужны. Их самостоятельные записи сохраняются: нормализация спулов не удаляет чертежи и ревизии, у которых ещё нет спулов.

**Итог для спула:**

```text
spool(spool_id, spool_code, isometric_revision_id, area_id, weight_ton, fabrication_status)
```

Кандидатные ключи: `{spool_id}` и `{spool_code}`. Из отношения удалены `isometric_id` и `pipeline_id`; остальные атрибуты сохранены.

| Выделенное отношение | Где хранятся его атрибуты в итоговой схеме |
| --- | --- |
| `drawing_pipeline(isometric_id, pipeline_id)` | В существующем `isometric_drawing`. |
| `revision_drawing(isometric_revision_id, isometric_id)` | В существующем `isometric_revision`. |

Для восстановления удалённых полей соединяем записи по совпадающим идентификаторам:

```text
spool.isometric_revision_id = isometric_revision.isometric_revision_id
isometric_revision.isometric_id = isometric_drawing.isometric_id
```

После соединения получаем `isometric_revision.isometric_id` и `isometric_drawing.pipeline_id` для каждого спула.

ФЗ исходного `spool` сохраняются в совокупности полученных отношений. Первичный ключ и уникальный код спула остаются в `spool`; зависимости ревизии и чертежа проверяются в соответствующих отношениях.

#### 1.5.2. Ремонт и необязательная проверка

```text
repair(repair_id, weld_joint_id, inspection_id, repair_date, repair_reason, repair_description, status)
```

В документе ФЗ `inspection_id -> weld_joint_id` указана только для записей с заполненным `inspection_id`. Это не безусловная ФЗ всей SQL-таблицы с `NULL`. По одним безусловным ФЗ она не выявляется как нарушение 3НФ; применять к ней обычную декомпозицию без учёта необязательной ссылки нельзя.

Для строгого реляционного разбора отдельно рассматриваем исходные ремонты с указанной проверкой и без неё.

В исходных записях с указанной проверкой:

```text
repair_id -> inspection_id, repair_date, repair_reason, repair_description, status
inspection_id -> weld_joint_id
```

Одна проверка может быть причиной нескольких ремонтов, поэтому `inspection_id` не является надключом. `weld_joint_id` - неключевой атрибут. В этой части данных имеется нарушение 3НФ.

**Разбиение ремонтов с проверкой.** Получены два отношения: `repair_with_inspection` и `inspection_joint`.

```text
repair_with_inspection(repair_id, inspection_id, repair_date, repair_reason, repair_description, status)
inspection_joint(inspection_id, weld_joint_id)
```

Общий атрибут `inspection_id` является ключом `inspection_joint`; соединение выполняется без потерь. `inspection_joint` уже хранится как проекция `inspection`, поэтому новая таблица для неё не создаётся.

**Результат для ремонтов без проверки:** `repair_without_inspection`.

```text
repair_without_inspection(repair_id, weld_joint_id, repair_date, repair_reason, repair_description, status)
```

**Итог для ремонта:** исходное `repair` заменено двумя отношениями.

```text
repair_with_inspection(repair_id, inspection_id, repair_date, repair_reason, repair_description, status)
repair_without_inspection(repair_id, weld_joint_id, repair_date, repair_reason, repair_description, status)
```

| Отношение результата | Что хранится | Откуда получаем соединение |
| --- | --- | --- |
| `repair_with_inspection` | Ремонт со ссылкой на проверку. | Через `inspection_id` в существующем `inspection`. |
| `repair_without_inspection` | Ремонт без ссылки на проверку. | Из собственного `weld_joint_id`. |

`inspection_joint(inspection_id, weld_joint_id)` представлено существующим `inspection`; отдельная таблица для него не добавляется.

Кандидатный ключ обоих новых отношений - `{repair_id}`. Каждый ремонт входит ровно в одно из них. Множества `repair_id` в этих отношениях не пересекаются; их объединение содержит все ремонты. Это межтабличное ограничение результата декомпозиции, а не следствие двух отдельных первичных ключей.

Восстановление исходного представлния:

1. Для `repair_with_inspection` получаем `weld_joint_id` соединением с `inspection` по `inspection_id`.
2. Для `repair_without_inspection` сохраняем собственный `weld_joint_id`, а `inspection_id` оставляем неуказанным.
3. Приводим обе части к исходному составу и порядку атрибутов `repair`, затем объединяем строки.

Разделение на две части - обработка необязательной ссылки, а не обычная проекция одной таблицы с `NULL`. Для части с проверкой доказано соединение без потерь. Для части без проверки все известные значения сохраняются непосредственно. Восстанавливается каждый ремонт, включая ремонт без проверки; фиктивная проверка с ID 0 не вводится.

#### 1.5.3. Остальные отношения

В остальных 25 исходных отношениях все нетривиальные ФЗ из исходного набора имеют слева надключ. Набор ФЗ эквивалентен набору ключевых зависимостей, поэтому его следствия не создают новых нарушений 3НФ. Дополнительная декомпозиция на этом этапе не нужна.

**Результат для остальных отношений:**

| Отношение | Результат этапа 3НФ |
| --- | --- |
| `area` | Без изменений. |
| `pipeline` | Без изменений. |
| `pipeline_area` | Без изменений. |
| `isometric_drawing` | Без изменений. |
| `isometric_revision` | Без изменений. |
| `welder` | Без изменений. |
| `welder_certificate` | Без изменений. |
| `component_type` | Без изменений. |
| `material` | Без изменений. |
| `insulation_material` | Без изменений. |
| `cladding_material` | Без изменений. |
| `vendor` | Без изменений. |
| `delivery` | Без изменений. |
| `delivery_document` | Без изменений. |
| `component` | Без изменений. |
| `component_insulation` | Без изменений. |
| `weld_joint` | Без изменений. |
| `weld_assignment` | Без изменений. |
| `flange_connection` | Без изменений. |
| `equipment` | Без изменений. |
| `inspection` | Без изменений. |
| `test_package` | Без изменений. |
| `test_package_spool` | Без изменений. |
| `test_package_flange_connection` | Без изменений. |
| `test_package_equipment` | Без изменений. |

#### 1.5.4. Итог этапа 3НФ

После преобразований логическая схема содержит 28 отношений: у `spool` удалены два избыточных поля, исходное `repair` заменено двумя отношениями. Отдельные `drawing_pipeline`, `revision_drawing` и `inspection_joint` в это количество не входят, поскольку соответствующие факты уже хранятся.

| Часть исходной схемы | Итог |
| --- | --- |
| `spool` | Одно отношение без `isometric_id` и `pipeline_id`. |
| `repair` | Два отношения: `repair_with_inspection` и `repair_without_inspection`. |
| Остальные 25 отношений | Сохранены без изменений. |

Все 28 отношений результата находятся в 3НФ. Их полный состав атрибутов приведён в п. 1.9.

### 1.6. Нормальная форма Бойса-Кодда

Проверяем, что в каждом отношении определитель любой нетривиальной ФЗ является надключом. Сначала расматриваем отношения, полученные в п. 1.5: изменённое `spool` и два новых отношения для ремонта.

**`spool`.** После удаления `isometric_id` и `pipeline_id` набор ФЗ имеет вид:

```text
spool_id -> spool_code, isometric_revision_id, area_id, weight_ton, fabrication_status
spool_code -> spool_id
```

Кандидатные ключи - `{spool_id}` и `{spool_code}`. Каждый определитель является ключом; через него выводятся все атрибуты отношения. Условие НФБК выполнено.

**`repair_with_inspection`.** Соединение определяется через проверку, поэтому собственного `weld_joint_id` здесь нет:

```text
repair_id -> inspection_id, repair_date, repair_reason, repair_description, status
```

Кандидатный ключ - `{repair_id}`. Он является определителем всех неключевых атрибутов; условие НФБК выполнено.

**`repair_without_inspection`.** Ремонт без проверки хранит ссылку непосредственно на соединение:

```text
repair_id -> weld_joint_id, repair_date, repair_reason, repair_description, status
```

Кандидатный ключ - `{repair_id}`. Он является определителем всех неключевых атрибутов; условие НФБК выполнено.

**Остальные 25 отношений.** Их состав атрибутов, ФЗ и кандидатные ключи не изменились. Используем неприводимые множества ФЗ из п. 4 [Functionla_dependencies.md](Functionla_dependencies.md). В каждом из этих множеств определитель каждой ФЗ является кандидатным ключом, а значит, надключом. Следовательно, эти отношения также находятся в НФБК.

**Итог проверки:** все 28 отношений находятся в НФБК. Ниже собраны их кандидатные ключи.

| Отношение результата | Кандидатные ключи | НФБК |
| --- | --- | --- |
| `area` | `{area_id}`; `{area_code}` | Да |
| `pipeline` | `{pipeline_id}`; `{pipeline_code}` | Да |
| `pipeline_area` | `{pipeline_id, area_id}` | Да |
| `isometric_drawing` | `{isometric_id}`; `{isometric_number}` | Да |
| `isometric_revision` | `{isometric_revision_id}`; `{isometric_id, revision}` | Да |
| `spool` | `{spool_id}`; `{spool_code}` | Да |
| `welder` | `{welder_id}`; `{welder_employer_no}` | Да |
| `welder_certificate` | `{certificate_id}` | Да |
| `component_type` | `{component_type_id}`; `{type_code}` | Да |
| `material` | `{material_id}`; `{material_code}` | Да |
| `insulation_material` | `{insulation_material_id}`; `{material_code}` | Да |
| `cladding_material` | `{cladding_material_id}`; `{material_code}` | Да |
| `vendor` | `{vendor_id}`; `{vendor_code}`; `{country, tax_id}` | Да |
| `delivery` | `{delivery_id}`; `{delivery_code}` | Да |
| `delivery_document` | `{delivery_document_id}`; `{delivery_id, document_type, document_number}` | Да |
| `component` | `{component_id}`; `{component_no}` | Да |
| `component_insulation` | `{component_id}` | Да |
| `weld_joint` | `{weld_joint_id}`; `{weld_joint_no}` | Да |
| `weld_assignment` | `{weld_joint_id, welder_id}` | Да |
| `flange_connection` | `{flange_connection_id}`; `{flange_connection_no}` | Да |
| `equipment` | `{equipment_id}`; `{equipment_code}` | Да |
| `inspection` | `{inspection_id}` | Да |
| `repair_with_inspection` | `{repair_id}` | Да |
| `repair_without_inspection` | `{repair_id}` | Да |
| `test_package` | `{test_package_id}`; `{test_package_code}` | Да |
| `test_package_spool` | `{test_package_id, spool_id}` | Да |
| `test_package_flange_connection` | `{test_package_id, flange_connection_id}` | Да |
| `test_package_equipment` | `{test_package_id, equipment_id}` | Да |

### 1.7. Четвёртая нормальная форма

Нетривиальная МЗ `X ->> Y` требует независимого комбинирования значений Y со значениями остальных атрибутов при фиксированном X. Для 4НФ определитель каждой такой МЗ должен быть надключом.

Используется теорема 5.2 Дейта-Фейгина: отношение в НФБК, имеющее хотя бы один простой кандидатный ключ, находится в 4НФ. 
У 23 отношений результата есть простой ключ; НФБК установлена в п. 1.6. Поэтому для них применима эта теорема.

У остальных пяти отношений ключи составные:

| Отношение | Проверка МЗ |
| --- | --- |
| `pipeline_area` | Обогрев, минимальная толщина и огнезащита относятся к конкретной паре «трубопровод + объект». При фиксированном трубопроводе характеристики разных объектов не образуют независимые множества. Все характеристики определяются полной парой. |
| `weld_assignment` | Два атрибута. МЗ с непустым определителем тривиальны. МЗ с пустым определителем означала бы, что каждый сварщик участвует в каждом зарегистрированном соединении; такого правила нет. |
| `test_package_spool` | Два атрибута. Все сочетания пакетов и спулов не требуются; фиксируются только зарегистрированные пары. |
| `test_package_flange_connection` | Два атрибута. Каждый пакет не обязан включать каждое фланцевое соединение. |
| `test_package_equipment` | Два атрибута. Каждый пакет не обязан включать каждую единицу оборудования. |

Пример для `pipeline_area`, сокращённо `P, A, H, T, F`:

```text
(P1, A1, false,   0, false)
(P1, A2, true,   40, true)
```

Эти строки допустимы. МЗ `P ->> A` требовала бы также перестановки объектов и характеристик, например `(P1, A1, true, 40, true)`. Эта строка не требуется предметной областью и конфликтовала бы с функциональной зависимостью пары на характеристики. Аналогично не независимы характеристики и при фиксированном объекте. Самостоятельных нетривиальных МЗ, не следующих из ключа, для этого отношения модель не задаёт.

Таким образом, все отношения результата находятся в 4НФ. Отдельные сертификаты, проверки, документы и участники остаются раздельными отношениями: их объединение в одну таблицу могло бы потребовать независимого комбинирования фактов и породить избыточные строки.

### 1.8. Пятая нормальная форма

Для 5НФ каждая зависимость соединения должна следовать из ограничений кандидатных ключей. Наличие простого первичного ключа само по себе не доказывает 5НФ, если есть составные альтернативные ключи.

Используется теорема 4.1 Дейта-Фейгина: если отношение находится в 3НФ и все его кандидатные ключи простые, то оно находится в 5НФ.

У 20 отношений результата все кандидатные ключи простые. Их 3НФ следует из НФБК, проверенной в п. 1.6, поэтому применяется теорема 4.1.

Для четырёх двухатрибутных ассоциаций `weld_assignment`, `test_package_spool`, `test_package_flange_connection`, `test_package_equipment` единственная декомпозиция на собственные непустые проекции разделяет два атрибута. Обратное соединение становится декартовым произведением и в общем случае добавляет незарегистрированные пары. Например, пары `(WJ1, W1)` и `(WJ2, W2)` не требуют пар `(WJ1, W2)` и `(WJ2, W1)`. Нетривиальной зависимости соединения здесь нет.

Остаются четыре отношения с составными ключами и дополнительными атрибутами. Для них первая теорема автоматически не применяется.

| Отношение | Единый факт и проверка независимости проекций |
| --- | --- |
| `pipeline_area` | Полная пара «трубопровод + объект» определяет один набор характеристик. Совпадение отдельных характеристик на разных участках не означает существования участка с их перестановкой. |
| `isometric_revision` | ID ревизии и пара «чертёж + номер ревизии» идентифицируют одну запись. Дата относится к этой записи; совпадение дат или номеров на разных чертежах не создаёт новую ревизию. |
| `vendor` | ID, код и пара «страна + налоговый номер» идентифицируют одного поставщика. Налоговый номер, страна, название и контакты не образуют независимые списки, комбинации которых обязаны существовать. |
| `delivery_document` | ID и тройка «поставка + тип + номер» определяют один документ. Документ одной поставки не становится документом другой поставки из-за совпадения типа или номера. |

Для этих отношений набор зависимостей соединения определяется ключевыми зависимостями и правилами п. 1.2: дополнительных правил, по которым совместимые проекции обязательно порождают новый факт, нет. Поэтому всякая обязательная зависимость соединения следует из кандидатных ключей; отношения находятся в 5НФ относительно принятых правил предметной области. Утверждение не основано только на количестве атрибутов или наличии ID.

Проверить зависимость соединения, следующую из ключей, можно алгоритмом принадлежности из раздела 4 статьи Дейта-Фейгина: объединять компоненты проекции, если их пересечение содержит кандидатный ключ; зависимость следует из ключей, когда в результате получается полный набор атрибутов. Если проекции нельзя так восстановить и их соединение требует новых комбинаций, соответствующее правило должно отдельно следовать из предметной области. В нашем случае такие дополнительные правила не приняты.

Пример недопустимого разделения характеристик участка:

```text
pipeline_area(P, A, H, T, F)
R = {(P1, A1, false, 0, false), (P1, A2, true, 40, true)}

pi_(P,A)(R) JOIN pi_(P,H,T,F)(R)
```

Соединение добавляет `(P1, A1, true, 40, true)` и `(P1, A2, false, 0, false)`. Значит, такую независимость участков и характеристик предполагать нельзя. Это контрпример для указанного разбиения, а не отдельное доказательство отсутствия всех возможных зависимостей соединения. Общий вывод опирается на сформулированную семантику и критерий 5НФ.

Дополнительная проверка для ревизий: рассмотрим возможное разбиение на `(revision_id, drawing_id, revision)`, `(drawing_id, issue_date)` и `(revision, issue_date)`. Сокращённые имена обозначают соответствующие атрибуты `isometric_revision`.

```text
(R1, D1, 00, 2024-01-01)
(R2, D1, 01, 2024-02-01)
(R3, D2, 00, 2024-02-01)
```

Оба кандидатных ключа уникальны, порядок дат соблюдён. Соединение указанных проекций дополнтельно создаёт `(R1, D1, 00, 2024-02-01)`. Следовательно, совместимость номера ревизии, чертежа и даты не заменяет единую запись ревизии.

Для поставщика аналогичное разбиение на «идентификаторы и реквизиты без адреса», «страна + адрес» и «налоговый номер + адрес» также не требуется:

```text
(V1, VC1, RU, 111, Address1)
(V2, VC2, RU, 222, Address2)
(V3, VC3, DE, 111, Address2)
```

Здесь приведены ID, код, страна, налоговый номер и адрес; остальные поля можно дополнить допустимыми значениями. Все ключи соблюдены. Соединение создаёт дополнительный адрес `Address2` для V1. Совместное появление адреса у других поставщиков не делает его адресом V1.

Для документа нельзя заменять исходное отношение независимыми списками типов и номеров внутри поставки:

```text
(DD1, DEL1, Invoice, INV-01)
(DD2, DEL1, DeliveryNote, DN-01)
```

Проекции `(delivery_id, document_type)` и `(delivery_id, document_number)` дают также несуществующие сочетания `(DEL1, Invoice, DN-01)` и `(DEL1, DeliveryNote, INV-01)`, а ID документа при таком разделении вообще теряется. Для сохранения ID документ должен оставаться связан со своими реквизитами. Эти контрпримеры проверяют конкретные возможные ошибки декомпозиции; утверждение 5НФ, как и выше, относится к заданному набору правил модели.

Новых декомпозиций на этапах 4НФ и 5НФ не требуется.

### 1.9. Отношения результата

В результате нормализации получено 28 отношений:

```text
area(area_id, area_code, area_name, area_type)
```

```text
pipeline(pipeline_id, pipeline_code, service, pressure_category, temperature_category)
```

```text
pipeline_area(pipeline_id, area_id, heat_tracing, min_insulation_thickness_mm, passive_fire_protection)
```

```text
isometric_drawing(isometric_id, isometric_number, pipeline_id)
```

```text
isometric_revision(isometric_revision_id, isometric_id, revision, issue_date)
```

```text
spool(spool_id, spool_code, isometric_revision_id, area_id, weight_ton, fabrication_status)
```

```text
welder(welder_id, welder_employer_no, welder_name, welder_license_no, welder_last_attestation_date)
```

```text
welder_certificate(certificate_id, welder_id, certificate_number, standard, valid_until)
```

```text
component_type(component_type_id, type_code, type_name)
```

```text
material(material_id, material_code, material_name, material_standard)
```

```text
insulation_material(insulation_material_id, material_code, material_name)
```

```text
cladding_material(cladding_material_id, material_code, material_name, coating)
```

```text
vendor(vendor_id, vendor_name, vendor_code, country, tax_id, vendor_address, phone, email, contact_name, contact_position)
```

```text
delivery(delivery_id, delivery_code, vendor_id, delivery_date)
```

```text
delivery_document(delivery_document_id, delivery_id, document_type, document_number)
```

```text
component(component_id, component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no)
```

```text
component_insulation(component_id, insulation_material_id, insulation_thickness_mm, cladding_material_id, cladding_thickness_mm)
```

```text
weld_joint(weld_joint_id, weld_joint_no, first_component_id, second_component_id, weld_type, welding_process, weld_date, status)
```

```text
weld_assignment(weld_joint_id, welder_id)
```

```text
flange_connection(flange_connection_id, flange_connection_no, first_component_id, second_component_id, gasket_type, bolt_specification, assembly_date, status)
```

```text
equipment(equipment_id, equipment_code, equipment_type, equipment_name, area_id, vendor_id, manufacturing_status)
```

```text
inspection(inspection_id, weld_joint_id, inspection_type, inspection_date, result, report_no, defect_description)
```

```text
repair_with_inspection(repair_id, inspection_id, repair_date, repair_reason, repair_description, status)
```

```text
repair_without_inspection(repair_id, weld_joint_id, repair_date, repair_reason, repair_description, status)
```

```text
test_package(test_package_id, test_package_code, test_type, test_date, status)
```

```text
test_package_spool(test_package_id, spool_id)
```

```text
test_package_flange_connection(test_package_id, flange_connection_id)
```

```text
test_package_equipment(test_package_id, equipment_id)
```

### 1.10. Сохранение информации и ограничений

| Исходное правило | После нормализации |
| --- | --- |
| Ревизия спула согласована с чертежом | Спул ссылается на ревизию, ревизия - на чертёж; дублируемый `isometric_id` у спула не хранится. |
| Трубопровод спула согласован с чертежом | Трубопровод получается из чертежа; дублируемый `pipeline_id` у спула не хранится. |
| Объект спула принадлежит маршруту трубопровода | Существование пары `(pipeline_id чертежа, area_id спула)` в `pipeline_area` проверяется триггерами из `update.sql`. Они заменяют составной FK исходной схемы. |
| Проверка ремонта относится к ремонтируемому соединению | Для `repair_with_inspection` соединение определяется через `inspection`; несовпадающего второго значения в записи нет. Для `repair_without_inspection` соединение хранится непосредственно. |
| Каждый ремонт существует независимо от наличия проверки | Все ремонты разделены на два непересекающихся множества; обязательная проверка для ремонта без проверки не вводится. |
| Глобальная идентификация ремонта | ID уникален в объединении двух отношений; каждый ID находится ровно в одном из них. Отдельных PK недостаточно для этого межтабличного правила. |
| Даты ревизий не убывают при увеличении номера | Правило сохраняется в `isometric_revision`; нормализация не отменяет проверку порядка дат. |
| Минимум два участка у трубопровода | Сохраняется межтабличное ограничение между `pipeline` и `pipeline_area`; из нормальных форм оно не следует. |
| Фактическая изоляция не тоньше требуемой | Для существующей записи изоляции сравниваются `component_insulation.insulation_thickness_mm` и `pipeline_area.min_insulation_thickness_mm`; участок определяется через компонент, спул, ревизию и чертёж. Отсутствие записи об изоляции не трактуется как нулевая толщина. |
| Допуск спула в пакет | Статус спула должен быть `released`, `installed` или `tested`; нормализация не заменяет это правило. |
| Документы, сертификаты, проверки и пары участия не дублируются по установленным ключам | Исходные ключи 25 неизменённых отношений сохраняются; спул сохраняет ID и код. Ключи двух отношений ремонта приведены в п. 1.6. |

Соединение без потерь для декомпозиций по ФЗ проверено по общему атрибуту, определяющему выделяемое отношение. Для сохранённых ФЗ приведены пути восстановления. Структура и ключи заданы в `ddl.sql`, дополнительные межтабличные ограничения реализованы триггерами в `update.sql`.
