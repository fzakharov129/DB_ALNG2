BEGIN;

-- 1. Модифицирующие запросы, Modifications.md

-- 1.1. Добавление ревизии чертежа

PREPARE add_isometric_revision (VARCHAR, VARCHAR, DATE) AS
INSERT INTO isometric_revision (isometric_id, revision, issue_date)
SELECT d.isometric_id, $2, $3
FROM isometric_drawing AS d
WHERE d.isometric_number = $1
RETURNING isometric_revision_id, isometric_id, revision, issue_date;

-- 1.2. Изменение статуса спула

PREPARE change_spool_status (VARCHAR, VARCHAR) AS
UPDATE spool
SET fabrication_status = $2
WHERE spool_code = $1
RETURNING spool_id, spool_code, fabrication_status;

-- 1.3. Регистрация контроля соединения

PREPARE register_weld_inspection (VARCHAR, VARCHAR, DATE, VARCHAR, VARCHAR, TEXT) AS
INSERT INTO inspection (weld_joint_id, inspection_type, inspection_date, result,
                        report_no, defect_description)
SELECT w.weld_joint_id, $2, $3, $4, $5, $6
FROM weld_joint AS w
WHERE w.weld_joint_no = $1
RETURNING inspection_id, weld_joint_id, inspection_type, inspection_date,
          result, report_no, defect_description;

-- 1.4. Завершение ремонта

PREPARE complete_repair (TEXT, INTEGER, DATE, TEXT) AS
WITH completed_with_inspection AS (
    UPDATE repair_with_inspection
    SET status = 'completed', repair_date = $3, repair_description = $4
    WHERE $1 = 'with_inspection' AND repair_id = $2
    RETURNING repair_id, repair_date, repair_description, status
),
completed_without_inspection AS (
    UPDATE repair_without_inspection
    SET status = 'completed', repair_date = $3, repair_description = $4
    WHERE $1 = 'without_inspection' AND repair_id = $2
    RETURNING repair_id, repair_date, repair_description, status
)
SELECT 'with_inspection' AS repair_kind, repair_id, repair_date, repair_description, status
FROM completed_with_inspection
UNION ALL
SELECT 'without_inspection', repair_id, repair_date, repair_description, status
FROM completed_without_inspection;

-- 1.5. Регистрация пакета испытаний

PREPARE register_test_package (VARCHAR, VARCHAR) AS
INSERT INTO test_package (test_package_code, test_type, status)
VALUES ($1, $2, 'planned')
RETURNING test_package_id, test_package_code, test_type, test_date, status;

-- 1.6. Исключение спула из испытаний

PREPARE exclude_spool_from_test_package (VARCHAR, VARCHAR) AS
DELETE FROM test_package_spool AS ps
USING test_package AS t, spool AS s
WHERE t.test_package_code = $1 AND s.spool_code = $2
  AND ps.test_package_id = t.test_package_id AND ps.spool_id = s.spool_id
RETURNING ps.test_package_id, ps.spool_id;

-- 2. Проверки и триггеры, Normalization.md

-- 2.1. Минимум два участка трубопровода

CREATE FUNCTION lock_pipeline_rules()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_advisory_xact_lock(4142621, 1);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER lock_pipeline_rules
BEFORE INSERT OR UPDATE OR DELETE ON pipeline
FOR EACH STATEMENT EXECUTE FUNCTION lock_pipeline_rules();

CREATE TRIGGER lock_pipeline_area_rules
BEFORE INSERT OR UPDATE OR DELETE ON pipeline_area
FOR EACH STATEMENT EXECUTE FUNCTION lock_pipeline_rules();

CREATE FUNCTION check_pipeline_area_count()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pipeline AS p
        WHERE p.pipeline_id IN (NEW.pipeline_id, OLD.pipeline_id)
          AND (SELECT COUNT(*) FROM pipeline_area AS pa WHERE pa.pipeline_id = p.pipeline_id) < 2
    ) THEN
        RAISE EXCEPTION 'Трубопровод должен иметь минимум два участка' USING ERRCODE = '23514';
    END IF;
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER pipeline_min_areas
AFTER INSERT ON pipeline
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_pipeline_area_count();

CREATE CONSTRAINT TRIGGER pipeline_area_min_areas
AFTER INSERT OR UPDATE OR DELETE ON pipeline_area
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_pipeline_area_count();

-- 2.2. Порядок дат ревизий

