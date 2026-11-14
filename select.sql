BEGIN;

-- Неагрегирующие запросы, Queries.md

-- 1.1. Ревизии чертежей после указанной даты

WITH parameters AS (
    SELECT DATE '2024-01-01' AS after_date
)
SELECT d.isometric_number, r.revision, r.issue_date, p.pipeline_code
FROM parameters AS v, isometric_revision AS r, isometric_drawing AS d, pipeline AS p
WHERE r.issue_date > v.after_date
  AND d.isometric_id = r.isometric_id
  AND p.pipeline_id = d.pipeline_id
ORDER BY r.issue_date, d.isometric_number, r.revision;

-- 1.2. Сварщики с действующим сертификатом указанного стандарта

WITH parameters AS (
    SELECT 'ISO 9606-1' AS certificate_standard,
           DATE '2026-01-01' AS as_of_date
)
SELECT w.welder_employer_no, w.welder_name,
       c.certificate_number, c.standard, c.valid_until
FROM parameters AS v, welder_certificate AS c, welder AS w
WHERE c.standard = v.certificate_standard AND c.valid_until >= v.as_of_date
  AND w.welder_id = c.welder_id
ORDER BY w.welder_employer_no, c.valid_until, c.certificate_id;

-- 1.3. Стажёры без сертификатов

SELECT w.welder_employer_no, w.welder_name, w.welder_license_no
FROM welder AS w
WHERE NOT EXISTS (
    SELECT 1 FROM welder_certificate AS c WHERE c.welder_id = w.welder_id
)
ORDER BY w.welder_employer_no;

-- 1.4. Соединения участка за период

WITH parameters AS (
    SELECT 'FG-001' AS pipeline_code, 'PRC-01' AS area_code,
           DATE '2026-01-01' AS date_from, DATE '2026-12-31' AS date_to
),
section_components AS (
    SELECT c.component_id
    FROM parameters AS v, component AS c, spool AS s, isometric_revision AS r,
         isometric_drawing AS d, pipeline AS p, area AS a
    WHERE p.pipeline_code = v.pipeline_code AND a.area_code = v.area_code
      AND d.pipeline_id = p.pipeline_id AND r.isometric_id = d.isometric_id
      AND s.isometric_revision_id = r.isometric_revision_id AND s.area_id = a.area_id
      AND c.spool_id = s.spool_id
),
connections AS (
    SELECT 'weld' AS connection_kind, w.weld_joint_no AS connection_no,
           w.first_component_id, w.second_component_id,
           w.weld_date AS execution_date, w.status
    FROM weld_joint AS w, parameters AS v
    WHERE w.weld_date BETWEEN v.date_from AND v.date_to
    UNION ALL
    SELECT 'flange', f.flange_connection_no, f.first_component_id,
           f.second_component_id, f.assembly_date, f.status
    FROM flange_connection AS f, parameters AS v
    WHERE f.assembly_date BETWEEN v.date_from AND v.date_to
)
SELECT v.pipeline_code, v.area_code, j.connection_kind, j.connection_no,
       j.execution_date, j.status,
       c1.component_no AS first_component_no, t1.type_name AS first_component_type,
       c1.nominal_diameter_inch AS first_diameter_inch,
       c2.component_no AS second_component_no, t2.type_name AS second_component_type,
       c2.nominal_diameter_inch AS second_diameter_inch
FROM parameters AS v, connections AS j, component AS c1, component AS c2,
     component_type AS t1, component_type AS t2
WHERE c1.component_id = j.first_component_id AND c2.component_id = j.second_component_id
  AND t1.component_type_id = c1.component_type_id AND t2.component_type_id = c2.component_type_id
  AND (j.first_component_id IN (SELECT component_id FROM section_components)
    OR j.second_component_id IN (SELECT component_id FROM section_components))
ORDER BY j.execution_date, j.connection_kind, j.connection_no;

-- 1.5. Основные компоненты и оборудование объекта

