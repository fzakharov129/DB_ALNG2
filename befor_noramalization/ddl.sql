-- Участки и трубопроводы

CREATE TABLE area(
    area_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    area_code VARCHAR(20) UNIQUE NOT NULL,
    area_name VARCHAR(100),
    area_type VARCHAR(50)
);

CREATE TABLE pipeline (
    pipeline_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pipeline_code VARCHAR(50) UNIQUE NOT NULL,
    service VARCHAR(100) NOT NULL,
    pressure_category VARCHAR(10) NOT NULL CHECK (pressure_category IN ('low', 'normal', 'high')),
    temperature_category VARCHAR(10) NOT NULL CHECK (temperature_category IN ('cryogenic', 'low', 'normal', 'high'))
);

CREATE TABLE pipeline_area (
    pipeline_id INTEGER NOT NULL REFERENCES pipeline(pipeline_id),
    area_id INTEGER NOT NULL REFERENCES area(area_id),
    heat_tracing BOOLEAN NOT NULL,
    min_insulation_thickness_mm INTEGER NOT NULL CHECK (min_insulation_thickness_mm >= 0 AND min_insulation_thickness_mm % 20 = 0),
    passive_fire_protection BOOLEAN NOT NULL,
    PRIMARY KEY (pipeline_id, area_id)
);

CREATE FUNCTION check_pipeline_area_count()
RETURNS TRIGGER AS $$
DECLARE
    checked_pipeline_id INTEGER;
BEGIN
    FOR checked_pipeline_id IN
        SELECT DISTINCT pipeline_id
        FROM unnest(ARRAY[
            CASE WHEN TG_TABLE_NAME = 'pipeline' AND TG_OP = 'INSERT' THEN NEW.pipeline_id
                 WHEN TG_TABLE_NAME = 'pipeline_area' AND TG_OP IN ('INSERT', 'UPDATE') THEN NEW.pipeline_id END,
            CASE WHEN TG_TABLE_NAME = 'pipeline_area' AND TG_OP IN ('DELETE', 'UPDATE') THEN OLD.pipeline_id END
        ]) AS ids(pipeline_id)
        WHERE pipeline_id IS NOT NULL
    LOOP
        PERFORM 1 FROM pipeline WHERE pipeline_id = checked_pipeline_id FOR UPDATE;
        IF FOUND AND (SELECT COUNT(*) FROM pipeline_area WHERE pipeline_id = checked_pipeline_id) < 2 THEN
            RAISE EXCEPTION 'Pipeline % must have at least two areas', checked_pipeline_id;
        END IF;
    END LOOP;
    RETURN NULL;
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

-- Чертежи и спулы

CREATE TABLE isometric_drawing (
    isometric_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isometric_number VARCHAR(50) UNIQUE NOT NULL,
    pipeline_id INTEGER NOT NULL,
    UNIQUE (isometric_id, pipeline_id),
    FOREIGN KEY (pipeline_id) REFERENCES pipeline(pipeline_id)
);

CREATE TABLE isometric_revision (
    isometric_revision_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isometric_id INTEGER NOT NULL,
    revision VARCHAR(2) NOT NULL CHECK (revision ~ '^[0-9]{2}$'),
    issue_date DATE NOT NULL,
    UNIQUE (isometric_id, revision),
    UNIQUE (isometric_revision_id, isometric_id),
    FOREIGN KEY (isometric_id) REFERENCES isometric_drawing(isometric_id)
);

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

CREATE TABLE spool (
    spool_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    spool_code VARCHAR(50) UNIQUE NOT NULL,
    isometric_revision_id INTEGER NOT NULL,
    isometric_id INTEGER NOT NULL,
    pipeline_id INTEGER NOT NULL,
    area_id INTEGER NOT NULL,
    weight_ton NUMERIC(10, 3),
    fabrication_status VARCHAR(30) NOT NULL CHECK (fabrication_status IN ('planned', 'in_progress', 'under_inspection', 'under_repair', 'released', 'installed', 'tested')),
    FOREIGN KEY (isometric_revision_id, isometric_id)
        REFERENCES isometric_revision(isometric_revision_id, isometric_id),
    FOREIGN KEY (isometric_id, pipeline_id)
        REFERENCES isometric_drawing(isometric_id, pipeline_id),
    FOREIGN KEY (pipeline_id, area_id)
        REFERENCES pipeline_area(pipeline_id, area_id)
);

