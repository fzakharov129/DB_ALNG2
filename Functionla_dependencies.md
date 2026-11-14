# Функциональные зависимости

## 1. Набор атрибутов и отношения

Атрибуты приведены по исходной схеме из `befor_noramalization/ddl.sql`, до нормализации. Итоговая схема описана в [Normalization.md](Normalization.md) и корневом `ddl.sql`. Имена атрибутов относятся к указанному отношению. `R(имя)` обозначает полный набор атрибутов отношения, `X+` - замыкание, `F` - исходный набор ФЗ, `G` - неприводимое множество.

Необязательные атрибуты сохраняються в записи отношения. Ключи состоят из обязательных атрибутов; из неизвестных значений `NULL` зависимости не выводятся. Для одинакового ключа допускается одна запись с определёнными или неуказанными значениями остальных полей. Условные зависимости с необязательным определителем указаны отдельно и не входят в безусловное множество `F`.

Названия, ФИО, номера удостоверений сварщиков, сертификатов и отчётов не считаются уникальными без соответствующего правила схемы. Ограничения толщины изоляции, порядка дат, количества участков и допуска к испытаниям не заменяют функциональные зависимости.

### `area`

```text
area(area_id, area_code, area_name, area_type)
```

### `pipeline`

```text
pipeline(pipeline_id, pipeline_code, service, pressure_category, temperature_category)
```

### `pipeline_area`

```text
pipeline_area(pipeline_id, area_id, heat_tracing, min_insulation_thickness_mm, passive_fire_protection)
```

### `isometric_drawing`

```text
isometric_drawing(isometric_id, isometric_number, pipeline_id)
```

### `isometric_revision`

```text
isometric_revision(isometric_revision_id, isometric_id, revision, issue_date)
```

### `spool`

```text
spool(spool_id, spool_code, isometric_revision_id, isometric_id, pipeline_id, area_id, weight_ton, fabrication_status)
```

### `welder`

```text
welder(welder_id, welder_employer_no, welder_name, welder_license_no, welder_last_attestation_date)
```

### `welder_certificate`

```text
welder_certificate(certificate_id, welder_id, certificate_number, standard, valid_until)
```

### `component_type`

```text
component_type(component_type_id, type_code, type_name)
```

### `material`

```text
material(material_id, material_code, material_name, material_standard)
```

### `insulation_material`

```text
insulation_material(insulation_material_id, material_code, material_name)
```

### `cladding_material`

```text
cladding_material(cladding_material_id, material_code, material_name, coating)
```

### `vendor`

```text
vendor(vendor_id, vendor_name, vendor_code, country, tax_id, vendor_address, phone, email, contact_name, contact_position)
```


### `delivery`

```text
delivery(delivery_id, delivery_code, vendor_id, delivery_date)
```

### `delivery_document`

```text
delivery_document(delivery_document_id, delivery_id, document_type, document_number)
```

### `component`

```text
component(component_id, component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no)
```

### `component_insulation`

```text
component_insulation(component_id, insulation_material_id, insulation_thickness_mm, cladding_material_id, cladding_thickness_mm)
```

### `weld_joint`

```text
weld_joint(weld_joint_id, weld_joint_no, first_component_id, second_component_id, weld_type, welding_process, weld_date, status)
```

### `weld_assignment`

```text
weld_assignment(weld_joint_id, welder_id)
```

### `flange_connection`

```text
flange_connection(flange_connection_id, flange_connection_no, first_component_id, second_component_id, gasket_type, bolt_specification, assembly_date, status)
```

### `equipment`

```text
equipment(equipment_id, equipment_code, equipment_type, equipment_name, area_id, vendor_id, manufacturing_status)
```

### `inspection`

```text
inspection(inspection_id, weld_joint_id, inspection_type, inspection_date, result, report_no, defect_description)
```

### `repair`

```text
repair(repair_id, weld_joint_id, inspection_id, repair_date, repair_reason, repair_description, status)
```

### `test_package`

```text
test_package(test_package_id, test_package_code, test_type, test_date, status)
```

### `test_package_spool`

```text
test_package_spool(test_package_id, spool_id)
```

### `test_package_flange_connection`

```text
test_package_flange_connection(test_package_id, flange_connection_id)
```

### `test_package_equipment`

```text
test_package_equipment(test_package_id, equipment_id)
```

## 2. Функциональные зависимости

Перечисленны нетривиальные ФЗ, из которых выводятся остальные. `F = {}` означает отсутствие нетривиальных ФЗ.

### `area`

```text
area_id -> area_code, area_name, area_type
area_code -> area_id
```

### `pipeline`

```text
pipeline_id -> pipeline_code, service, pressure_category, temperature_category
pipeline_code -> pipeline_id
```

### `pipeline_area`

```text
pipeline_id, area_id -> heat_tracing, min_insulation_thickness_mm, passive_fire_protection
```

### `isometric_drawing`

```text
isometric_id -> isometric_number, pipeline_id
isometric_number -> isometric_id
```

### `isometric_revision`

```text
isometric_revision_id -> isometric_id, revision, issue_date
isometric_id, revision -> isometric_revision_id
```

### `spool`

```text
spool_id -> spool_code, isometric_revision_id, isometric_id, pipeline_id, area_id, weight_ton, fabrication_status
spool_code -> spool_id
isometric_revision_id -> isometric_id
isometric_id -> pipeline_id
```

ФЗ `isometric_revision_id -> isometric_id` и `isometric_id -> pipeline_id` следуют из обязательных составных внешних ключей и уникальности записей ревизии и чертежа. Одна ревизия может использоваться несколькими спулами; `isometric_revision_id` не определяет `spool_id`.

### `welder`

```text
welder_id -> welder_employer_no, welder_name, welder_license_no, welder_last_attestation_date
welder_employer_no -> welder_id
```

### `welder_certificate`

```text
certificate_id -> welder_id, certificate_number, standard, valid_until
```

### `component_type`

```text
component_type_id -> type_code, type_name
type_code -> component_type_id
```

### `material`

```text
material_id -> material_code, material_name, material_standard
material_code -> material_id
```

### `insulation_material`

```text
insulation_material_id -> material_code, material_name
material_code -> insulation_material_id
```

### `cladding_material`

```text
cladding_material_id -> material_code, material_name, coating
material_code -> cladding_material_id
```

### `vendor`

```text
vendor_id -> vendor_name, vendor_code, country, tax_id, vendor_address, phone, email, contact_name, contact_position
vendor_code -> vendor_id
country, tax_id -> vendor_id
```


### `delivery`

```text
delivery_id -> delivery_code, vendor_id, delivery_date
delivery_code -> delivery_id
```

### `delivery_document`

```text
delivery_document_id -> delivery_id, document_type, document_number
delivery_id, document_type, document_number -> delivery_document_id
```

### `component`

```text
component_id -> component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no
component_no -> component_id
```

### `component_insulation`

```text
component_id -> insulation_material_id, insulation_thickness_mm, cladding_material_id, cladding_thickness_mm
```

### `weld_joint`

```text
weld_joint_id -> weld_joint_no, first_component_id, second_component_id, weld_type, welding_process, weld_date, status
weld_joint_no -> weld_joint_id
```

### `weld_assignment`

```text
F = {}
```

### `flange_connection`

```text
flange_connection_id -> flange_connection_no, first_component_id, second_component_id, gasket_type, bolt_specification, assembly_date, status
flange_connection_no -> flange_connection_id
```

### `equipment`

```text
equipment_id -> equipment_code, equipment_type, equipment_name, area_id, vendor_id, manufacturing_status
equipment_code -> equipment_id
```