WITH parameters AS (
    SELECT 'PRC-01' AS area_code
),
items AS (
    SELECT a.area_code, 'component' AS item_kind, c.component_no AS item_code,
           t.type_name AS item_type,
           (SELECT m.material_code FROM material AS m WHERE m.material_id = c.material_id) AS material_code,
           (SELECT m.material_name FROM material AS m WHERE m.material_id = c.material_id) AS material_name,
           v.vendor_code, v.vendor_name, s.spool_code, s.fabrication_status AS spool_status,
           NULL AS equipment_status
    FROM parameters AS p, area AS a, spool AS s, component AS c,
         component_type AS t, delivery AS d, vendor AS v
    WHERE a.area_code = p.area_code AND s.area_id = a.area_id
      AND c.spool_id = s.spool_id AND t.component_type_id = c.component_type_id
      AND d.delivery_id = c.delivery_id AND v.vendor_id = d.vendor_id
    UNION ALL
    SELECT a.area_code, 'equipment', e.equipment_code, e.equipment_type, NULL, NULL,
           v.vendor_code, v.vendor_name, NULL, NULL, e.manufacturing_status
    FROM parameters AS p, area AS a, equipment AS e, vendor AS v
    WHERE a.area_code = p.area_code AND e.area_id = a.area_id AND v.vendor_id = e.vendor_id
)
SELECT area_code, item_kind, item_code, item_type, material_code, material_name,
       vendor_code, vendor_name, spool_code, spool_status, equipment_status
FROM items
ORDER BY item_kind, item_code;

-- 1.6. Поставки компонентов объекта за период

WITH parameters AS (
    SELECT 'PRC-01' AS area_code,
           DATE '2024-01-01' AS date_from, DATE '2025-12-31' AS date_to
),
delivery_components AS (
    SELECT a.area_code, d.delivery_id, d.delivery_code, d.delivery_date,
           v.vendor_code, v.vendor_name, c.component_no
    FROM parameters AS p, area AS a, spool AS s, component AS c, delivery AS d, vendor AS v
    WHERE a.area_code = p.area_code AND s.area_id = a.area_id
      AND c.spool_id = s.spool_id AND d.delivery_id = c.delivery_id
      AND v.vendor_id = d.vendor_id AND d.delivery_date BETWEEN p.date_from AND p.date_to
),
delivery_rows AS (
    SELECT c.area_code, c.delivery_code, c.delivery_date, c.vendor_code, c.vendor_name,
           c.component_no, d.document_type, d.document_number, d.delivery_document_id
    FROM delivery_components AS c, delivery_document AS d
    WHERE d.delivery_id = c.delivery_id
    UNION ALL
    SELECT c.area_code, c.delivery_code, c.delivery_date, c.vendor_code, c.vendor_name,
           c.component_no, NULL, NULL, NULL
    FROM delivery_components AS c
    WHERE NOT EXISTS (SELECT 1 FROM delivery_document AS d WHERE d.delivery_id = c.delivery_id)
)
SELECT area_code, delivery_code, delivery_date, vendor_code, vendor_name,
       component_no, document_type, document_number
FROM delivery_rows
ORDER BY delivery_date, delivery_code, component_no, delivery_document_id;

-- 1.7. Страны поставщиков по объектам

WITH parameters AS (
    SELECT ARRAY['PRC-01', 'STG-01'] AS area_codes
),
object_vendors AS (
    SELECT a.area_code, d.vendor_id
    FROM parameters AS p, area AS a, spool AS s, component AS c, delivery AS d
    WHERE a.area_code = ANY(p.area_codes) AND s.area_id = a.area_id
      AND c.spool_id = s.spool_id AND d.delivery_id = c.delivery_id
    UNION
    SELECT a.area_code, e.vendor_id
    FROM parameters AS p, area AS a, equipment AS e
    WHERE a.area_code = ANY(p.area_codes) AND e.area_id = a.area_id
)
SELECT o.area_code, v.vendor_code, v.vendor_name, v.country
FROM object_vendors AS o, vendor AS v
WHERE v.vendor_id = o.vendor_id
ORDER BY o.area_code, v.country, v.vendor_code;

-- 1.8. Выпущенные спулы без успешного испытания в пакете