-- Сварщики и сертификаты

CREATE TABLE welder(
    welder_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    welder_employer_no VARCHAR(30) UNIQUE NOT NULL,
    welder_name VARCHAR(100) NOT NULL,
    welder_license_no VARCHAR(6) NOT NULL CHECK (welder_license_no ~ '^[0-9]{6}$'),
    welder_last_attestation_date DATE
);

CREATE TABLE welder_certificate (
    certificate_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    welder_id INTEGER NOT NULL REFERENCES welder(welder_id),
    certificate_number VARCHAR(50) NOT NULL,
    standard VARCHAR(100) NOT NULL,
    valid_until DATE NOT NULL
);

CREATE VIEW welder_category AS
SELECT w.welder_id, w.welder_employer_no, w.welder_name,
       CASE WHEN EXISTS (
           SELECT 1 FROM welder_certificate AS c WHERE c.welder_id = w.welder_id
       ) THEN 'welder' ELSE 'trainee' END AS category
FROM welder AS w;

-- Справочники компонентов и материалов

CREATE TABLE component_type(
    component_type_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type_code VARCHAR(30) UNIQUE NOT NULL,
    type_name VARCHAR(100) NOT NULL
);

CREATE TABLE material(
    material_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    material_code VARCHAR(50) UNIQUE NOT NULL,
    material_name VARCHAR(100),
    material_standard VARCHAR(100)
);

CREATE TABLE insulation_material (
    insulation_material_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    material_code VARCHAR(30) UNIQUE NOT NULL,
    material_name VARCHAR(100) NOT NULL
);

CREATE TABLE cladding_material (
    cladding_material_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    material_code VARCHAR(30) UNIQUE NOT NULL,
    material_name VARCHAR(100) NOT NULL,
    coating VARCHAR(100) NOT NULL
);

-- Поставщики

CREATE TABLE vendor(
    vendor_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vendor_name VARCHAR(200) NOT NULL,
    vendor_code VARCHAR(10) UNIQUE NOT NULL,
    country VARCHAR(100) NOT NULL,
    tax_id VARCHAR(50) NOT NULL,
    vendor_address TEXT NOT NULL,
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(254) NOT NULL,
    contact_name VARCHAR(200),
    contact_position VARCHAR(100),
    UNIQUE (country, tax_id)
);

-- Поставки и документы

CREATE TABLE delivery (
    delivery_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    delivery_code VARCHAR(30) UNIQUE NOT NULL,
    vendor_id INTEGER NOT NULL REFERENCES vendor(vendor_id),
    delivery_date DATE NOT NULL
);

CREATE TABLE delivery_document (
    delivery_document_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    delivery_id INTEGER NOT NULL REFERENCES delivery(delivery_id),
    document_type VARCHAR(100) NOT NULL,
    document_number VARCHAR(100) NOT NULL,
    UNIQUE (delivery_id, document_type, document_number)
);

-- Компоненты и изоляция

CREATE TABLE component(
    component_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    component_no VARCHAR(50) UNIQUE NOT NULL,
    component_type_id INTEGER NOT NULL,
    spool_id INTEGER NOT NULL,
    material_id INTEGER,
    delivery_id INTEGER NOT NULL,
    nominal_diameter_inch NUMERIC(10, 2),
    wall_thickness_mm NUMERIC(10, 2),
    length_mm NUMERIC(10, 2),
    width_mm NUMERIC(10, 2),
    height_mm NUMERIC(10, 2),
    weight_ton NUMERIC(10, 3),
    certificate_no VARCHAR(100),

    FOREIGN KEY (component_type_id) REFERENCES component_type(component_type_id),
    FOREIGN KEY (spool_id) REFERENCES spool(spool_id),
    FOREIGN KEY (material_id) REFERENCES material(material_id),
    FOREIGN KEY (delivery_id) REFERENCES delivery(delivery_id)
);