### `inspection`

```text
inspection_id -> weld_joint_id, inspection_type, inspection_date, result, report_no, defect_description
```

### `repair`

```text
repair_id -> weld_joint_id, inspection_id, repair_date, repair_reason, repair_description, status
```

На записях с `inspection_id IS NOT NULL` выполняется `inspection_id -> weld_joint_id`. При `inspection_id IS NULL` ремонты могут относиться к разным соединениям, поэтому эта ФЗ не включена в безусловное `F`.

### `test_package`

```text
test_package_id -> test_package_code, test_type, test_date, status
test_package_code -> test_package_id
```

### `test_package_spool`

```text
F = {}
```

### `test_package_flange_connection`

```text
F = {}
```

### `test_package_equipment`

```text
F = {}
```

## 3. Все ключи отношений

Для каждого отношения рассмотрены все подмножества атрибутов. Кандидатный ключ `K` удовлетворяет `K+ = R`, а ни одно собственное подмножество `K` не определяет `R`. Ниже приведены все найденные ключи, шаги их замыканий и проверки удаления каждого атрибута.

Уникальные наборы `(isometric_id, pipeline_id)` в `isometric_drawing`, `(isometric_revision_id, isometric_id)` в `isometric_revision` и `(inspection_id, weld_joint_id)` в `inspection` являются надключами; они содержат первичный ключ и не являются минимальными.

### `area`

```text
K = {area_id}
K+ = {area_id}
area_id -> area_code, area_name, area_type
K+ = {area_id, area_code, area_name, area_type}
K+ = R(area)
{}+ = {} != R(area)

K = {area_code}
K+ = {area_code}
area_code -> area_id
K+ = {area_id, area_code}
area_id -> area_name, area_type
K+ = {area_id, area_code, area_name, area_type}
K+ = R(area)
{}+ = {} != R(area)

K содержит {area_id} или K содержит {area_code}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{area_id}`;
- `{area_code}`.


### `pipeline`

```text
K = {pipeline_id}
K+ = {pipeline_id}
pipeline_id -> pipeline_code, service, pressure_category, temperature_category
K+ = {pipeline_id, pipeline_code, service, pressure_category, temperature_category}
K+ = R(pipeline)
{}+ = {} != R(pipeline)

K = {pipeline_code}
K+ = {pipeline_code}
pipeline_code -> pipeline_id
K+ = {pipeline_id, pipeline_code}
pipeline_id -> service, pressure_category, temperature_category
K+ = {pipeline_id, pipeline_code, service, pressure_category, temperature_category}
K+ = R(pipeline)
{}+ = {} != R(pipeline)

K содержит {pipeline_id} или K содержит {pipeline_code}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{pipeline_id}`;
- `{pipeline_code}`.


### `pipeline_area`

```text
K = {pipeline_id, area_id}
K+ = {pipeline_id, area_id}
pipeline_id, area_id -> heat_tracing, min_insulation_thickness_mm, passive_fire_protection
K+ = {pipeline_id, area_id, heat_tracing, min_insulation_thickness_mm, passive_fire_protection}
K+ = R(pipeline_area)
{area_id}+ = {area_id} != R(pipeline_area)
{pipeline_id}+ = {pipeline_id} != R(pipeline_area)

K содержит {pipeline_id, area_id}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{pipeline_id, area_id}`.


### `isometric_drawing`

```text
K = {isometric_id}
K+ = {isometric_id}
isometric_id -> isometric_number, pipeline_id
K+ = {isometric_id, isometric_number, pipeline_id}
K+ = R(isometric_drawing)
{}+ = {} != R(isometric_drawing)

K = {isometric_number}
K+ = {isometric_number}
isometric_number -> isometric_id
K+ = {isometric_id, isometric_number}
isometric_id -> pipeline_id
K+ = {isometric_id, isometric_number, pipeline_id}
K+ = R(isometric_drawing)
{}+ = {} != R(isometric_drawing)

K содержит {isometric_id} или K содержит {isometric_number}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{isometric_id}`;
- `{isometric_number}`.


### `isometric_revision`

```text
K = {isometric_revision_id}
K+ = {isometric_revision_id}
isometric_revision_id -> isometric_id, revision, issue_date
K+ = {isometric_revision_id, isometric_id, revision, issue_date}
K+ = R(isometric_revision)
{}+ = {} != R(isometric_revision)

K = {isometric_id, revision}
K+ = {isometric_id, revision}
isometric_id, revision -> isometric_revision_id
K+ = {isometric_revision_id, isometric_id, revision}
isometric_revision_id -> issue_date
K+ = {isometric_revision_id, isometric_id, revision, issue_date}
K+ = R(isometric_revision)
{revision}+ = {revision} != R(isometric_revision)
{isometric_id}+ = {isometric_id} != R(isometric_revision)

K содержит {isometric_revision_id} или K содержит {isometric_id, revision}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{isometric_revision_id}`;
- `{isometric_id, revision}`.


### `spool`

```text
K = {spool_id}
K+ = {spool_id}
spool_id -> spool_code, isometric_revision_id, isometric_id, pipeline_id, area_id, weight_ton, fabrication_status
K+ = {spool_id, spool_code, isometric_revision_id, isometric_id, pipeline_id, area_id, weight_ton, fabrication_status}
K+ = R(spool)
{}+ = {} != R(spool)

K = {spool_code}
K+ = {spool_code}
spool_code -> spool_id
K+ = {spool_id, spool_code}
spool_id -> isometric_revision_id, isometric_id, pipeline_id, area_id, weight_ton, fabrication_status
K+ = {spool_id, spool_code, isometric_revision_id, isometric_id, pipeline_id, area_id, weight_ton, fabrication_status}
K+ = R(spool)
{}+ = {} != R(spool)

K содержит {spool_id} или K содержит {spool_code}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{spool_id}`;
- `{spool_code}`.


### `welder`

```text
K = {welder_id}
K+ = {welder_id}
welder_id -> welder_employer_no, welder_name, welder_license_no, welder_last_attestation_date
K+ = {welder_id, welder_employer_no, welder_name, welder_license_no, welder_last_attestation_date}
K+ = R(welder)
{}+ = {} != R(welder)

K = {welder_employer_no}
K+ = {welder_employer_no}
welder_employer_no -> welder_id
K+ = {welder_id, welder_employer_no}
welder_id -> welder_name, welder_license_no, welder_last_attestation_date
K+ = {welder_id, welder_employer_no, welder_name, welder_license_no, welder_last_attestation_date}
K+ = R(welder)
{}+ = {} != R(welder)

K содержит {welder_id} или K содержит {welder_employer_no}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{welder_id}`;
- `{welder_employer_no}`.


### `welder_certificate`

```text
K = {certificate_id}
K+ = {certificate_id}
certificate_id -> welder_id, certificate_number, standard, valid_until
K+ = {certificate_id, welder_id, certificate_number, standard, valid_until}
K+ = R(welder_certificate)
{}+ = {} != R(welder_certificate)

K содержит {certificate_id}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{certificate_id}`.


### `component_type`

```text
K = {component_type_id}
K+ = {component_type_id}
component_type_id -> type_code, type_name
K+ = {component_type_id, type_code, type_name}
K+ = R(component_type)
{}+ = {} != R(component_type)

K = {type_code}
K+ = {type_code}
type_code -> component_type_id
K+ = {component_type_id, type_code}
component_type_id -> type_name
K+ = {component_type_id, type_code, type_name}
K+ = R(component_type)
{}+ = {} != R(component_type)

K содержит {component_type_id} или K содержит {type_code}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{component_type_id}`;
- `{type_code}`.