WITH parameters AS (
    SELECT 'PRC-01' AS area_code
),
eligible_spools AS (
    SELECT s.spool_id, s.spool_code, p.pipeline_code, s.weight_ton, s.fabrication_status
    FROM parameters AS v, area AS a, spool AS s, isometric_revision AS r,
         isometric_drawing AS d, pipeline AS p
    WHERE a.area_code = v.area_code AND s.area_id = a.area_id
      AND r.isometric_revision_id = s.isometric_revision_id
      AND d.isometric_id = r.isometric_id AND p.pipeline_id = d.pipeline_id
      AND s.fabrication_status IN ('released', 'installed', 'tested')
      AND NOT EXISTS (
          SELECT 1 FROM test_package_spool AS ps, test_package AS t
          WHERE ps.spool_id = s.spool_id AND t.test_package_id = ps.test_package_id
            AND t.status = 'passed'
      )
),
spool_packages AS (
    SELECT s.spool_code, s.pipeline_code, s.weight_ton, s.fabrication_status,
           t.test_package_code, t.test_type, t.test_date, t.status AS package_status
    FROM eligible_spools AS s, test_package_spool AS ps, test_package AS t
    WHERE ps.spool_id = s.spool_id AND t.test_package_id = ps.test_package_id
    UNION ALL
    SELECT s.spool_code, s.pipeline_code, s.weight_ton, s.fabrication_status,
           NULL, NULL, NULL, NULL
    FROM eligible_spools AS s
    WHERE NOT EXISTS (SELECT 1 FROM test_package_spool AS ps WHERE ps.spool_id = s.spool_id)
)
SELECT spool_code, pipeline_code, weight_ton, fabrication_status,
       test_package_code, test_type, test_date, package_status
FROM spool_packages
ORDER BY spool_code, test_package_code;

-- 1.9. Незавершённые ремонты соединений участка

WITH parameters AS (
    SELECT 'FG-001' AS pipeline_code, 'PRC-01' AS area_code
),
section_components AS (
    SELECT c.component_id
    FROM parameters AS v, component AS c, spool AS s, isometric_revision AS r,
         isometric_drawing AS d, pipeline AS p, area AS a
    WHERE p.pipeline_code = v.pipeline_code AND a.area_code = v.area_code
      AND d.pipeline_id = p.pipeline_id AND r.isometric_id = d.isometric_id
      AND s.isometric_revision_id = r.isometric_revision_id AND s.area_id = a.area_id
      AND c.spool_id = s.spool_id
),
section_welds AS (
    SELECT w.weld_joint_id, w.weld_joint_no
    FROM weld_joint AS w
    WHERE w.first_component_id IN (SELECT component_id FROM section_components)
       OR w.second_component_id IN (SELECT component_id FROM section_components)
),
repairs AS (
    SELECT r.repair_id, i.weld_joint_id, r.repair_date, r.repair_reason,
           r.repair_description, r.status, i.inspection_id, i.report_no
    FROM repair_with_inspection AS r, inspection AS i
    WHERE i.inspection_id = r.inspection_id AND r.status IN ('planned', 'in_progress')
    UNION ALL
    SELECT r.repair_id, r.weld_joint_id, r.repair_date, r.repair_reason,
           r.repair_description, r.status, NULL, NULL
    FROM repair_without_inspection AS r
    WHERE r.status IN ('planned', 'in_progress')
)
SELECT r.repair_id, w.weld_joint_no, r.repair_date, r.repair_reason,
       r.repair_description, r.status, r.inspection_id, r.report_no
FROM repairs AS r, section_welds AS w
WHERE w.weld_joint_id = r.weld_joint_id
ORDER BY r.repair_date NULLS LAST, r.repair_id;

-- 1.10. Выпущенные спулы с устаревшей ревизией

WITH parameters AS (
    SELECT DATE '2024-01-01' AS after_date
)
SELECT s.spool_code, s.fabrication_status, d.isometric_number,
       used.revision AS used_revision, latest.revision AS latest_revision,
       latest.issue_date AS latest_issue_date
FROM parameters AS p, spool AS s, isometric_revision AS used,
     isometric_drawing AS d, isometric_revision AS latest
WHERE s.fabrication_status IN ('released', 'installed', 'tested')
  AND used.isometric_revision_id = s.isometric_revision_id
  AND d.isometric_id = used.isometric_id AND latest.isometric_id = d.isometric_id
  AND latest.revision > used.revision AND latest.issue_date > p.after_date
  AND NOT EXISTS (
      SELECT 1 FROM isometric_revision AS newer
      WHERE newer.isometric_id = latest.isometric_id AND newer.revision > latest.revision
  )
ORDER BY s.spool_code;

-- 1.11. Успешно испытанные пакеты объекта