CREATE TABLE component_insulation (
    component_id INTEGER PRIMARY KEY REFERENCES component(component_id),
    insulation_material_id INTEGER NOT NULL REFERENCES insulation_material(insulation_material_id),
    insulation_thickness_mm INTEGER NOT NULL CHECK (insulation_thickness_mm > 0 AND insulation_thickness_mm % 20 = 0),
    cladding_material_id INTEGER NOT NULL REFERENCES cladding_material(cladding_material_id),
    cladding_thickness_mm NUMERIC(6, 2) NOT NULL CHECK (cladding_thickness_mm > 0)
);

CREATE FUNCTION lock_insulation_rules()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_advisory_xact_lock(4142621, 1);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER lock_pipeline_area_insulation
BEFORE INSERT OR UPDATE OR DELETE ON pipeline_area
FOR EACH STATEMENT EXECUTE FUNCTION lock_insulation_rules();

CREATE TRIGGER lock_spool_insulation
BEFORE INSERT OR UPDATE OR DELETE ON spool
FOR EACH STATEMENT EXECUTE FUNCTION lock_insulation_rules();

CREATE TRIGGER lock_component_insulation_rule
BEFORE INSERT OR UPDATE OR DELETE ON component
FOR EACH STATEMENT EXECUTE FUNCTION lock_insulation_rules();

CREATE TRIGGER lock_component_insulation_data
BEFORE INSERT OR UPDATE OR DELETE ON component_insulation
FOR EACH STATEMENT EXECUTE FUNCTION lock_insulation_rules();

CREATE FUNCTION check_component_insulation_minimum()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM component_insulation AS ci
        JOIN component AS c ON c.component_id = ci.component_id
        JOIN spool AS s ON s.spool_id = c.spool_id
        JOIN pipeline_area AS pa ON pa.pipeline_id = s.pipeline_id AND pa.area_id = s.area_id
        WHERE ci.insulation_thickness_mm < pa.min_insulation_thickness_mm
          AND CASE TG_TABLE_NAME
              WHEN 'component_insulation' THEN ci.component_id = (to_jsonb(NEW)->>'component_id')::integer
              WHEN 'component' THEN c.component_id = (to_jsonb(NEW)->>'component_id')::integer
              WHEN 'spool' THEN s.spool_id = (to_jsonb(NEW)->>'spool_id')::integer
              WHEN 'pipeline_area' THEN pa.pipeline_id = (to_jsonb(NEW)->>'pipeline_id')::integer AND pa.area_id = (to_jsonb(NEW)->>'area_id')::integer
              ELSE FALSE
          END
    ) THEN
        RAISE EXCEPTION 'Component insulation thickness is less than the pipeline area minimum';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_insulation_on_component_insulation
AFTER INSERT OR UPDATE ON component_insulation
FOR EACH ROW EXECUTE FUNCTION check_component_insulation_minimum();

CREATE TRIGGER check_insulation_on_component
AFTER UPDATE OF spool_id ON component
FOR EACH ROW EXECUTE FUNCTION check_component_insulation_minimum();

CREATE TRIGGER check_insulation_on_spool
AFTER UPDATE OF pipeline_id, area_id ON spool
FOR EACH ROW EXECUTE FUNCTION check_component_insulation_minimum();

CREATE TRIGGER check_insulation_on_pipeline_area
AFTER UPDATE OF min_insulation_thickness_mm ON pipeline_area
FOR EACH ROW EXECUTE FUNCTION check_component_insulation_minimum();

-- Соединения