### `material`

```text
K = {material_id}
K+ = {material_id}
material_id -> material_code, material_name, material_standard
K+ = {material_id, material_code, material_name, material_standard}
K+ = R(material)
{}+ = {} != R(material)

K = {material_code}
K+ = {material_code}
material_code -> material_id
K+ = {material_id, material_code}
material_id -> material_name, material_standard
K+ = {material_id, material_code, material_name, material_standard}
K+ = R(material)
{}+ = {} != R(material)

K содержит {material_id} или K содержит {material_code}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{material_id}`;
- `{material_code}`.


### `insulation_material`

```text
K = {insulation_material_id}
K+ = {insulation_material_id}
insulation_material_id -> material_code, material_name
K+ = {insulation_material_id, material_code, material_name}
K+ = R(insulation_material)
{}+ = {} != R(insulation_material)

K = {material_code}
K+ = {material_code}
material_code -> insulation_material_id
K+ = {insulation_material_id, material_code}
insulation_material_id -> material_name
K+ = {insulation_material_id, material_code, material_name}
K+ = R(insulation_material)
{}+ = {} != R(insulation_material)

K содержит {insulation_material_id} или K содержит {material_code}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{insulation_material_id}`;
- `{material_code}`.


### `cladding_material`

```text
K = {cladding_material_id}
K+ = {cladding_material_id}
cladding_material_id -> material_code, material_name, coating
K+ = {cladding_material_id, material_code, material_name, coating}
K+ = R(cladding_material)
{}+ = {} != R(cladding_material)

K = {material_code}
K+ = {material_code}
material_code -> cladding_material_id
K+ = {cladding_material_id, material_code}
cladding_material_id -> material_name, coating
K+ = {cladding_material_id, material_code, material_name, coating}
K+ = R(cladding_material)
{}+ = {} != R(cladding_material)

K содержит {cladding_material_id} или K содержит {material_code}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{cladding_material_id}`;
- `{material_code}`.


### `vendor`

```text
K = {vendor_id}
K+ = {vendor_id}
vendor_id -> vendor_name, vendor_code, country, tax_id, vendor_address, phone, email, contact_name, contact_position
K+ = {vendor_id, vendor_name, vendor_code, country, tax_id, vendor_address, phone, email, contact_name, contact_position}
K+ = R(vendor)
{}+ = {} != R(vendor)

K = {vendor_code}
K+ = {vendor_code}
vendor_code -> vendor_id
K+ = {vendor_id, vendor_code}
vendor_id -> vendor_name, country, tax_id, vendor_address, phone, email, contact_name, contact_position
K+ = {vendor_id, vendor_name, vendor_code, country, tax_id, vendor_address, phone, email, contact_name, contact_position}
K+ = R(vendor)
{}+ = {} != R(vendor)

K = {country, tax_id}
K+ = {country, tax_id}
country, tax_id -> vendor_id
K+ = {vendor_id, country, tax_id}
vendor_id -> vendor_name, vendor_code, vendor_address, phone, email, contact_name, contact_position
K+ = {vendor_id, vendor_name, vendor_code, country, tax_id, vendor_address, phone, email, contact_name, contact_position}
K+ = R(vendor)
{tax_id}+ = {tax_id} != R(vendor)
{country}+ = {country} != R(vendor)

K содержит {vendor_id}, или K содержит {vendor_code}, или K содержит {country, tax_id}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{vendor_id}`;
- `{vendor_code}`;
- `{country, tax_id}`.


### `delivery`

```text
K = {delivery_id}
K+ = {delivery_id}
delivery_id -> delivery_code, vendor_id, delivery_date
K+ = {delivery_id, delivery_code, vendor_id, delivery_date}
K+ = R(delivery)
{}+ = {} != R(delivery)

K = {delivery_code}
K+ = {delivery_code}
delivery_code -> delivery_id
K+ = {delivery_id, delivery_code}
delivery_id -> vendor_id, delivery_date
K+ = {delivery_id, delivery_code, vendor_id, delivery_date}
K+ = R(delivery)
{}+ = {} != R(delivery)

K содержит {delivery_id} или K содержит {delivery_code}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{delivery_id}`;
- `{delivery_code}`.


### `delivery_document`

```text
K = {delivery_document_id}
K+ = {delivery_document_id}
delivery_document_id -> delivery_id, document_type, document_number
K+ = {delivery_document_id, delivery_id, document_type, document_number}
K+ = R(delivery_document)
{}+ = {} != R(delivery_document)

K = {delivery_id, document_type, document_number}
K+ = {delivery_id, document_type, document_number}
delivery_id, document_type, document_number -> delivery_document_id
K+ = {delivery_document_id, delivery_id, document_type, document_number}
K+ = R(delivery_document)
{document_type, document_number}+ = {document_type, document_number} != R(delivery_document)
{delivery_id, document_number}+ = {delivery_id, document_number} != R(delivery_document)
{delivery_id, document_type}+ = {delivery_id, document_type} != R(delivery_document)

K содержит {delivery_document_id} или K содержит {delivery_id, document_type, document_number}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{delivery_document_id}`;
- `{delivery_id, document_type, document_number}`.


### `component`

```text
K = {component_id}
K+ = {component_id}
component_id -> component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no
K+ = {component_id, component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no}
K+ = R(component)
{}+ = {} != R(component)

K = {component_no}
K+ = {component_no}
component_no -> component_id
K+ = {component_id, component_no}
component_id -> component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no
K+ = {component_id, component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no}
K+ = R(component)
{}+ = {} != R(component)

K содержит {component_id} или K содержит {component_no}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{component_id}`;
- `{component_no}`.


### `component_insulation`

```text
K = {component_id}
K+ = {component_id}
component_id -> insulation_material_id, insulation_thickness_mm, cladding_material_id, cladding_thickness_mm
K+ = {component_id, insulation_material_id, insulation_thickness_mm, cladding_material_id, cladding_thickness_mm}
K+ = R(component_insulation)
{}+ = {} != R(component_insulation)

K содержит {component_id}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{component_id}`.


### `weld_joint`

```text
K = {weld_joint_id}
K+ = {weld_joint_id}
weld_joint_id -> weld_joint_no, first_component_id, second_component_id, weld_type, welding_process, weld_date, status
K+ = {weld_joint_id, weld_joint_no, first_component_id, second_component_id, weld_type, welding_process, weld_date, status}
K+ = R(weld_joint)
{}+ = {} != R(weld_joint)

K = {weld_joint_no}
K+ = {weld_joint_no}
weld_joint_no -> weld_joint_id
K+ = {weld_joint_id, weld_joint_no}
weld_joint_id -> first_component_id, second_component_id, weld_type, welding_process, weld_date, status
K+ = {weld_joint_id, weld_joint_no, first_component_id, second_component_id, weld_type, welding_process, weld_date, status}
K+ = R(weld_joint)
{}+ = {} != R(weld_joint)

K содержит {weld_joint_id} или K содержит {weld_joint_no}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{weld_joint_id}`;
- `{weld_joint_no}`.


### `weld_assignment`

```text
K = {weld_joint_id, welder_id}
K+ = {weld_joint_id, welder_id}
K+ = R(weld_assignment)
{welder_id}+ = {welder_id} != R(weld_assignment)
{weld_joint_id}+ = {weld_joint_id} != R(weld_assignment)

K содержит {weld_joint_id, welder_id}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{weld_joint_id, welder_id}`.


### `flange_connection`