WITH parameters AS (
    SELECT 'PRC-01' AS area_code
),
selected_areas AS (
    SELECT a.area_id
    FROM parameters AS v, area AS a
    WHERE a.area_code = v.area_code
),
selected_spools AS (
    SELECT s.spool_id FROM spool AS s
    WHERE s.area_id IN (SELECT area_id FROM selected_areas)
),
selected_components AS (
    SELECT c.component_id FROM component AS c
    WHERE c.spool_id IN (SELECT spool_id FROM selected_spools)
),
selected_packages AS (
    SELECT ps.test_package_id FROM test_package_spool AS ps
    WHERE ps.spool_id IN (SELECT spool_id FROM selected_spools)
    UNION
    SELECT pf.test_package_id
    FROM test_package_flange_connection AS pf, flange_connection AS f
    WHERE f.flange_connection_id = pf.flange_connection_id
      AND (f.first_component_id IN (SELECT component_id FROM selected_components)
        OR f.second_component_id IN (SELECT component_id FROM selected_components))
    UNION
    SELECT pe.test_package_id FROM test_package_equipment AS pe, equipment AS e
    WHERE e.equipment_id = pe.equipment_id
      AND e.area_id IN (SELECT area_id FROM selected_areas)
)
SELECT t.test_package_code, t.test_type, t.test_date, t.status
FROM test_package AS t
WHERE t.status = 'passed'
  AND t.test_package_id IN (SELECT test_package_id FROM selected_packages)
ORDER BY t.test_date NULLS LAST, t.test_package_code;

-- 1.12. Пакеты, готовые к финальным испытаниям

WITH parameters AS (
    SELECT NULL AS area_code
),
selected_areas AS (
    SELECT a.area_id
    FROM parameters AS v, area AS a
    WHERE (v.area_code IS NULL OR a.area_code = v.area_code)
),
selected_spools AS (
    SELECT s.spool_id FROM spool AS s
    WHERE s.area_id IN (SELECT area_id FROM selected_areas)
),
selected_components AS (
    SELECT c.component_id FROM component AS c
    WHERE c.spool_id IN (SELECT spool_id FROM selected_spools)
),
selected_packages AS (
    SELECT ps.test_package_id FROM test_package_spool AS ps
    WHERE ps.spool_id IN (SELECT spool_id FROM selected_spools)
    UNION
    SELECT pf.test_package_id
    FROM test_package_flange_connection AS pf, flange_connection AS f
    WHERE f.flange_connection_id = pf.flange_connection_id
      AND (f.first_component_id IN (SELECT component_id FROM selected_components)
        OR f.second_component_id IN (SELECT component_id FROM selected_components))
    UNION
    SELECT pe.test_package_id FROM test_package_equipment AS pe, equipment AS e
    WHERE e.equipment_id = pe.equipment_id
      AND e.area_id IN (SELECT area_id FROM selected_areas)
),
candidate_packages AS (
    SELECT t.test_package_id, t.test_package_code, t.test_type
    FROM test_package AS t
    WHERE t.status = 'planned'
      AND t.test_package_id IN (SELECT test_package_id FROM selected_packages)
),
package_items AS (
    SELECT t.test_package_id, t.test_package_code, t.test_type,
           'spool' AS item_kind, s.spool_code AS item_code, s.fabrication_status AS item_status
    FROM candidate_packages AS t, test_package_spool AS ps, spool AS s
    WHERE ps.test_package_id = t.test_package_id AND s.spool_id = ps.spool_id
    UNION ALL
    SELECT t.test_package_id, t.test_package_code, t.test_type,
           'flange', f.flange_connection_no, f.status
    FROM candidate_packages AS t, test_package_flange_connection AS pf, flange_connection AS f
    WHERE pf.test_package_id = t.test_package_id AND f.flange_connection_id = pf.flange_connection_id
    UNION ALL
    SELECT t.test_package_id, t.test_package_code, t.test_type,
           'equipment', e.equipment_code, e.manufacturing_status
    FROM candidate_packages AS t, test_package_equipment AS pe, equipment AS e
    WHERE pe.test_package_id = t.test_package_id AND e.equipment_id = pe.equipment_id
),
open_repairs AS (
    SELECT i.weld_joint_id
    FROM repair_with_inspection AS r, inspection AS i
    WHERE i.inspection_id = r.inspection_id AND r.status IS DISTINCT FROM 'completed'
    UNION
    SELECT r.weld_joint_id FROM repair_without_inspection AS r
    WHERE r.status IS DISTINCT FROM 'completed'
),
blocked_packages AS (
    SELECT DISTINCT ps.test_package_id
    FROM test_package_spool AS ps, component AS c, weld_joint AS w
    WHERE ps.test_package_id IN (SELECT test_package_id FROM candidate_packages)
      AND c.spool_id = ps.spool_id
      AND c.component_id IN (w.first_component_id, w.second_component_id)
      AND w.weld_joint_id IN (SELECT weld_joint_id FROM open_repairs)
),
ready_packages AS (
    SELECT i.test_package_id FROM package_items AS i
    WHERE i.test_package_id NOT IN (SELECT test_package_id FROM blocked_packages)
    GROUP BY i.test_package_id
    HAVING COUNT(*) FILTER (
        WHERE (CASE i.item_kind
            WHEN 'spool' THEN i.item_status IN ('installed', 'tested')
            WHEN 'flange' THEN i.item_status = 'accepted'
            WHEN 'equipment' THEN i.item_status = 'installed'
        END) IS NOT TRUE
    ) = 0
)
SELECT i.test_package_code, i.test_type, i.item_kind, i.item_code, i.item_status
FROM package_items AS i
WHERE i.test_package_id IN (SELECT test_package_id FROM ready_packages)
ORDER BY i.test_package_code, i.item_kind, i.item_code;

