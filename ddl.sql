CREATE TABLE area(
    area_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    area_code VARCHAR(20) UNIQUE NOT NULL,
    area_name VARCHAR(100),
    area_type VARCHAR(50)
);

CREATE TABLE pipeline(
    pipeline_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pipeline_code VARCHAR(50) UNIQUE NOT NULL ,
    area_id INTEGER NOT NULL,
    service VARCHAR(100), 
    design_pressure_bar NUMERIC(10, 2),
    design_temperature_c NUMERIC(10, 2),
    FOREIGN KEY (area_id) REFERENCES area(area_id)
);

CREATE TABLE isometric_drawing (
    isometric_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isometric_number VARCHAR(50) UNIQUE NOT NULL,
    pipeline_id INTEGER NOT NULL,
    revision VARCHAR(10),
    issue_date DATE,
    FOREIGN KEY (pipeline_id) REFERENCES pipeline(pipeline_id)
);

CREATE TABLE spool(
    spool_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    spool_code VARCHAR(50) UNIQUE NOT NULL,
    isometric_id INTEGER NOT NULL,
    weight_ton NUMERIC(10, 3),
    fabrication_status VARCHAR(30),
    FOREIGN KEY (isometric_id) REFERENCES isometric_drawing(isometric_id)
);

CREATE TABLE welder(
    welder_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    welder_employer_no VARCHAR(30) UNIQUE NOT NULL,
    welder_name VARCHAR(100) NOT NULL,
    welder_license_no VARCHAR(20),
    welder_last_attestation_date DATE
);

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

CREATE TABLE vendor(
    vendor_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vendor_name VARCHAR(200) UNIQUE NOT NULL,
    vendor_code VARCHAR(10) UNIQUE NOT NULL,
    vendor_address TEXT
);

CREATE TABLE component(
    component_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    component_no VARCHAR(50) UNIQUE NOT NULL,
    component_type_id INTEGER NOT NULL,
    spool_id INTEGER NOT NULL,
    material_id INTEGER,
    vendor_id INTEGER,
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
    FOREIGN KEY (vendor_id) REFERENCES vendor(vendor_id) 
);

CREATE TABLE weld_joint (
    weld_joint_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    weld_joint_no VARCHAR(50) UNIQUE NOT NULL,
    welder_id INTEGER NOT NULL,
    first_component_id INTEGER NOT NULL,
    second_component_id INTEGER NOT NULL,
    weld_type VARCHAR(30),
    welding_process VARCHAR(50),
    weld_date DATE,
    status VARCHAR(30),

    FOREIGN KEY (first_component_id) REFERENCES component(component_id),
    FOREIGN KEY (second_component_id) REFERENCES component(component_id),
    FOREIGN KEY (welder_id) REFERENCES welder(welder_id),
    CHECK (first_component_id <> second_component_id)
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

CREATE TABLE equipment (
    equipment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    equipment_code VARCHAR(50) UNIQUE NOT NULL,
    equipment_type VARCHAR(50),
    equipment_name VARCHAR(100),
    area_id INTEGER NOT NULL,
    vendor_id INTEGER,
    manufacturing_status VARCHAR(100),
    FOREIGN KEY (area_id) REFERENCES area(area_id),
    FOREIGN KEY (vendor_id) REFERENCES vendor(vendor_id)
);

CREATE TABLE inspection (
    inspection_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    weld_joint_id INTEGER NOT NULL,
    inspection_type VARCHAR(30) NOT NULL,
    inspection_date DATE,
    result VARCHAR(30),
    report_no VARCHAR(50),
    defect_description TEXT,
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
    FOREIGN KEY (inspection_id) REFERENCES inspection(inspection_id)
);