```text
K = {flange_connection_id}
K+ = {flange_connection_id}
flange_connection_id -> flange_connection_no, first_component_id, second_component_id, gasket_type, bolt_specification, assembly_date, status
K+ = {flange_connection_id, flange_connection_no, first_component_id, second_component_id, gasket_type, bolt_specification, assembly_date, status}
K+ = R(flange_connection)
{}+ = {} != R(flange_connection)

K = {flange_connection_no}
K+ = {flange_connection_no}
flange_connection_no -> flange_connection_id
K+ = {flange_connection_id, flange_connection_no}
flange_connection_id -> first_component_id, second_component_id, gasket_type, bolt_specification, assembly_date, status
K+ = {flange_connection_id, flange_connection_no, first_component_id, second_component_id, gasket_type, bolt_specification, assembly_date, status}
K+ = R(flange_connection)
{}+ = {} != R(flange_connection)

K содержит {flange_connection_id} или K содержит {flange_connection_no}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{flange_connection_id}`;
- `{flange_connection_no}`.


### `equipment`

```text
K = {equipment_id}
K+ = {equipment_id}
equipment_id -> equipment_code, equipment_type, equipment_name, area_id, vendor_id, manufacturing_status
K+ = {equipment_id, equipment_code, equipment_type, equipment_name, area_id, vendor_id, manufacturing_status}
K+ = R(equipment)
{}+ = {} != R(equipment)

K = {equipment_code}
K+ = {equipment_code}
equipment_code -> equipment_id
K+ = {equipment_id, equipment_code}
equipment_id -> equipment_type, equipment_name, area_id, vendor_id, manufacturing_status
K+ = {equipment_id, equipment_code, equipment_type, equipment_name, area_id, vendor_id, manufacturing_status}
K+ = R(equipment)
{}+ = {} != R(equipment)

K содержит {equipment_id} или K содержит {equipment_code}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{equipment_id}`;
- `{equipment_code}`.


### `inspection`

```text
K = {inspection_id}
K+ = {inspection_id}
inspection_id -> weld_joint_id, inspection_type, inspection_date, result, report_no, defect_description
K+ = {inspection_id, weld_joint_id, inspection_type, inspection_date, result, report_no, defect_description}
K+ = R(inspection)
{}+ = {} != R(inspection)

K содержит {inspection_id}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{inspection_id}`.


### `repair`

```text
K = {repair_id}
K+ = {repair_id}
repair_id -> weld_joint_id, inspection_id, repair_date, repair_reason, repair_description, status
K+ = {repair_id, weld_joint_id, inspection_id, repair_date, repair_reason, repair_description, status}
K+ = R(repair)
{}+ = {} != R(repair)

K содержит {repair_id}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{repair_id}`.


### `test_package`

```text
K = {test_package_id}
K+ = {test_package_id}
test_package_id -> test_package_code, test_type, test_date, status
K+ = {test_package_id, test_package_code, test_type, test_date, status}
K+ = R(test_package)
{}+ = {} != R(test_package)

K = {test_package_code}
K+ = {test_package_code}
test_package_code -> test_package_id
K+ = {test_package_id, test_package_code}
test_package_id -> test_type, test_date, status
K+ = {test_package_id, test_package_code, test_type, test_date, status}
K+ = R(test_package)
{}+ = {} != R(test_package)

K содержит {test_package_id} или K содержит {test_package_code}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{test_package_id}`;
- `{test_package_code}`.


### `test_package_spool`

```text
K = {test_package_id, spool_id}
K+ = {test_package_id, spool_id}
K+ = R(test_package_spool)
{spool_id}+ = {spool_id} != R(test_package_spool)
{test_package_id}+ = {test_package_id} != R(test_package_spool)

K содержит {test_package_id, spool_id}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{test_package_id, spool_id}`.


### `test_package_flange_connection`

```text
K = {test_package_id, flange_connection_id}
K+ = {test_package_id, flange_connection_id}
K+ = R(test_package_flange_connection)
{flange_connection_id}+ = {flange_connection_id} != R(test_package_flange_connection)
{test_package_id}+ = {test_package_id} != R(test_package_flange_connection)

K содержит {test_package_id, flange_connection_id}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{test_package_id, flange_connection_id}`.


### `test_package_equipment`

```text
K = {test_package_id, equipment_id}
K+ = {test_package_id, equipment_id}
K+ = R(test_package_equipment)
{equipment_id}+ = {equipment_id} != R(test_package_equipment)
{test_package_id}+ = {test_package_id} != R(test_package_equipment)

K содержит {test_package_id, equipment_id}
Иных кандидатных ключей нет.
```

Кандидатные ключи:

- `{test_package_id, equipment_id}`.

## 4. Неприводимые множества функциональных зависимостей

Правые части `F` расщеплены на одиночные атрибуты. В таблицах проверок используется итоговое `G`. Для каждой ФЗ `X -> a` проверены удаления атрибутов слева и замыкание `X` по `G` без этой ФЗ. Правило необходимо, если `a` не входит в полученное замыкание.

### `area`

**Расщепление правых частей**

```text
area_id -> area_code
area_id -> area_name
area_id -> area_type
area_code -> area_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
area_code, area_name, area_type not in {}+
area_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `area_id -> area_code` | `{area_id}+ = {area_id, area_name, area_type}` |
| `area_id -> area_name` | `{area_id}+ = {area_id, area_code, area_type}` |
| `area_id -> area_type` | `{area_id}+ = {area_id, area_code, area_name}` |
| `area_code -> area_id` | `{area_code}+ = {area_code}` |

**Неприводимое множество**

```text
area_id -> area_code
area_id -> area_name
area_id -> area_type
area_code -> area_id
```

### `pipeline`

**Расщепление правых частей**

```text
pipeline_id -> pipeline_code
pipeline_id -> service
pipeline_id -> pressure_category
pipeline_id -> temperature_category
pipeline_code -> pipeline_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
pipeline_code, service, pressure_category, temperature_category not in {}+
pipeline_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `pipeline_id -> pipeline_code` | `{pipeline_id}+ = {pipeline_id, service, pressure_category, temperature_category}` |
| `pipeline_id -> service` | `{pipeline_id}+ = {pipeline_id, pipeline_code, pressure_category, temperature_category}` |
| `pipeline_id -> pressure_category` | `{pipeline_id}+ = {pipeline_id, pipeline_code, service, temperature_category}` |
| `pipeline_id -> temperature_category` | `{pipeline_id}+ = {pipeline_id, pipeline_code, service, pressure_category}` |
| `pipeline_code -> pipeline_id` | `{pipeline_code}+ = {pipeline_code}` |

**Неприводимое множество**

```text
pipeline_id -> pipeline_code
pipeline_id -> service
pipeline_id -> pressure_category
pipeline_id -> temperature_category
pipeline_code -> pipeline_id
```

### `pipeline_area`

**Расщепление правых частей**

```text
pipeline_id, area_id -> heat_tracing
pipeline_id, area_id -> min_insulation_thickness_mm
pipeline_id, area_id -> passive_fire_protection
```

**Удаление атрибутов из левых частей**