CREATE TRIGGER lock_isometric_drawing_rules
BEFORE INSERT OR UPDATE OR DELETE ON isometric_drawing
FOR EACH STATEMENT EXECUTE FUNCTION lock_pipeline_rules();

CREATE TRIGGER lock_isometric_revision_rules
BEFORE INSERT OR UPDATE OR DELETE ON isometric_revision
FOR EACH STATEMENT EXECUTE FUNCTION lock_pipeline_rules();

CREATE FUNCTION check_isometric_revision_dates()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM 1 FROM isometric_drawing
    WHERE isometric_id = NEW.isometric_id
    FOR UPDATE;

    IF EXISTS (
        SELECT 1
        FROM isometric_revision AS r
        WHERE r.isometric_id = NEW.isometric_id
          AND r.isometric_revision_id IS DISTINCT FROM NEW.isometric_revision_id
          AND ((r.revision < NEW.revision AND r.issue_date > NEW.issue_date)
            OR (r.revision > NEW.revision AND r.issue_date < NEW.issue_date))
    ) THEN
        RAISE EXCEPTION 'Revision dates must follow revision order for isometric %', NEW.isometric_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER isometric_revision_date_order
BEFORE INSERT OR UPDATE OF isometric_id, revision, issue_date ON isometric_revision
FOR EACH ROW EXECUTE FUNCTION check_isometric_revision_dates();

-- 2.3. Принадлежность спула участку трубопровода

CREATE TRIGGER lock_spool_rules
BEFORE INSERT OR UPDATE OR DELETE ON spool
FOR EACH STATEMENT EXECUTE FUNCTION lock_pipeline_rules();

CREATE FUNCTION check_spool_pipeline_area()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT d.pipeline_id, s.area_id
        FROM spool AS s, isometric_revision AS r, isometric_drawing AS d
        WHERE r.isometric_revision_id = s.isometric_revision_id AND d.isometric_id = r.isometric_id
        EXCEPT
        SELECT pa.pipeline_id, pa.area_id FROM pipeline_area AS pa
    ) THEN
        RAISE EXCEPTION 'Spool area must belong to the pipeline defined by its drawing'
            USING ERRCODE = '23503';
    END IF;
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER spool_pipeline_area_check
AFTER INSERT OR UPDATE ON spool
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_spool_pipeline_area();

CREATE CONSTRAINT TRIGGER revision_spool_pipeline_area_check
AFTER UPDATE ON isometric_revision
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_spool_pipeline_area();

CREATE CONSTRAINT TRIGGER drawing_spool_pipeline_area_check
AFTER UPDATE ON isometric_drawing
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_spool_pipeline_area();

CREATE CONSTRAINT TRIGGER pipeline_area_spool_check
AFTER UPDATE OR DELETE ON pipeline_area
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_spool_pipeline_area();

-- 2.4. Минимальная толщина утеплителя

CREATE TRIGGER lock_component_rules
BEFORE INSERT OR UPDATE OR DELETE ON component
FOR EACH STATEMENT EXECUTE FUNCTION lock_pipeline_rules();

CREATE TRIGGER lock_component_insulation_rules
BEFORE INSERT OR UPDATE OR DELETE ON component_insulation
FOR EACH STATEMENT EXECUTE FUNCTION lock_pipeline_rules();

CREATE FUNCTION check_component_insulation_minimum()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM component_insulation AS ci, component AS c, spool AS s,
             isometric_revision AS r, isometric_drawing AS d, pipeline_area AS pa
        WHERE c.component_id = ci.component_id AND s.spool_id = c.spool_id
          AND r.isometric_revision_id = s.isometric_revision_id
          AND d.isometric_id = r.isometric_id
          AND pa.pipeline_id = d.pipeline_id AND pa.area_id = s.area_id
          AND ci.insulation_thickness_mm < pa.min_insulation_thickness_mm
    ) THEN
        RAISE EXCEPTION 'Component insulation thickness is less than the pipeline area minimum'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER component_insulation_minimum_check
AFTER INSERT OR UPDATE ON component_insulation
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_component_insulation_minimum();

CREATE CONSTRAINT TRIGGER component_insulation_spool_check
AFTER UPDATE ON component
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_component_insulation_minimum();

CREATE CONSTRAINT TRIGGER spool_insulation_minimum_check
AFTER UPDATE ON spool
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_component_insulation_minimum();

CREATE CONSTRAINT TRIGGER revision_insulation_minimum_check
AFTER UPDATE ON isometric_revision
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_component_insulation_minimum();