CREATE TABLE weld_joint (
    weld_joint_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    weld_joint_no VARCHAR(50) UNIQUE NOT NULL,
    first_component_id INTEGER NOT NULL,
    second_component_id INTEGER NOT NULL,
    weld_type VARCHAR(30),
    welding_process VARCHAR(50),
    weld_date DATE,
    status VARCHAR(30),

    FOREIGN KEY (first_component_id) REFERENCES component(component_id),
    FOREIGN KEY (second_component_id) REFERENCES component(component_id),
    CHECK (first_component_id <> second_component_id)
);
CREATE TABLE weld_assignment (
    weld_joint_id INTEGER NOT NULL REFERENCES weld_joint(weld_joint_id),
    welder_id INTEGER NOT NULL REFERENCES welder(welder_id),
    PRIMARY KEY (weld_joint_id, welder_id)
);

CREATE TABLE flange_connection (
    flange_connection_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    flange_connection_no VARCHAR(50) UNIQUE NOT NULL,
    first_component_id INTEGER NOT NULL,
    second_component_id INTEGER NOT NULL,
    gasket_type VARCHAR(100),
    bolt_specification VARCHAR(100),
    assembly_date DATE,
    status VARCHAR(30),

    FOREIGN KEY (first_component_id) REFERENCES component(component_id),
    FOREIGN KEY (second_component_id) REFERENCES component(component_id),
    CHECK (first_component_id <> second_component_id)
);

-- Оборудование

CREATE TABLE equipment (
    equipment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    equipment_code VARCHAR(50) UNIQUE NOT NULL,
    equipment_type VARCHAR(50),
    equipment_name VARCHAR(100),
    area_id INTEGER NOT NULL,
    vendor_id INTEGER NOT NULL,
    manufacturing_status VARCHAR(100),
    FOREIGN KEY (area_id) REFERENCES area(area_id),
    FOREIGN KEY (vendor_id) REFERENCES vendor(vendor_id)
);

-- Контроль и ремонт

CREATE TABLE inspection (
    inspection_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    weld_joint_id INTEGER NOT NULL,
    inspection_type VARCHAR(30) NOT NULL,
    inspection_date DATE,
    result VARCHAR(30),
    report_no VARCHAR(50),
    defect_description TEXT,
    UNIQUE (inspection_id, weld_joint_id),
    FOREIGN KEY (weld_joint_id) REFERENCES weld_joint(weld_joint_id)
);

CREATE TABLE repair (
    repair_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    weld_joint_id INTEGER NOT NULL,
    inspection_id INTEGER,
    repair_date DATE,
    repair_reason TEXT,
    repair_description TEXT,
    status VARCHAR(30),
    FOREIGN KEY (weld_joint_id) REFERENCES weld_joint(weld_joint_id),
    FOREIGN KEY (inspection_id, weld_joint_id)
        REFERENCES inspection(inspection_id, weld_joint_id)
);
-- Испытания

CREATE TABLE test_package (
    test_package_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    test_package_code VARCHAR(50) UNIQUE NOT NULL,
    test_type VARCHAR(50) NOT NULL,
    test_date DATE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('planned', 'in_progress', 'passed', 'failed'))
);

CREATE TABLE test_package_spool (
    test_package_id INTEGER NOT NULL REFERENCES test_package(test_package_id),
    spool_id INTEGER NOT NULL REFERENCES spool(spool_id),
    PRIMARY KEY (test_package_id, spool_id)
);

CREATE FUNCTION check_test_package_spool_status()
RETURNS TRIGGER AS $$
DECLARE
    current_status VARCHAR(30);
BEGIN
    SELECT fabrication_status INTO current_status
    FROM spool WHERE spool_id = NEW.spool_id FOR UPDATE;
    IF current_status IS NOT NULL AND current_status NOT IN ('released', 'installed', 'tested') THEN
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

CREATE TABLE test_package_flange_connection (
    test_package_id INTEGER NOT NULL REFERENCES test_package(test_package_id),
    flange_connection_id INTEGER NOT NULL REFERENCES flange_connection(flange_connection_id),
    PRIMARY KEY (test_package_id, flange_connection_id)
);

CREATE TABLE test_package_equipment (
    test_package_id INTEGER NOT NULL REFERENCES test_package(test_package_id),
    equipment_id INTEGER NOT NULL REFERENCES equipment(equipment_id),
    PRIMARY KEY (test_package_id, equipment_id)
);