| ФЗ | Удалённый атрибут | Замыкание оставшейся части | Проверка |
| --- | --- | --- | --- |
| `pipeline_id, area_id -> heat_tracing` | `pipeline_id` | `{area_id}+ = {area_id}` | `heat_tracing not in X+` |
| `pipeline_id, area_id -> heat_tracing` | `area_id` | `{pipeline_id}+ = {pipeline_id}` | `heat_tracing not in X+` |
| `pipeline_id, area_id -> min_insulation_thickness_mm` | `pipeline_id` | `{area_id}+ = {area_id}` | `min_insulation_thickness_mm not in X+` |
| `pipeline_id, area_id -> min_insulation_thickness_mm` | `area_id` | `{pipeline_id}+ = {pipeline_id}` | `min_insulation_thickness_mm not in X+` |
| `pipeline_id, area_id -> passive_fire_protection` | `pipeline_id` | `{area_id}+ = {area_id}` | `passive_fire_protection not in X+` |
| `pipeline_id, area_id -> passive_fire_protection` | `area_id` | `{pipeline_id}+ = {pipeline_id}` | `passive_fire_protection not in X+` |

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `pipeline_id, area_id -> heat_tracing` | `{pipeline_id, area_id}+ = {pipeline_id, area_id, min_insulation_thickness_mm, passive_fire_protection}` |
| `pipeline_id, area_id -> min_insulation_thickness_mm` | `{pipeline_id, area_id}+ = {pipeline_id, area_id, heat_tracing, passive_fire_protection}` |
| `pipeline_id, area_id -> passive_fire_protection` | `{pipeline_id, area_id}+ = {pipeline_id, area_id, heat_tracing, min_insulation_thickness_mm}` |

**Неприводимое множество**

```text
pipeline_id, area_id -> heat_tracing
pipeline_id, area_id -> min_insulation_thickness_mm
pipeline_id, area_id -> passive_fire_protection
```

### `isometric_drawing`

**Расщепление правых частей**

```text
isometric_id -> isometric_number
isometric_id -> pipeline_id
isometric_number -> isometric_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
isometric_number, pipeline_id not in {}+
isometric_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `isometric_id -> isometric_number` | `{isometric_id}+ = {isometric_id, pipeline_id}` |
| `isometric_id -> pipeline_id` | `{isometric_id}+ = {isometric_id, isometric_number}` |
| `isometric_number -> isometric_id` | `{isometric_number}+ = {isometric_number}` |

**Неприводимое множество**

```text
isometric_id -> isometric_number
isometric_id -> pipeline_id
isometric_number -> isometric_id
```

### `isometric_revision`

**Расщепление правых частей**

```text
isometric_revision_id -> isometric_id
isometric_revision_id -> revision
isometric_revision_id -> issue_date
isometric_id, revision -> isometric_revision_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
isometric_id, revision, issue_date not in {}+
```

| ФЗ | Удалённый атрибут | Замыкание оставшейся части | Проверка |
| --- | --- | --- | --- |
| `isometric_id, revision -> isometric_revision_id` | `isometric_id` | `{revision}+ = {revision}` | `isometric_revision_id not in X+` |
| `isometric_id, revision -> isometric_revision_id` | `revision` | `{isometric_id}+ = {isometric_id}` | `isometric_revision_id not in X+` |

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `isometric_revision_id -> isometric_id` | `{isometric_revision_id}+ = {isometric_revision_id, revision, issue_date}` |
| `isometric_revision_id -> revision` | `{isometric_revision_id}+ = {isometric_revision_id, isometric_id, issue_date}` |
| `isometric_revision_id -> issue_date` | `{isometric_revision_id}+ = {isometric_revision_id, isometric_id, revision}` |
| `isometric_id, revision -> isometric_revision_id` | `{isometric_id, revision}+ = {isometric_id, revision}` |

**Неприводимое множество**

```text
isometric_revision_id -> isometric_id
isometric_revision_id -> revision
isometric_revision_id -> issue_date
isometric_id, revision -> isometric_revision_id
```

### `spool`

**Расщепление правых частей**

```text
spool_id -> spool_code
spool_id -> isometric_revision_id
spool_id -> isometric_id
spool_id -> pipeline_id
spool_id -> area_id
spool_id -> weight_ton
spool_id -> fabrication_status
spool_code -> spool_id
isometric_revision_id -> isometric_id
isometric_id -> pipeline_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
spool_code, isometric_revision_id, area_id, weight_ton, fabrication_status not in {}+
spool_id not in {}+
isometric_id not in {}+
pipeline_id not in {}+
```

**Удаление избыточных ФЗ**

| Удаляемая ФЗ | Замыкание по остальным ФЗ |
| --- | --- |
| `spool_id -> isometric_id` | `{spool_id}+ = {spool_id, spool_code, isometric_revision_id, isometric_id, pipeline_id, area_id, weight_ton, fabrication_status}` |
| `spool_id -> pipeline_id` | `{spool_id}+ = {spool_id, spool_code, isometric_revision_id, isometric_id, pipeline_id, area_id, weight_ton, fabrication_status}` |

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `spool_id -> spool_code` | `{spool_id}+ = {spool_id, isometric_revision_id, isometric_id, pipeline_id, area_id, weight_ton, fabrication_status}` |
| `spool_id -> isometric_revision_id` | `{spool_id}+ = {spool_id, spool_code, area_id, weight_ton, fabrication_status}` |
| `spool_id -> area_id` | `{spool_id}+ = {spool_id, spool_code, isometric_revision_id, isometric_id, pipeline_id, weight_ton, fabrication_status}` |
| `spool_id -> weight_ton` | `{spool_id}+ = {spool_id, spool_code, isometric_revision_id, isometric_id, pipeline_id, area_id, fabrication_status}` |
| `spool_id -> fabrication_status` | `{spool_id}+ = {spool_id, spool_code, isometric_revision_id, isometric_id, pipeline_id, area_id, weight_ton}` |
| `spool_code -> spool_id` | `{spool_code}+ = {spool_code}` |
| `isometric_revision_id -> isometric_id` | `{isometric_revision_id}+ = {isometric_revision_id}` |
| `isometric_id -> pipeline_id` | `{isometric_id}+ = {isometric_id}` |

**Неприводимое множество**

```text
spool_id -> spool_code
spool_id -> isometric_revision_id
spool_id -> area_id
spool_id -> weight_ton
spool_id -> fabrication_status
spool_code -> spool_id
isometric_revision_id -> isometric_id
isometric_id -> pipeline_id
```

### `welder`

**Расщепление правых частей**

```text
welder_id -> welder_employer_no
welder_id -> welder_name
welder_id -> welder_license_no
welder_id -> welder_last_attestation_date
welder_employer_no -> welder_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
welder_employer_no, welder_name, welder_license_no, welder_last_attestation_date not in {}+
welder_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `welder_id -> welder_employer_no` | `{welder_id}+ = {welder_id, welder_name, welder_license_no, welder_last_attestation_date}` |
| `welder_id -> welder_name` | `{welder_id}+ = {welder_id, welder_employer_no, welder_license_no, welder_last_attestation_date}` |
| `welder_id -> welder_license_no` | `{welder_id}+ = {welder_id, welder_employer_no, welder_name, welder_last_attestation_date}` |
| `welder_id -> welder_last_attestation_date` | `{welder_id}+ = {welder_id, welder_employer_no, welder_name, welder_license_no}` |
| `welder_employer_no -> welder_id` | `{welder_employer_no}+ = {welder_employer_no}` |

**Неприводимое множество**

```text
welder_id -> welder_employer_no
welder_id -> welder_name
welder_id -> welder_license_no
welder_id -> welder_last_attestation_date
welder_employer_no -> welder_id
```

### `welder_certificate`

**Расщепление правых частей**