CREATE CONSTRAINT TRIGGER drawing_insulation_minimum_check
AFTER UPDATE ON isometric_drawing
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_component_insulation_minimum();

CREATE CONSTRAINT TRIGGER pipeline_area_insulation_minimum_check
AFTER UPDATE ON pipeline_area
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_component_insulation_minimum();

-- 2.5. Уникальность идентификаторов ремонта

CREATE FUNCTION lock_repair_ids()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_advisory_xact_lock(4142621, 2);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER lock_repair_with_inspection_ids
BEFORE INSERT OR UPDATE OR DELETE ON repair_with_inspection
FOR EACH STATEMENT EXECUTE FUNCTION lock_repair_ids();

CREATE TRIGGER lock_repair_without_inspection_ids
BEFORE INSERT OR UPDATE OR DELETE ON repair_without_inspection
FOR EACH STATEMENT EXECUTE FUNCTION lock_repair_ids();

CREATE FUNCTION check_repair_id_uniqueness()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM repair_with_inspection WHERE repair_id = NEW.repair_id)
       AND EXISTS (SELECT 1 FROM repair_without_inspection WHERE repair_id = NEW.repair_id) THEN
        RAISE EXCEPTION 'Repair ID must be unique across both repair tables' USING ERRCODE = '23505';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER repair_with_inspection_id_check
AFTER INSERT OR UPDATE ON repair_with_inspection
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_repair_id_uniqueness();

CREATE CONSTRAINT TRIGGER repair_without_inspection_id_check
AFTER INSERT OR UPDATE ON repair_without_inspection
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_repair_id_uniqueness();

-- 2.6. Допуск спула в пакет испытаний

CREATE FUNCTION check_test_package_spool_status()
RETURNS TRIGGER AS $$
DECLARE
    current_status VARCHAR(30);
BEGIN
    SELECT fabrication_status INTO current_status
    FROM spool WHERE spool_id = NEW.spool_id FOR UPDATE;
    IF current_status NOT IN ('released', 'installed', 'tested') THEN
        RAISE EXCEPTION 'Spool % is not released for testing', NEW.spool_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER test_package_spool_status_check
BEFORE INSERT OR UPDATE OF spool_id ON test_package_spool
FOR EACH ROW EXECUTE FUNCTION check_test_package_spool_status();

CREATE FUNCTION check_spool_status_in_test_package()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fabrication_status NOT IN ('released', 'installed', 'tested')
       AND EXISTS (SELECT 1 FROM test_package_spool WHERE spool_id = NEW.spool_id) THEN
        RAISE EXCEPTION 'Spool % belongs to a test package', NEW.spool_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER spool_test_package_status_check
BEFORE UPDATE OF fabrication_status ON spool
FOR EACH ROW EXECUTE FUNCTION check_spool_status_in_test_package();

-- 3. Индексы, Indexes.md

-- 3.1. Спулы объекта и их ревизии

CREATE INDEX spool_area_revision_btree
ON spool USING btree (area_id, isometric_revision_id);

-- 3.2. Компоненты спула

CREATE INDEX component_spool_hash
ON component USING hash (spool_id);

-- 3.3. Ревизии после указанной даты

CREATE INDEX isometric_revision_issue_date_btree
ON isometric_revision USING btree (issue_date);

-- 3.4. Сертификаты сварщика

CREATE INDEX welder_certificate_welder_hash
ON welder_certificate USING hash (welder_id);

-- 3.5. Проверки сварного соединения

CREATE INDEX inspection_weld_joint_hash
ON inspection USING hash (weld_joint_id);

-- 3.6. Оборудование объекта

CREATE INDEX equipment_area_hash
ON equipment USING hash (area_id);

-- 3.7. Поставки за период

CREATE INDEX delivery_date_btree
ON delivery USING btree (delivery_date);

-- 4. Наборы входных данных, Procedures.md

-- 4.1. Код, назначение и категории давления и температуры трубопровода

CREATE TYPE pipeline_input AS (
    pipeline_code TEXT,
    service TEXT,
    pressure_category TEXT,
    temperature_category TEXT
);

-- 4.2. Объект и требования к участку: обогрев, утеплитель и огнезащита

CREATE TYPE pipeline_area_input AS (
    area_code TEXT,
    heat_tracing BOOLEAN,
    min_insulation_thickness_mm INTEGER,
    passive_fire_protection BOOLEAN
);

-- 4.3. Код поставки, поставщик и дата поставки