-- Агрегирующие запросы

-- 2.1. Количество спулов по объектам и статусам

WITH parameters AS (
    SELECT NULL AS area_code
),
selected_areas AS (
    SELECT a.area_id, a.area_code, a.area_name
    FROM parameters AS v, area AS a
    WHERE v.area_code IS NULL OR a.area_code = v.area_code
)
SELECT a.area_code, a.area_name, s.fabrication_status, COUNT(s.spool_id) AS spool_count
FROM selected_areas AS a, spool AS s
WHERE s.area_id = a.area_id
GROUP BY a.area_code, a.area_name, s.fabrication_status
UNION ALL
SELECT a.area_code, a.area_name, NULL, 0
FROM selected_areas AS a
WHERE NOT EXISTS (SELECT 1 FROM spool AS s WHERE s.area_id = a.area_id)
ORDER BY area_code, fabrication_status;

-- 2.2. Тоннаж спулов объекта по трубопроводам

WITH parameters AS (
    SELECT 'PRC-01' AS area_code
),
selected_areas AS (
    SELECT a.area_id, a.area_code FROM parameters AS v, area AS a
    WHERE a.area_code = v.area_code
),
spool_totals AS (
    SELECT d.pipeline_id, s.area_id, COUNT(s.spool_id) AS spool_count,
           SUM(s.weight_ton) AS known_weight_ton,
           COUNT(s.spool_id) - COUNT(s.weight_ton) AS missing_weight_count
    FROM selected_areas AS a, spool AS s, isometric_revision AS r, isometric_drawing AS d
    WHERE s.area_id = a.area_id AND r.isometric_revision_id = s.isometric_revision_id
      AND d.isometric_id = r.isometric_id
    GROUP BY d.pipeline_id, s.area_id
),
section_totals AS (
    SELECT t.pipeline_id, t.area_id, t.spool_count, t.known_weight_ton, t.missing_weight_count
    FROM spool_totals AS t, pipeline_area AS pa
    WHERE pa.pipeline_id = t.pipeline_id AND pa.area_id = t.area_id
    UNION ALL
    SELECT pa.pipeline_id, pa.area_id, 0, 0, 0
    FROM pipeline_area AS pa
    WHERE pa.area_id IN (SELECT area_id FROM selected_areas)
      AND NOT EXISTS (
          SELECT 1 FROM spool_totals AS t
          WHERE t.pipeline_id = pa.pipeline_id AND t.area_id = pa.area_id
      )
)
SELECT a.area_code, p.pipeline_code, t.spool_count, t.known_weight_ton, t.missing_weight_count
FROM section_totals AS t, selected_areas AS a, pipeline AS p
WHERE a.area_id = t.area_id AND p.pipeline_id = t.pipeline_id
ORDER BY p.pipeline_code;

-- 2.3. Количество испытанных пакетов по месяцам