```text
certificate_id -> welder_id
certificate_id -> certificate_number
certificate_id -> standard
certificate_id -> valid_until
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
welder_id, certificate_number, standard, valid_until not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `certificate_id -> welder_id` | `{certificate_id}+ = {certificate_id, certificate_number, standard, valid_until}` |
| `certificate_id -> certificate_number` | `{certificate_id}+ = {certificate_id, welder_id, standard, valid_until}` |
| `certificate_id -> standard` | `{certificate_id}+ = {certificate_id, welder_id, certificate_number, valid_until}` |
| `certificate_id -> valid_until` | `{certificate_id}+ = {certificate_id, welder_id, certificate_number, standard}` |

**Неприводимое множество**

```text
certificate_id -> welder_id
certificate_id -> certificate_number
certificate_id -> standard
certificate_id -> valid_until
```

### `component_type`

**Расщепление правых частей**

```text
component_type_id -> type_code
component_type_id -> type_name
type_code -> component_type_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
type_code, type_name not in {}+
component_type_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `component_type_id -> type_code` | `{component_type_id}+ = {component_type_id, type_name}` |
| `component_type_id -> type_name` | `{component_type_id}+ = {component_type_id, type_code}` |
| `type_code -> component_type_id` | `{type_code}+ = {type_code}` |

**Неприводимое множество**

```text
component_type_id -> type_code
component_type_id -> type_name
type_code -> component_type_id
```

### `material`

**Расщепление правых частей**

```text
material_id -> material_code
material_id -> material_name
material_id -> material_standard
material_code -> material_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
material_code, material_name, material_standard not in {}+
material_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `material_id -> material_code` | `{material_id}+ = {material_id, material_name, material_standard}` |
| `material_id -> material_name` | `{material_id}+ = {material_id, material_code, material_standard}` |
| `material_id -> material_standard` | `{material_id}+ = {material_id, material_code, material_name}` |
| `material_code -> material_id` | `{material_code}+ = {material_code}` |

**Неприводимое множество**

```text
material_id -> material_code
material_id -> material_name
material_id -> material_standard
material_code -> material_id
```

### `insulation_material`

**Расщепление правых частей**

```text
insulation_material_id -> material_code
insulation_material_id -> material_name
material_code -> insulation_material_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
material_code, material_name not in {}+
insulation_material_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `insulation_material_id -> material_code` | `{insulation_material_id}+ = {insulation_material_id, material_name}` |
| `insulation_material_id -> material_name` | `{insulation_material_id}+ = {insulation_material_id, material_code}` |
| `material_code -> insulation_material_id` | `{material_code}+ = {material_code}` |

**Неприводимое множество**

```text
insulation_material_id -> material_code
insulation_material_id -> material_name
material_code -> insulation_material_id
```

### `cladding_material`

**Расщепление правых частей**

```text
cladding_material_id -> material_code
cladding_material_id -> material_name
cladding_material_id -> coating
material_code -> cladding_material_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
material_code, material_name, coating not in {}+
cladding_material_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `cladding_material_id -> material_code` | `{cladding_material_id}+ = {cladding_material_id, material_name, coating}` |
| `cladding_material_id -> material_name` | `{cladding_material_id}+ = {cladding_material_id, material_code, coating}` |
| `cladding_material_id -> coating` | `{cladding_material_id}+ = {cladding_material_id, material_code, material_name}` |
| `material_code -> cladding_material_id` | `{material_code}+ = {material_code}` |

**Неприводимое множество**

```text
cladding_material_id -> material_code
cladding_material_id -> material_name
cladding_material_id -> coating
material_code -> cladding_material_id
```

### `vendor`

**Расщепление правых частей**

```text
vendor_id -> vendor_name
vendor_id -> vendor_code
vendor_id -> country
vendor_id -> tax_id
vendor_id -> vendor_address
vendor_id -> phone
vendor_id -> email
vendor_id -> contact_name
vendor_id -> contact_position
vendor_code -> vendor_id
country, tax_id -> vendor_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
vendor_name, vendor_code, country, tax_id, vendor_address, phone, email, contact_name, contact_position not in {}+
vendor_id not in {}+
```

| ФЗ | Удалённый атрибут | Замыкание оставшейся части | Проверка |
| --- | --- | --- | --- |
| `country, tax_id -> vendor_id` | `country` | `{tax_id}+ = {tax_id}` | `vendor_id not in X+` |
| `country, tax_id -> vendor_id` | `tax_id` | `{country}+ = {country}` | `vendor_id not in X+` |

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `vendor_id -> vendor_name` | `{vendor_id}+ = {vendor_id, vendor_code, country, tax_id, vendor_address, phone, email, contact_name, contact_position}` |
| `vendor_id -> vendor_code` | `{vendor_id}+ = {vendor_id, vendor_name, country, tax_id, vendor_address, phone, email, contact_name, contact_position}` |
| `vendor_id -> country` | `{vendor_id}+ = {vendor_id, vendor_name, vendor_code, tax_id, vendor_address, phone, email, contact_name, contact_position}` |
| `vendor_id -> tax_id` | `{vendor_id}+ = {vendor_id, vendor_name, vendor_code, country, vendor_address, phone, email, contact_name, contact_position}` |
| `vendor_id -> vendor_address` | `{vendor_id}+ = {vendor_id, vendor_name, vendor_code, country, tax_id, phone, email, contact_name, contact_position}` |
| `vendor_id -> phone` | `{vendor_id}+ = {vendor_id, vendor_name, vendor_code, country, tax_id, vendor_address, email, contact_name, contact_position}` |
| `vendor_id -> email` | `{vendor_id}+ = {vendor_id, vendor_name, vendor_code, country, tax_id, vendor_address, phone, contact_name, contact_position}` |
| `vendor_id -> contact_name` | `{vendor_id}+ = {vendor_id, vendor_name, vendor_code, country, tax_id, vendor_address, phone, email, contact_position}` |
| `vendor_id -> contact_position` | `{vendor_id}+ = {vendor_id, vendor_name, vendor_code, country, tax_id, vendor_address, phone, email, contact_name}` |
| `vendor_code -> vendor_id` | `{vendor_code}+ = {vendor_code}` |
| `country, tax_id -> vendor_id` | `{country, tax_id}+ = {country, tax_id}` |

**Неприводимое множество**

```text
vendor_id -> vendor_name
vendor_id -> vendor_code
vendor_id -> country
vendor_id -> tax_id
vendor_id -> vendor_address
vendor_id -> phone
vendor_id -> email
vendor_id -> contact_name
vendor_id -> contact_position
vendor_code -> vendor_id
country, tax_id -> vendor_id
```


### `delivery`

**Расщепление правых частей**

```text
delivery_id -> delivery_code
delivery_id -> vendor_id
delivery_id -> delivery_date
delivery_code -> delivery_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
delivery_code, vendor_id, delivery_date not in {}+
delivery_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `delivery_id -> delivery_code` | `{delivery_id}+ = {delivery_id, vendor_id, delivery_date}` |
| `delivery_id -> vendor_id` | `{delivery_id}+ = {delivery_id, delivery_code, delivery_date}` |
| `delivery_id -> delivery_date` | `{delivery_id}+ = {delivery_id, delivery_code, vendor_id}` |
| `delivery_code -> delivery_id` | `{delivery_code}+ = {delivery_code}` |

**Неприводимое множество**

```text
delivery_id -> delivery_code
delivery_id -> vendor_id
delivery_id -> delivery_date
delivery_code -> delivery_id
```

### `delivery_document`

**Расщепление правых частей**

```text
delivery_document_id -> delivery_id
delivery_document_id -> document_type
delivery_document_id -> document_number
delivery_id, document_type, document_number -> delivery_document_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
delivery_id, document_type, document_number not in {}+
```

