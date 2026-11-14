# Хранимые процедуры

## 1. Определение хранимых процедур, необходимых для работы проекта

Составные типы объединяют связанные значения в один параметр. Для нескольких записей передаётся массив составного типа; данные можно вводить вручную через `ROW(...)`. Типы и процедуры реализованы в `update.sql` для PostgreSQL 18.6.

| № | Название | Описание | Входные параметры |
| --- | --- | --- | --- |
| 1 | Регистрация трубопровода, его участков и требований, `create_pipeline_with_areas` | Создаёт трубопровод и его участки на существующих объектах. Проверяет наличие минимум двух участков и отсутствие повторов. Чертежи и спулы отдельно не создаёт. | `:pipeline` - данные трубопровода типа `pipeline_input`; `:areas` - массив участков типа `pipeline_area_input[]` |
| 2 | Регистрация поставки с документами и компонентами, `register_delivery_with_documents` | Создаёт поставку от существующего поставщика, все её документы и компоненты. Компоненты привязываются к существующим спулам; при необходимости добавляется их изоляция. | `:delivery` - поставка типа `delivery_input`; `:documents` - массив `delivery_document_input[]`; `:components` - массив `component_input[]` |
| 3 | Регистрация компонента с изоляцией, `register_component_with_insulation` | Добавляет компонент к существующим спулу и поставке. При наличии изоляции записывает утеплитель и верхний защитный слой, проверяет толщины и минимум участка. | `:delivery_code` - код поставки; `:component` - данные типа `component_input` |
| 4 | Регистрация сварщика с сертификатами, `register_welder_with_certificates` | Создаёт сварщика и записи его сертификатов. Пустой список сертификатов допускается: сварщик относится к стажёрам. | `:welder` - данные типа `welder_input`; `:certificates` - массив `welder_certificate_input[]` |
| 5 | Регистрация сварного соединения с участниками, `register_weld_with_welders` | Создаёт соединение двух разных компонентов и записывает участие указанных сварщиков. Проверяет существование компонентов и сварщиков, отсутствие повторов участников. | `:weld_joint` - данные типа `weld_joint_input`; `:welder_employer_nos` - массив табельных номеров сварщиков |
| 6 | Регистрация фланцевого соединения, `register_flange_connection` | Создаёт соединение с данными прокладки, крепежа и сборки. Проверяет разные компоненты и допустимость их типов для фланцевого соединения. | `:flange_connection` - данные типа `flange_connection_input` |
| 7 | Заполнение пакета испытаний, `add_test_package_contents` | Добавляет элементы в существующий пакет испытаний со статусом `planned`. Проверяет существование элементов и отсутствие повторов; для спулов допустимы `released`, `installed`, `tested`. | `:test_package_code` - код пакета испытаний; `:spool_codes` - массив номеров спулов; `:flange_connection_nos` - массив номеров фланцевых соединений; `:equipment_codes` - массив кодов оборудования |

### Наборы входных данных

| № | Тип | Короткое описание | Поля |
| --- | --- | --- | --- |
| 1 | `pipeline_input` | Код, назначение и категории давления и температуры трубопровода. | `pipeline_code`, `service`, `pressure_category`, `temperature_category` |
| 2 | `pipeline_area_input` | Объект и требования к участку: обогрев, утеплитель и огнезащита. | `area_code`, `heat_tracing`, `min_insulation_thickness_mm`, `passive_fire_protection` |
| 3 | `delivery_input` | Код поставки, поставщик и дата поставки. | `delivery_code`, `vendor_code`, `delivery_date` |
| 4 | `delivery_document_input` | Тип и номер документа поставки. | `document_type`, `document_number` |
| 5 | `component_input` | Компонент спула: тип, материал, размеры, масса и сведения об изоляции. | `component_no`, `type_code`, `spool_code`, `material_code`, `nominal_diameter_inch`, `wall_thickness_mm`, `length_mm`, `width_mm`, `height_mm`, `weight_ton`, `certificate_no`, `insulation` |
| 6 | `component_insulation_input` | Материалы и толщины утеплителя и верхнего защитного слоя. | `insulation_material_code`, `insulation_thickness_mm`, `cladding_material_code`, `cladding_thickness_mm` |
| 7 | `welder_input` | ФИО сварщика, табельный номер, удостоверение и дата аттестации. | `welder_employer_no`, `welder_name`, `welder_license_no`, `welder_last_attestation_date` |
| 8 | `welder_certificate_input` | Номер сертификата, стандарт и дата окончания действия. | `certificate_number`, `standard`, `valid_until` |
| 9 | `weld_joint_input` | Компоненты сварного соединения, технология, дата и состояние. | `weld_joint_no`, `first_component_no`, `second_component_no`, `weld_type`, `welding_process`, `weld_date`, `status` |
| 10 | `flange_connection_input` | Компоненты фланцевого соединения, прокладка, крепёж, дата и состояние. | `flange_connection_no`, `first_component_no`, `second_component_no`, `gasket_type`, `bolt_specification`, `assembly_date`, `status` |

Поле `component_input.insulation` имеет тип `component_insulation_input`; `NULL` означает, что изоляция не регистрируется. Необязательные поля соответствуют `ddl.sql`. 

При регистрации фланцевого соединения оба компонента должны иметь тип `FLG-WN`, `FLG-BL`, `VLV-*`, `STRAINER`, `EXP-JOINT` или `ORIFICE`. В рамках проекта эти типы считаются фланцевыми; `VLV-*` означает все коды с префиксом `VLV-`. Проверка выполняется внутри `register_flange_connection`, при прямом `INSERT` в таблицу она не применяется. Отдельная таблица `equipment` в этой операции не участвует.

Процедуры завершаются успешно либо выдают ошибку с причиной. При ошибке частичные изменения операции не сохраняются.