CREATE TYPE delivery_input AS (
    delivery_code TEXT,
    vendor_code TEXT,
    delivery_date DATE
);

-- 4.4. Тип и номер документа поставки

CREATE TYPE delivery_document_input AS (
    document_type TEXT,
    document_number TEXT
);

-- 4.6. Материалы и толщины утеплителя и верхнего защитного слоя

CREATE TYPE component_insulation_input AS (
    insulation_material_code TEXT,
    insulation_thickness_mm INTEGER,
    cladding_material_code TEXT,
    cladding_thickness_mm NUMERIC
);

-- 4.5. Компонент спула: тип, материал, размеры, масса и сведения об изоляции

CREATE TYPE component_input AS (
    component_no TEXT,
    type_code TEXT,
    spool_code TEXT,
    material_code TEXT,
    nominal_diameter_inch NUMERIC,
    wall_thickness_mm NUMERIC,
    length_mm NUMERIC,
    width_mm NUMERIC,
    height_mm NUMERIC,
    weight_ton NUMERIC,
    certificate_no TEXT,
    insulation component_insulation_input
);

-- 4.7. ФИО сварщика, табельный номер, удостоверение и дата аттестации

CREATE TYPE welder_input AS (
    welder_employer_no TEXT,
    welder_name TEXT,
    welder_license_no TEXT,
    welder_last_attestation_date DATE
);

-- 4.8. Номер сертификата, стандарт и дата окончания действия

CREATE TYPE welder_certificate_input AS (
    certificate_number TEXT,
    standard TEXT,
    valid_until DATE
);

-- 4.9. Компоненты сварного соединения, технология, дата и состояние

CREATE TYPE weld_joint_input AS (
    weld_joint_no TEXT,
    first_component_no TEXT,
    second_component_no TEXT,
    weld_type TEXT,
    welding_process TEXT,
    weld_date DATE,
    status TEXT
);

-- 4.10. Компоненты фланцевого соединения, прокладка, крепёж, дата и состояние

CREATE TYPE flange_connection_input AS (
    flange_connection_no TEXT,
    first_component_no TEXT,
    second_component_no TEXT,
    gasket_type TEXT,
    bolt_specification TEXT,
    assembly_date DATE,
    status TEXT
);

-- 5. Хранимые процедуры, Procedures.md
-- Вызов: CALL имя_процедуры(...); параметры передаются в порядке объявления.
-- Один набор: ROW(...)::имя_типа; несколько наборов: ARRAY[ROW(...)::имя_типа, ...].
-- Поля ROW передаются в указанном ниже порядке; даты - DATE '2025-01-31', логические значения - TRUE или FALSE.

-- 5.1. Регистрация трубопровода, его участков и требований
-- p_pipeline - ROW(код трубопровода, назначение, категория давления, категория температуры).
-- Давление: low, normal, high; температура: cryogenic, low, normal, high.
-- p_areas - массив минимум из двух ROW(код существующего объекта, обогрев, минимальная толщина утеплителя в мм, пассивная огнезащита).
-- Коды объектов не повторяются; минимальная толщина неотрицательна и кратна 20 мм.