| ФЗ | Удалённый атрибут | Замыкание оставшейся части | Проверка |
| --- | --- | --- | --- |
| `delivery_id, document_type, document_number -> delivery_document_id` | `delivery_id` | `{document_type, document_number}+ = {document_type, document_number}` | `delivery_document_id not in X+` |
| `delivery_id, document_type, document_number -> delivery_document_id` | `document_type` | `{delivery_id, document_number}+ = {delivery_id, document_number}` | `delivery_document_id not in X+` |
| `delivery_id, document_type, document_number -> delivery_document_id` | `document_number` | `{delivery_id, document_type}+ = {delivery_id, document_type}` | `delivery_document_id not in X+` |

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `delivery_document_id -> delivery_id` | `{delivery_document_id}+ = {delivery_document_id, document_type, document_number}` |
| `delivery_document_id -> document_type` | `{delivery_document_id}+ = {delivery_document_id, delivery_id, document_number}` |
| `delivery_document_id -> document_number` | `{delivery_document_id}+ = {delivery_document_id, delivery_id, document_type}` |
| `delivery_id, document_type, document_number -> delivery_document_id` | `{delivery_id, document_type, document_number}+ = {delivery_id, document_type, document_number}` |

**Неприводимое множество**

```text
delivery_document_id -> delivery_id
delivery_document_id -> document_type
delivery_document_id -> document_number
delivery_id, document_type, document_number -> delivery_document_id
```

### `component`

**Расщепление правых частей**

```text
component_id -> component_no
component_id -> component_type_id
component_id -> spool_id
component_id -> material_id
component_id -> delivery_id
component_id -> nominal_diameter_inch
component_id -> wall_thickness_mm
component_id -> length_mm
component_id -> width_mm
component_id -> height_mm
component_id -> weight_ton
component_id -> certificate_no
component_no -> component_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no not in {}+
component_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `component_id -> component_no` | `{component_id}+ = {component_id, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no}` |
| `component_id -> component_type_id` | `{component_id}+ = {component_id, component_no, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no}` |
| `component_id -> spool_id` | `{component_id}+ = {component_id, component_no, component_type_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no}` |
| `component_id -> material_id` | `{component_id}+ = {component_id, component_no, component_type_id, spool_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no}` |
| `component_id -> delivery_id` | `{component_id}+ = {component_id, component_no, component_type_id, spool_id, material_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no}` |
| `component_id -> nominal_diameter_inch` | `{component_id}+ = {component_id, component_no, component_type_id, spool_id, material_id, delivery_id, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton, certificate_no}` |
| `component_id -> wall_thickness_mm` | `{component_id}+ = {component_id, component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, length_mm, width_mm, height_mm, weight_ton, certificate_no}` |
| `component_id -> length_mm` | `{component_id}+ = {component_id, component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, width_mm, height_mm, weight_ton, certificate_no}` |
| `component_id -> width_mm` | `{component_id}+ = {component_id, component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, height_mm, weight_ton, certificate_no}` |
| `component_id -> height_mm` | `{component_id}+ = {component_id, component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, weight_ton, certificate_no}` |
| `component_id -> weight_ton` | `{component_id}+ = {component_id, component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, certificate_no}` |
| `component_id -> certificate_no` | `{component_id}+ = {component_id, component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, width_mm, height_mm, weight_ton}` |
| `component_no -> component_id` | `{component_no}+ = {component_no}` |

**Неприводимое множество**

```text
component_id -> component_no
component_id -> component_type_id
component_id -> spool_id
component_id -> material_id
component_id -> delivery_id
component_id -> nominal_diameter_inch
component_id -> wall_thickness_mm
component_id -> length_mm
component_id -> width_mm
component_id -> height_mm
component_id -> weight_ton
component_id -> certificate_no
component_no -> component_id
```

### `component_insulation`

**Расщепление правых частей**

```text
component_id -> insulation_material_id
component_id -> insulation_thickness_mm
component_id -> cladding_material_id
component_id -> cladding_thickness_mm
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
insulation_material_id, insulation_thickness_mm, cladding_material_id, cladding_thickness_mm not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `component_id -> insulation_material_id` | `{component_id}+ = {component_id, insulation_thickness_mm, cladding_material_id, cladding_thickness_mm}` |
| `component_id -> insulation_thickness_mm` | `{component_id}+ = {component_id, insulation_material_id, cladding_material_id, cladding_thickness_mm}` |
| `component_id -> cladding_material_id` | `{component_id}+ = {component_id, insulation_material_id, insulation_thickness_mm, cladding_thickness_mm}` |
| `component_id -> cladding_thickness_mm` | `{component_id}+ = {component_id, insulation_material_id, insulation_thickness_mm, cladding_material_id}` |

**Неприводимое множество**

```text
component_id -> insulation_material_id
component_id -> insulation_thickness_mm
component_id -> cladding_material_id
component_id -> cladding_thickness_mm
```

### `weld_joint`

**Расщепление правых частей**

```text
weld_joint_id -> weld_joint_no
weld_joint_id -> first_component_id
weld_joint_id -> second_component_id
weld_joint_id -> weld_type
weld_joint_id -> welding_process
weld_joint_id -> weld_date
weld_joint_id -> status
weld_joint_no -> weld_joint_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
weld_joint_no, first_component_id, second_component_id, weld_type, welding_process, weld_date, status not in {}+
weld_joint_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `weld_joint_id -> weld_joint_no` | `{weld_joint_id}+ = {weld_joint_id, first_component_id, second_component_id, weld_type, welding_process, weld_date, status}` |
| `weld_joint_id -> first_component_id` | `{weld_joint_id}+ = {weld_joint_id, weld_joint_no, second_component_id, weld_type, welding_process, weld_date, status}` |
| `weld_joint_id -> second_component_id` | `{weld_joint_id}+ = {weld_joint_id, weld_joint_no, first_component_id, weld_type, welding_process, weld_date, status}` |
| `weld_joint_id -> weld_type` | `{weld_joint_id}+ = {weld_joint_id, weld_joint_no, first_component_id, second_component_id, welding_process, weld_date, status}` |
| `weld_joint_id -> welding_process` | `{weld_joint_id}+ = {weld_joint_id, weld_joint_no, first_component_id, second_component_id, weld_type, weld_date, status}` |
| `weld_joint_id -> weld_date` | `{weld_joint_id}+ = {weld_joint_id, weld_joint_no, first_component_id, second_component_id, weld_type, welding_process, status}` |
| `weld_joint_id -> status` | `{weld_joint_id}+ = {weld_joint_id, weld_joint_no, first_component_id, second_component_id, weld_type, welding_process, weld_date}` |
| `weld_joint_no -> weld_joint_id` | `{weld_joint_no}+ = {weld_joint_no}` |

**Неприводимое множество**

```text
weld_joint_id -> weld_joint_no
weld_joint_id -> first_component_id
weld_joint_id -> second_component_id
weld_joint_id -> weld_type
weld_joint_id -> welding_process
weld_joint_id -> weld_date
weld_joint_id -> status
weld_joint_no -> weld_joint_id
```

### `weld_assignment`

```text
F = G = {}
```

### `flange_connection`

**Расщепление правых частей**

```text
flange_connection_id -> flange_connection_no
flange_connection_id -> first_component_id
flange_connection_id -> second_component_id
flange_connection_id -> gasket_type
flange_connection_id -> bolt_specification
flange_connection_id -> assembly_date
flange_connection_id -> status
flange_connection_no -> flange_connection_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
flange_connection_no, first_component_id, second_component_id, gasket_type, bolt_specification, assembly_date, status not in {}+
flange_connection_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `flange_connection_id -> flange_connection_no` | `{flange_connection_id}+ = {flange_connection_id, first_component_id, second_component_id, gasket_type, bolt_specification, assembly_date, status}` |
| `flange_connection_id -> first_component_id` | `{flange_connection_id}+ = {flange_connection_id, flange_connection_no, second_component_id, gasket_type, bolt_specification, assembly_date, status}` |
| `flange_connection_id -> second_component_id` | `{flange_connection_id}+ = {flange_connection_id, flange_connection_no, first_component_id, gasket_type, bolt_specification, assembly_date, status}` |
| `flange_connection_id -> gasket_type` | `{flange_connection_id}+ = {flange_connection_id, flange_connection_no, first_component_id, second_component_id, bolt_specification, assembly_date, status}` |
| `flange_connection_id -> bolt_specification` | `{flange_connection_id}+ = {flange_connection_id, flange_connection_no, first_component_id, second_component_id, gasket_type, assembly_date, status}` |
| `flange_connection_id -> assembly_date` | `{flange_connection_id}+ = {flange_connection_id, flange_connection_no, first_component_id, second_component_id, gasket_type, bolt_specification, status}` |
| `flange_connection_id -> status` | `{flange_connection_id}+ = {flange_connection_id, flange_connection_no, first_component_id, second_component_id, gasket_type, bolt_specification, assembly_date}` |
| `flange_connection_no -> flange_connection_id` | `{flange_connection_no}+ = {flange_connection_no}` |