WITH parameters AS (
    SELECT 2026 AS report_year
),
months AS (
    SELECT generate_series(1, 12) AS month_no
),
month_totals AS (
    SELECT m.month_no, COUNT(t.test_package_id) AS tested_package_count,
           COUNT(t.test_package_id) FILTER (WHERE t.status = 'passed') AS passed_package_count,
           COUNT(t.test_package_id) FILTER (WHERE t.status = 'failed') AS failed_package_count
    FROM parameters AS p, months AS m, test_package AS t
    WHERE t.test_date >= make_date(p.report_year, 1, 1)
      AND t.test_date < make_date(p.report_year + 1, 1, 1)
      AND t.status IN ('passed', 'failed') AND m.month_no = EXTRACT(MONTH FROM t.test_date)
    GROUP BY m.month_no
),
month_counts AS (
    SELECT month_no, tested_package_count, passed_package_count, failed_package_count
    FROM month_totals
    UNION ALL
    SELECT m.month_no, 0, 0, 0 FROM months AS m
    WHERE NOT EXISTS (SELECT 1 FROM month_totals AS t WHERE t.month_no = m.month_no)
)
SELECT p.report_year, m.month_no, m.tested_package_count, m.passed_package_count, m.failed_package_count
FROM parameters AS p, month_counts AS m
ORDER BY m.month_no;

-- 2.4. Объём сварки по сварщикам и диаметрам компонентов

WITH parameters AS (
    SELECT DATE '2026-01-01' AS date_from, DATE '2026-12-31' AS date_to
),
period_welds AS (
    SELECT wa.welder_id, w.weld_joint_id,
           c1.nominal_diameter_inch AS first_diameter_inch,
           c2.nominal_diameter_inch AS second_diameter_inch
    FROM parameters AS p, weld_joint AS w, weld_assignment AS wa, component AS c1, component AS c2
    WHERE w.weld_date BETWEEN p.date_from AND p.date_to AND wa.weld_joint_id = w.weld_joint_id
      AND c1.component_id = w.first_component_id AND c2.component_id = w.second_component_id
)
SELECT w.welder_employer_no, w.welder_name, pw.first_diameter_inch, pw.second_diameter_inch,
       COUNT(pw.weld_joint_id) AS weld_count,
       SUM(pw.first_diameter_inch) FILTER (
           WHERE pw.first_diameter_inch > 0 AND pw.first_diameter_inch = pw.second_diameter_inch
       ) AS known_weld_volume_inch,
       COUNT(pw.weld_joint_id) FILTER (
           WHERE (pw.first_diameter_inch > 0 AND pw.first_diameter_inch = pw.second_diameter_inch) IS NOT TRUE
       ) AS unresolved_diameter_count
FROM period_welds AS pw, welder AS w
WHERE w.welder_id = pw.welder_id
GROUP BY w.welder_id, pw.first_diameter_inch, pw.second_diameter_inch
UNION ALL
SELECT w.welder_employer_no, w.welder_name, NULL, NULL, 0, NULL, 0
FROM welder AS w
WHERE NOT EXISTS (SELECT 1 FROM period_welds AS pw WHERE pw.welder_id = w.welder_id)
ORDER BY welder_employer_no, first_diameter_inch, second_diameter_inch;

-- 2.5. Количество завершённых ремонтов по участкам

WITH parameters AS (
    SELECT DATE '2026-01-01' AS date_from, DATE '2026-12-31' AS date_to
),
period_repairs AS (
    SELECT r.repair_id, i.weld_joint_id
    FROM parameters AS p, repair_with_inspection AS r, inspection AS i
    WHERE i.inspection_id = r.inspection_id AND r.status = 'completed'
      AND r.repair_date BETWEEN p.date_from AND p.date_to
    UNION ALL
    SELECT r.repair_id, r.weld_joint_id
    FROM parameters AS p, repair_without_inspection AS r
    WHERE r.status = 'completed' AND r.repair_date BETWEEN p.date_from AND p.date_to
),
repair_sections AS (
    SELECT DISTINCT r.repair_id, d.pipeline_id, s.area_id
    FROM period_repairs AS r, weld_joint AS w, component AS c, spool AS s,
         isometric_revision AS v, isometric_drawing AS d
    WHERE w.weld_joint_id = r.weld_joint_id AND c.component_id IN (w.first_component_id, w.second_component_id)
      AND s.spool_id = c.spool_id AND v.isometric_revision_id = s.isometric_revision_id
      AND d.isometric_id = v.isometric_id
),
repair_counts AS (
    SELECT pipeline_id, area_id, COUNT(*) AS completed_repair_count
    FROM repair_sections GROUP BY pipeline_id, area_id
),
section_counts AS (
    SELECT r.pipeline_id, r.area_id, r.completed_repair_count
    FROM repair_counts AS r, pipeline_area AS pa
    WHERE pa.pipeline_id = r.pipeline_id AND pa.area_id = r.area_id
    UNION ALL
    SELECT pa.pipeline_id, pa.area_id, 0 FROM pipeline_area AS pa
    WHERE NOT EXISTS (
        SELECT 1 FROM repair_counts AS r
        WHERE r.pipeline_id = pa.pipeline_id AND r.area_id = pa.area_id
    )
)
SELECT p.pipeline_code, a.area_code, c.completed_repair_count
FROM section_counts AS c, pipeline AS p, area AS a
WHERE p.pipeline_id = c.pipeline_id AND a.area_id = c.area_id
ORDER BY p.pipeline_code, a.area_code;