CREATE PROCEDURE create_pipeline_with_areas (
    p_pipeline pipeline_input,
    p_areas pipeline_area_input[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    selected_pipeline_id INTEGER;
BEGIN
    PERFORM pg_advisory_xact_lock(4142621, 1);

    IF p_pipeline IS NULL OR COALESCE(cardinality(p_areas), 0) < 2 THEN
        RAISE EXCEPTION 'Укажите трубопровод и минимум два участка' USING ERRCODE = '22023';
    END IF;

    IF EXISTS (
        SELECT 1 FROM unnest(p_areas) AS a
        WHERE a.area_code IS NULL OR NOT EXISTS (
            SELECT 1 FROM area WHERE area_code = a.area_code
        )
    ) THEN
        RAISE EXCEPTION 'Объект участка не найден' USING ERRCODE = '23503';
    END IF;

    IF EXISTS (
        SELECT a.area_code FROM unnest(p_areas) AS a
        GROUP BY a.area_code HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Участки трубопровода не должны повторяться' USING ERRCODE = '22023';
    END IF;

    INSERT INTO pipeline (pipeline_code, service, pressure_category, temperature_category)
    VALUES (p_pipeline.pipeline_code, p_pipeline.service,
            p_pipeline.pressure_category, p_pipeline.temperature_category)
    RETURNING pipeline_id INTO selected_pipeline_id;

    INSERT INTO pipeline_area (pipeline_id, area_id, heat_tracing,
                               min_insulation_thickness_mm, passive_fire_protection)
    SELECT selected_pipeline_id, a.area_id, v.heat_tracing,
           v.min_insulation_thickness_mm, v.passive_fire_protection
    FROM unnest(p_areas) AS v, area AS a
    WHERE a.area_code = v.area_code;
END;
$$;

-- 5.2. Регистрация поставки с документами и компонентами
-- p_delivery - ROW(новый код поставки, код существующего поставщика, дата поставки).
-- p_documents - массив ROW(тип документа, номер документа); NULL или пустой массив - без документов.
-- p_components - непустой массив component_input; поля каждого компонента и вложенной изоляции перечислены в п. 5.3.

CREATE PROCEDURE register_delivery_with_documents (
    p_delivery delivery_input,
    p_documents delivery_document_input[],
    p_components component_input[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    selected_vendor_id INTEGER;
    selected_delivery_id INTEGER;
    current_component component_input;
BEGIN
    PERFORM pg_advisory_xact_lock(4142621, 1);

    IF p_delivery IS NULL OR COALESCE(cardinality(p_components), 0) = 0 THEN
        RAISE EXCEPTION 'Укажите поставку и её компоненты' USING ERRCODE = '22023';
    END IF;

    SELECT vendor_id INTO selected_vendor_id
    FROM vendor WHERE vendor_code = p_delivery.vendor_code;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Поставщик % не найден', p_delivery.vendor_code USING ERRCODE = '23503';
    END IF;

    INSERT INTO delivery (delivery_code, vendor_id, delivery_date)
    VALUES (p_delivery.delivery_code, selected_vendor_id, p_delivery.delivery_date)
    RETURNING delivery_id INTO selected_delivery_id;

    INSERT INTO delivery_document (delivery_id, document_type, document_number)
    SELECT selected_delivery_id, d.document_type, d.document_number
    FROM unnest(p_documents) AS d;

    FOREACH current_component IN ARRAY p_components
    LOOP
        CALL register_component_with_insulation(p_delivery.delivery_code, current_component);
    END LOOP;
END;
$$;

-- 5.3. Регистрация компонента с изоляцией
-- p_delivery_code - код существующей поставки.
-- p_component - ROW(номер компонента, код типа, код спула, код материала, номинальный диаметр в дюймах,
--                   толщина стенки в мм, длина в мм, ширина в мм, высота в мм, масса в тоннах, номер сертификата, изоляция).
-- Тип, спул и указанный материал должны существовать; необязательные поля из ddl.sql допускают NULL.
-- Изоляция - ROW(код утеплителя, его толщина в мм, код защитного слоя, его толщина в мм)::component_insulation_input.
-- NULL вместо изоляции - без записи об изоляции; при её наличии оба материала должны существовать.
-- Толщина утеплителя положительна, кратна 20 мм и не меньше минимума участка; толщина защитного слоя больше 0.

CREATE PROCEDURE register_component_with_insulation (
    p_delivery_code TEXT,
    p_component component_input
)
LANGUAGE plpgsql
AS $$
DECLARE
    selected_delivery_id INTEGER;
    selected_type_id INTEGER;
    selected_spool_id INTEGER;
    selected_material_id INTEGER;
    selected_component_id INTEGER;
    selected_insulation_id INTEGER;
    selected_cladding_id INTEGER;
    selected_minimum INTEGER;
    selected_insulation component_insulation_input := p_component.insulation;
BEGIN
    PERFORM pg_advisory_xact_lock(4142621, 1);

    IF p_component IS NULL THEN
        RAISE EXCEPTION 'Укажите данные компонента' USING ERRCODE = '22023';
    END IF;

    SELECT delivery_id INTO selected_delivery_id
    FROM delivery WHERE delivery_code = p_delivery_code;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Поставка % не найдена', p_delivery_code USING ERRCODE = '23503';
    END IF;

    SELECT component_type_id INTO selected_type_id
    FROM component_type WHERE type_code = p_component.type_code;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Тип компонента % не найден', p_component.type_code USING ERRCODE = '23503';
    END IF;

    SELECT spool_id INTO selected_spool_id
    FROM spool WHERE spool_code = p_component.spool_code FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Спул % не найден', p_component.spool_code USING ERRCODE = '23503';
    END IF;

    IF p_component.material_code IS NOT NULL THEN
        SELECT material_id INTO selected_material_id
        FROM material WHERE material_code = p_component.material_code;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Материал % не найден', p_component.material_code USING ERRCODE = '23503';
        END IF;
    END IF;

    IF selected_insulation IS DISTINCT FROM NULL THEN
        SELECT insulation_material_id INTO selected_insulation_id
        FROM insulation_material
        WHERE material_code = selected_insulation.insulation_material_code;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Материал утеплителя % не найден',
                selected_insulation.insulation_material_code USING ERRCODE = '23503';
        END IF;

        SELECT cladding_material_id INTO selected_cladding_id
        FROM cladding_material
        WHERE material_code = selected_insulation.cladding_material_code;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Материал защитного слоя % не найден',
                selected_insulation.cladding_material_code USING ERRCODE = '23503';
        END IF;

        SELECT pa.min_insulation_thickness_mm INTO selected_minimum
        FROM spool AS s, isometric_revision AS r, isometric_drawing AS d, pipeline_area AS pa
        WHERE s.spool_id = selected_spool_id
          AND r.isometric_revision_id = s.isometric_revision_id
          AND d.isometric_id = r.isometric_id
          AND pa.pipeline_id = d.pipeline_id AND pa.area_id = s.area_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Участок трубопровода для спула не найден' USING ERRCODE = '23503';
        END IF;

        IF selected_insulation.insulation_thickness_mm < selected_minimum THEN
            RAISE EXCEPTION 'Толщина утеплителя должна быть не менее % мм', selected_minimum
                USING ERRCODE = '23514';
        END IF;
    END IF;

    INSERT INTO component (component_no, component_type_id, spool_id, material_id,
                           delivery_id, nominal_diameter_inch, wall_thickness_mm,
                           length_mm, width_mm, height_mm, weight_ton, certificate_no)
    VALUES (p_component.component_no, selected_type_id, selected_spool_id, selected_material_id,
            selected_delivery_id, p_component.nominal_diameter_inch, p_component.wall_thickness_mm,
            p_component.length_mm, p_component.width_mm, p_component.height_mm,
            p_component.weight_ton, p_component.certificate_no)
    RETURNING component_id INTO selected_component_id;

    IF selected_insulation IS DISTINCT FROM NULL THEN
        INSERT INTO component_insulation (component_id, insulation_material_id,
                                          insulation_thickness_mm, cladding_material_id,
                                          cladding_thickness_mm)
        VALUES (selected_component_id, selected_insulation_id,
                selected_insulation.insulation_thickness_mm, selected_cladding_id,
                selected_insulation.cladding_thickness_mm);
    END IF;
END;
$$;

-- 5.4. Регистрация сварщика с сертификатами
-- p_welder - ROW(табельный номер, ФИО, номер удостоверения из шести цифр, дата последней аттестации).
-- p_certificates - массив ROW(номер сертификата, стандарт, дата окончания действия).
-- NULL или пустой массив сертификатов - стажёр; дата аттестации может быть NULL, номер удостоверения обязателен.

CREATE PROCEDURE register_welder_with_certificates (
    p_welder welder_input,
    p_certificates welder_certificate_input[]
)
LANGUAGE SQL
AS $$
    WITH registered_welder AS (
        INSERT INTO welder (welder_employer_no, welder_name, welder_license_no,
                            welder_last_attestation_date)
        VALUES ((p_welder).welder_employer_no, (p_welder).welder_name,
                (p_welder).welder_license_no, (p_welder).welder_last_attestation_date)
        RETURNING welder_id
    )
    INSERT INTO welder_certificate (welder_id, certificate_number, standard, valid_until)
    SELECT w.welder_id, c.certificate_number, c.standard, c.valid_until
    FROM registered_welder AS w, unnest(p_certificates) AS c;
$$;

-- 5.5. Регистрация сварного соединения с участниками
-- p_weld_joint - ROW(номер соединения, номер первого компонента, номер второго компонента, тип сварного соединения, процесс сварки, дата сварки, статус).
-- p_welder_employer_nos - непустой массив табельных номеров, например ARRAY['W001', 'W002'].
-- Компоненты должны существовать и различаться; сварщики должны существовать и не повторяться.

CREATE PROCEDURE register_weld_with_welders (
    p_weld_joint weld_joint_input,
    p_welder_employer_nos TEXT[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    selected_first_component_id INTEGER;
    selected_second_component_id INTEGER;
    selected_weld_joint_id INTEGER;
BEGIN
    IF p_weld_joint IS NULL OR COALESCE(cardinality(p_welder_employer_nos), 0) = 0 THEN
        RAISE EXCEPTION 'Укажите соединение и хотя бы одного сварщика' USING ERRCODE = '22023';
    END IF;

    SELECT component_id INTO selected_first_component_id
    FROM component WHERE component_no = p_weld_joint.first_component_no;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Первый компонент % не найден', p_weld_joint.first_component_no
            USING ERRCODE = '23503';
    END IF;

    SELECT component_id INTO selected_second_component_id
    FROM component WHERE component_no = p_weld_joint.second_component_no;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Второй компонент % не найден', p_weld_joint.second_component_no
            USING ERRCODE = '23503';
    END IF;

    IF selected_first_component_id = selected_second_component_id THEN
        RAISE EXCEPTION 'Компоненты соединения должны различаться' USING ERRCODE = '23514';
    END IF;

    IF EXISTS (
        SELECT n.employer_no FROM unnest(p_welder_employer_nos) AS n(employer_no)
        GROUP BY n.employer_no HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Участники сварки не должны повторяться' USING ERRCODE = '22023';
    END IF;

    IF EXISTS (
        SELECT 1 FROM unnest(p_welder_employer_nos) AS n(employer_no)
        WHERE n.employer_no IS NULL OR NOT EXISTS (
            SELECT 1 FROM welder WHERE welder_employer_no = n.employer_no
        )
    ) THEN
        RAISE EXCEPTION 'Один из сварщиков не найден' USING ERRCODE = '23503';
    END IF;

    INSERT INTO weld_joint (weld_joint_no, first_component_id, second_component_id,
                            weld_type, welding_process, weld_date, status)
    VALUES (p_weld_joint.weld_joint_no, selected_first_component_id, selected_second_component_id,
            p_weld_joint.weld_type, p_weld_joint.welding_process,
            p_weld_joint.weld_date, p_weld_joint.status)
    RETURNING weld_joint_id INTO selected_weld_joint_id;

    INSERT INTO weld_assignment (weld_joint_id, welder_id)
    SELECT selected_weld_joint_id, w.welder_id
    FROM welder AS w WHERE w.welder_employer_no = ANY(p_welder_employer_nos);
END;
$$;

-- 5.6. Регистрация фланцевого соединения
-- p_flange_connection - ROW(номер соединения, номер первого компонента, номер второго компонента, тип прокладки, спецификация крепежа, дата сборки, статус).
-- Компоненты должны существовать и различаться; допустимые типы: FLG-WN, FLG-BL, VLV-*, STRAINER, EXP-JOINT, ORIFICE.

CREATE PROCEDURE register_flange_connection (
    p_flange_connection flange_connection_input
)
LANGUAGE plpgsql
AS $$
DECLARE
    selected_first_component_id INTEGER;
    selected_second_component_id INTEGER;
BEGIN
    IF p_flange_connection IS NULL THEN
        RAISE EXCEPTION 'Укажите данные фланцевого соединения' USING ERRCODE = '22023';
    END IF;

    SELECT component_id INTO selected_first_component_id
    FROM component WHERE component_no = p_flange_connection.first_component_no;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Первый компонент % не найден', p_flange_connection.first_component_no
            USING ERRCODE = '23503';
    END IF;

    SELECT component_id INTO selected_second_component_id
    FROM component WHERE component_no = p_flange_connection.second_component_no;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Второй компонент % не найден', p_flange_connection.second_component_no
            USING ERRCODE = '23503';
    END IF;

    IF selected_first_component_id = selected_second_component_id THEN
        RAISE EXCEPTION 'Компоненты соединения должны различаться' USING ERRCODE = '23514';
    END IF;

    IF EXISTS (
        SELECT 1 FROM component AS c, component_type AS t
        WHERE c.component_id IN (selected_first_component_id, selected_second_component_id)
          AND t.component_type_id = c.component_type_id
          AND NOT (t.type_code IN ('FLG-WN', 'FLG-BL', 'STRAINER', 'EXP-JOINT', 'ORIFICE')
                   OR t.type_code LIKE 'VLV-%')
    ) THEN
        RAISE EXCEPTION 'Тип компонента не допускает фланцевое соединение' USING ERRCODE = '23514';
    END IF;

    INSERT INTO flange_connection (flange_connection_no, first_component_id, second_component_id,
                                   gasket_type, bolt_specification, assembly_date, status)
    VALUES (p_flange_connection.flange_connection_no,
            selected_first_component_id, selected_second_component_id,
            p_flange_connection.gasket_type, p_flange_connection.bolt_specification,
            p_flange_connection.assembly_date, p_flange_connection.status);
END;
$$;

-- 5.7. Заполнение пакета испытаний
-- p_test_package_code - код существующего пакета испытаний со статусом planned.
-- p_spool_codes - массив кодов спулов, например ARRAY['SP-001', 'SP-021'].
-- p_flange_connection_nos - массив номеров фланцевых соединений, например ARRAY['FC-001'].
-- p_equipment_codes - массив кодов оборудования, например ARRAY['EQ-001'].
-- Ненужные массивы - NULL или пустые; хотя бы один массив непустой, все элементы существуют и не повторяются.
-- Спулы должны иметь статус released, installed или tested; уже включённые в пакет элементы повторно не добавляются.

CREATE PROCEDURE add_test_package_contents (
    p_test_package_code TEXT,
    p_spool_codes TEXT[],
    p_flange_connection_nos TEXT[],
    p_equipment_codes TEXT[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    selected_package_id INTEGER;
    selected_package_status TEXT;
BEGIN
    PERFORM pg_advisory_xact_lock(4142621, 1);

    SELECT test_package_id, status INTO selected_package_id, selected_package_status
    FROM test_package WHERE test_package_code = p_test_package_code FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Пакет испытаний % не найден', p_test_package_code USING ERRCODE = '23503';
    END IF;
    IF selected_package_status <> 'planned' THEN
        RAISE EXCEPTION 'Состав можно добавлять только в запланированный пакет испытаний'
            USING ERRCODE = '23514';
    END IF;

    IF COALESCE(cardinality(p_spool_codes), 0)
       + COALESCE(cardinality(p_flange_connection_nos), 0)
       + COALESCE(cardinality(p_equipment_codes), 0) = 0 THEN
        RAISE EXCEPTION 'Укажите хотя бы один элемент пакета испытаний' USING ERRCODE = '22023';
    END IF;

    IF EXISTS (
        SELECT n.code FROM unnest(p_spool_codes) AS n(code)
        GROUP BY n.code HAVING COUNT(*) > 1
    ) OR EXISTS (
        SELECT n.code FROM unnest(p_flange_connection_nos) AS n(code)
        GROUP BY n.code HAVING COUNT(*) > 1
    ) OR EXISTS (
        SELECT n.code FROM unnest(p_equipment_codes) AS n(code)
        GROUP BY n.code HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Элементы пакета испытаний не должны повторяться' USING ERRCODE = '22023';
    END IF;

    IF EXISTS (
        SELECT 1 FROM unnest(p_spool_codes) AS n(code)
        WHERE n.code IS NULL OR NOT EXISTS (SELECT 1 FROM spool WHERE spool_code = n.code)
    ) OR EXISTS (
        SELECT 1 FROM unnest(p_flange_connection_nos) AS n(code)
        WHERE n.code IS NULL OR NOT EXISTS (
            SELECT 1 FROM flange_connection WHERE flange_connection_no = n.code
        )
    ) OR EXISTS (
        SELECT 1 FROM unnest(p_equipment_codes) AS n(code)
        WHERE n.code IS NULL OR NOT EXISTS (SELECT 1 FROM equipment WHERE equipment_code = n.code)
    ) THEN
        RAISE EXCEPTION 'Один из элементов пакета испытаний не найден' USING ERRCODE = '23503';
    END IF;

    PERFORM 1 FROM spool WHERE spool_code = ANY(p_spool_codes) ORDER BY spool_id FOR UPDATE;

    IF EXISTS (
        SELECT 1 FROM spool
        WHERE spool_code = ANY(p_spool_codes)
          AND fabrication_status NOT IN ('released', 'installed', 'tested')
    ) THEN
        RAISE EXCEPTION 'В пакет испытаний допускаются только выпущенные спулы' USING ERRCODE = '23514';
    END IF;

    INSERT INTO test_package_spool (test_package_id, spool_id)
    SELECT selected_package_id, spool_id FROM spool WHERE spool_code = ANY(p_spool_codes);

    INSERT INTO test_package_flange_connection (test_package_id, flange_connection_id)
    SELECT selected_package_id, flange_connection_id
    FROM flange_connection WHERE flange_connection_no = ANY(p_flange_connection_nos);

    INSERT INTO test_package_equipment (test_package_id, equipment_id)
    SELECT selected_package_id, equipment_id FROM equipment WHERE equipment_code = ANY(p_equipment_codes);
END;
$$;

COMMIT;