**Неприводимое множество**

```text
flange_connection_id -> flange_connection_no
flange_connection_id -> first_component_id
flange_connection_id -> second_component_id
flange_connection_id -> gasket_type
flange_connection_id -> bolt_specification
flange_connection_id -> assembly_date
flange_connection_id -> status
flange_connection_no -> flange_connection_id
```

### `equipment`

**Расщепление правых частей**

```text
equipment_id -> equipment_code
equipment_id -> equipment_type
equipment_id -> equipment_name
equipment_id -> area_id
equipment_id -> vendor_id
equipment_id -> manufacturing_status
equipment_code -> equipment_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
equipment_code, equipment_type, equipment_name, area_id, vendor_id, manufacturing_status not in {}+
equipment_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `equipment_id -> equipment_code` | `{equipment_id}+ = {equipment_id, equipment_type, equipment_name, area_id, vendor_id, manufacturing_status}` |
| `equipment_id -> equipment_type` | `{equipment_id}+ = {equipment_id, equipment_code, equipment_name, area_id, vendor_id, manufacturing_status}` |
| `equipment_id -> equipment_name` | `{equipment_id}+ = {equipment_id, equipment_code, equipment_type, area_id, vendor_id, manufacturing_status}` |
| `equipment_id -> area_id` | `{equipment_id}+ = {equipment_id, equipment_code, equipment_type, equipment_name, vendor_id, manufacturing_status}` |
| `equipment_id -> vendor_id` | `{equipment_id}+ = {equipment_id, equipment_code, equipment_type, equipment_name, area_id, manufacturing_status}` |
| `equipment_id -> manufacturing_status` | `{equipment_id}+ = {equipment_id, equipment_code, equipment_type, equipment_name, area_id, vendor_id}` |
| `equipment_code -> equipment_id` | `{equipment_code}+ = {equipment_code}` |

**Неприводимое множество**

```text
equipment_id -> equipment_code
equipment_id -> equipment_type
equipment_id -> equipment_name
equipment_id -> area_id
equipment_id -> vendor_id
equipment_id -> manufacturing_status
equipment_code -> equipment_id
```

### `inspection`

**Расщепление правых частей**

```text
inspection_id -> weld_joint_id
inspection_id -> inspection_type
inspection_id -> inspection_date
inspection_id -> result
inspection_id -> report_no
inspection_id -> defect_description
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
weld_joint_id, inspection_type, inspection_date, result, report_no, defect_description not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `inspection_id -> weld_joint_id` | `{inspection_id}+ = {inspection_id, inspection_type, inspection_date, result, report_no, defect_description}` |
| `inspection_id -> inspection_type` | `{inspection_id}+ = {inspection_id, weld_joint_id, inspection_date, result, report_no, defect_description}` |
| `inspection_id -> inspection_date` | `{inspection_id}+ = {inspection_id, weld_joint_id, inspection_type, result, report_no, defect_description}` |
| `inspection_id -> result` | `{inspection_id}+ = {inspection_id, weld_joint_id, inspection_type, inspection_date, report_no, defect_description}` |
| `inspection_id -> report_no` | `{inspection_id}+ = {inspection_id, weld_joint_id, inspection_type, inspection_date, result, defect_description}` |
| `inspection_id -> defect_description` | `{inspection_id}+ = {inspection_id, weld_joint_id, inspection_type, inspection_date, result, report_no}` |

**Неприводимое множество**

```text
inspection_id -> weld_joint_id
inspection_id -> inspection_type
inspection_id -> inspection_date
inspection_id -> result
inspection_id -> report_no
inspection_id -> defect_description
```

### `repair`

**Расщепление правых частей**

```text
repair_id -> weld_joint_id
repair_id -> inspection_id
repair_id -> repair_date
repair_id -> repair_reason
repair_id -> repair_description
repair_id -> status
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
weld_joint_id, inspection_id, repair_date, repair_reason, repair_description, status not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `repair_id -> weld_joint_id` | `{repair_id}+ = {repair_id, inspection_id, repair_date, repair_reason, repair_description, status}` |
| `repair_id -> inspection_id` | `{repair_id}+ = {repair_id, weld_joint_id, repair_date, repair_reason, repair_description, status}` |
| `repair_id -> repair_date` | `{repair_id}+ = {repair_id, weld_joint_id, inspection_id, repair_reason, repair_description, status}` |
| `repair_id -> repair_reason` | `{repair_id}+ = {repair_id, weld_joint_id, inspection_id, repair_date, repair_description, status}` |
| `repair_id -> repair_description` | `{repair_id}+ = {repair_id, weld_joint_id, inspection_id, repair_date, repair_reason, status}` |
| `repair_id -> status` | `{repair_id}+ = {repair_id, weld_joint_id, inspection_id, repair_date, repair_reason, repair_description}` |

**Неприводимое множество**

```text
repair_id -> weld_joint_id
repair_id -> inspection_id
repair_id -> repair_date
repair_id -> repair_reason
repair_id -> repair_description
repair_id -> status
```

### `test_package`

**Расщепление правых частей**

```text
test_package_id -> test_package_code
test_package_id -> test_type
test_package_id -> test_date
test_package_id -> status
test_package_code -> test_package_id
```

**Удаление атрибутов из левых частей**

```text
{}+ = {}
test_package_code, test_type, test_date, status not in {}+
test_package_id not in {}+
```

**Удаление избыточных ФЗ**

| Проверяемая ФЗ `f` | Замыкание левой части по `G` без `f` |
| --- | --- |
| `test_package_id -> test_package_code` | `{test_package_id}+ = {test_package_id, test_type, test_date, status}` |
| `test_package_id -> test_type` | `{test_package_id}+ = {test_package_id, test_package_code, test_date, status}` |
| `test_package_id -> test_date` | `{test_package_id}+ = {test_package_id, test_package_code, test_type, status}` |
| `test_package_id -> status` | `{test_package_id}+ = {test_package_id, test_package_code, test_type, test_date}` |
| `test_package_code -> test_package_id` | `{test_package_code}+ = {test_package_code}` |

**Неприводимое множество**

```text
test_package_id -> test_package_code
test_package_id -> test_type
test_package_id -> test_date
test_package_id -> status
test_package_code -> test_package_id
```

### `test_package_spool`

```text
F = G = {}
```

### `test_package_flange_connection`

```text
F = G = {}
```

### `test_package_equipment`

```text
F = G = {}
```