-- 3. Представления, Views.md

-- 3.1. Категории сварщиков
CREATE OR REPLACE VIEW welder_category AS
SELECT w.welder_id, w.welder_employer_no, w.welder_name,
       CASE WHEN EXISTS (
           SELECT 1 FROM welder_certificate AS c WHERE c.welder_id = w.welder_id
       ) THEN 'welder' ELSE 'trainee' END AS category
FROM welder AS w;

-- 3.2. Принадлежность спулов
CREATE OR REPLACE VIEW spool_location AS
SELECT s.spool_id, s.spool_code, r.isometric_revision_id, r.revision, r.issue_date,
       d.isometric_id, d.isometric_number, p.pipeline_id, p.pipeline_code,
       a.area_id, a.area_code, a.area_name, s.weight_ton, s.fabrication_status
FROM spool AS s, isometric_revision AS r, isometric_drawing AS d,
     pipeline AS p, area AS a
WHERE r.isometric_revision_id = s.isometric_revision_id
  AND d.isometric_id = r.isometric_id
  AND p.pipeline_id = d.pipeline_id
  AND a.area_id = s.area_id;

-- 3.3. Реестр соединений
CREATE OR REPLACE VIEW connection_register AS
WITH connections AS (
    SELECT 'weld' AS connection_kind, w.weld_joint_id AS connection_id,
           w.weld_joint_no AS connection_no, w.weld_date AS execution_date,
           w.status, w.first_component_id, w.second_component_id
    FROM weld_joint AS w
    UNION ALL
    SELECT 'flange', f.flange_connection_id, f.flange_connection_no,
           f.assembly_date, f.status, f.first_component_id, f.second_component_id
    FROM flange_connection AS f
)
SELECT c.connection_kind, c.connection_id, c.connection_no, c.execution_date, c.status,
       c1.component_id AS first_component_id, c1.component_no AS first_component_no,
       t1.type_name AS first_component_type, c1.nominal_diameter_inch AS first_diameter_inch,
       c2.component_id AS second_component_id, c2.component_no AS second_component_no,
       t2.type_name AS second_component_type, c2.nominal_diameter_inch AS second_diameter_inch,
       s1.spool_id AS first_spool_id, s1.pipeline_code AS first_pipeline_code,
       s1.area_code AS first_area_code, s2.spool_id AS second_spool_id,
       s2.pipeline_code AS second_pipeline_code, s2.area_code AS second_area_code
FROM connections AS c, component AS c1, component AS c2,
     component_type AS t1, component_type AS t2,
     spool_location AS s1, spool_location AS s2
WHERE c1.component_id = c.first_component_id
  AND c2.component_id = c.second_component_id
  AND t1.component_type_id = c1.component_type_id
  AND t2.component_type_id = c2.component_type_id
  AND s1.spool_id = c1.spool_id
  AND s2.spool_id = c2.spool_id;

-- 3.4. Реестр ремонтов
CREATE OR REPLACE VIEW repair_register AS
SELECT 'with_inspection' AS repair_kind, r.repair_id, w.weld_joint_id,
       w.weld_joint_no, i.inspection_id, i.report_no, r.repair_date,
       r.repair_reason, r.repair_description, r.status
FROM repair_with_inspection AS r, inspection AS i, weld_joint AS w
WHERE i.inspection_id = r.inspection_id AND w.weld_joint_id = i.weld_joint_id
UNION ALL
SELECT 'without_inspection', r.repair_id, w.weld_joint_id, w.weld_joint_no,
       NULL, NULL, r.repair_date, r.repair_reason, r.repair_description, r.status
FROM repair_without_inspection AS r, weld_joint AS w
WHERE w.weld_joint_id = r.weld_joint_id;

-- 3.5. Состав пакетов испытаний
CREATE OR REPLACE VIEW test_package_contents AS
SELECT t.test_package_id, t.test_package_code, t.test_type, t.test_date,
       t.status AS package_status, 'spool' AS item_kind,
       s.spool_id AS item_id, s.spool_code AS item_code,
       s.fabrication_status AS item_status
FROM test_package AS t, test_package_spool AS ps, spool AS s
WHERE ps.test_package_id = t.test_package_id AND s.spool_id = ps.spool_id
UNION ALL
SELECT t.test_package_id, t.test_package_code, t.test_type, t.test_date,
       t.status, 'flange', f.flange_connection_id, f.flange_connection_no, f.status
FROM test_package AS t, test_package_flange_connection AS pf, flange_connection AS f
WHERE pf.test_package_id = t.test_package_id
  AND f.flange_connection_id = pf.flange_connection_id
UNION ALL
SELECT t.test_package_id, t.test_package_code, t.test_type, t.test_date,
       t.status, 'equipment', e.equipment_id, e.equipment_code, e.manufacturing_status
FROM test_package AS t, test_package_equipment AS pe, equipment AS e
WHERE pe.test_package_id = t.test_package_id AND e.equipment_id = pe.equipment_id;

-- 3.6. Готовность пакетов
CREATE OR REPLACE VIEW test_package_readiness AS
WITH item_counts AS (
    SELECT c.test_package_id, COUNT(*) AS item_count,
           COUNT(*) FILTER (
               WHERE c.item_kind = 'spool' AND (c.item_status IN ('installed', 'tested')) IS NOT TRUE
           ) AS unready_spool_count,
           COUNT(*) FILTER (
               WHERE c.item_kind = 'flange' AND (c.item_status = 'accepted') IS NOT TRUE
           ) AS unready_flange_count,
           COUNT(*) FILTER (
               WHERE c.item_kind = 'equipment' AND (c.item_status = 'installed') IS NOT TRUE
           ) AS unready_equipment_count
    FROM test_package_contents AS c
    GROUP BY c.test_package_id
),
all_item_counts AS (
    SELECT test_package_id, item_count, unready_spool_count, unready_flange_count, unready_equipment_count
    FROM item_counts
    UNION ALL
    SELECT t.test_package_id, 0, 0, 0, 0 FROM test_package AS t
    WHERE NOT EXISTS (SELECT 1 FROM item_counts AS c WHERE c.test_package_id = t.test_package_id)
),
blocking_repairs AS (
    SELECT DISTINCT ps.test_package_id, r.repair_kind, r.repair_id
    FROM test_package_spool AS ps, component AS c, weld_joint AS w, repair_register AS r
    WHERE c.spool_id = ps.spool_id
      AND c.component_id IN (w.first_component_id, w.second_component_id)
      AND r.weld_joint_id = w.weld_joint_id AND r.status IS DISTINCT FROM 'completed'
),
repair_counts AS (
    SELECT test_package_id, COUNT(*) AS blocking_repair_count
    FROM blocking_repairs GROUP BY test_package_id
),
all_repair_counts AS (
    SELECT test_package_id, blocking_repair_count FROM repair_counts
    UNION ALL
    SELECT t.test_package_id, 0 FROM test_package AS t
    WHERE NOT EXISTS (SELECT 1 FROM repair_counts AS r WHERE r.test_package_id = t.test_package_id)
)
SELECT t.test_package_id, t.test_package_code, t.test_type, t.status AS package_status,
       c.item_count, c.unready_spool_count, c.unready_flange_count,
       c.unready_equipment_count, r.blocking_repair_count,
       t.status = 'planned' AND c.item_count > 0
         AND c.unready_spool_count = 0 AND c.unready_flange_count = 0
         AND c.unready_equipment_count = 0 AND r.blocking_repair_count = 0 AS is_ready
FROM test_package AS t, all_item_counts AS c, all_repair_counts AS r
WHERE c.test_package_id = t.test_package_id AND r.test_package_id = t.test_package_id;

COMMIT;
