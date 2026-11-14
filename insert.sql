BEGIN;

-- Участки и трубопроводы

INSERT INTO area (area_code, area_name, area_type)
VALUES
    ('CTL-01', 'Central Control Room', 'Control'),
    ('PRC-01', 'Feed Gas Receiving and Inlet Manifold', 'Process'),
    ('PRC-02', 'Inlet Gas Separation Unit', 'Process'),
    ('PRC-03', 'Gas Treatment and Dehydration Unit', 'Process'),
    ('PRC-04', 'Natural Gas Liquefaction Unit', 'Process'),
    ('PRC-05', 'Refrigerant Compressor and Piping Area', 'Process'),
    ('PRC-06', 'Boil-off Gas Collection Unit', 'Process'),
    ('STG-01', 'LNG Storage Tank Area and Associated Piping', 'Storage'),
    ('STG-02', 'Condensate Storage Tank Area and Associated Piping', 'Storage'),
    ('EXP-01', 'LNG Loading Pumps and Manifold', 'Loading'),
    ('EXP-02', 'Condensate Loading Pumps and Manifold', 'Loading'),
    ('FLR-01', 'High-Pressure Flare and Inlet Piping', 'Flare'),
    ('FLR-02', 'Low-Pressure Flare and Inlet Piping', 'Flare'),
    ('UTL-01', 'Water Treatment and Distribution Unit', 'Utilities'),
    ('UTL-02', 'Wastewater Treatment Unit', 'Utilities'),
    ('UTL-03', 'Firewater Pumping and Piping Area', 'Utilities'),
    ('UTL-04', 'Compressed Air and Nitrogen Supply Unit', 'Utilities'),
    ('UTL-05', 'Boiler and Heating Medium Manifold', 'Utilities'),
    ('PIP-01', 'Main Pipe Rack', 'Piping'),
    ('PIP-02', 'Intermodule Piping and Tie-in Area', 'Piping');

INSERT INTO pipeline (pipeline_code, service, pressure_category, temperature_category)
VALUES
    ('FG-001', 'Feed gas', 'high', 'normal'),
    ('FG-002', 'Feed gas', 'high', 'normal'),
    ('FG-003', 'Treated gas', 'high', 'normal'),
    ('LNG-001', 'LNG', 'low', 'cryogenic'),
    ('LNG-002', 'LNG', 'low', 'cryogenic'),
    ('LNG-003', 'LNG', 'low', 'cryogenic'),
    ('CD-001', 'Condensate', 'normal', 'normal'),
    ('CD-002', 'Condensate', 'normal', 'normal'),
    ('REF-001', 'Refrigerant', 'high', 'low'),
    ('REF-002', 'Refrigerant', 'low', 'low'),
    ('BOG-001', 'Boil-off gas', 'low', 'low'),
    ('BOG-002', 'Boil-off gas', 'normal', 'normal'),
    ('HPF-001', 'Flare gas', 'high', 'normal'),
    ('LPF-001', 'Flare gas', 'low', 'normal'),
    ('FW-001', 'Firewater', 'normal', 'low'),
    ('IA-001', 'Instrument air', 'normal', 'normal'),
    ('N2-001', 'Nitrogen', 'normal', 'normal'),
    ('HM-001', 'Heating medium', 'normal', 'high'),
    ('WTR-001', 'Treated water', 'normal', 'low'),
    ('WW-001', 'Wastewater', 'normal', 'normal');

INSERT INTO pipeline_area (pipeline_id, area_id, heat_tracing, min_insulation_thickness_mm, passive_fire_protection)
SELECT p.pipeline_id, a.area_id, links.heat_tracing, links.min_insulation_thickness_mm, links.passive_fire_protection
FROM (VALUES
        ('FG-001', 'PRC-01', FALSE, 0, FALSE),
        ('FG-001', 'PRC-02', FALSE, 0, TRUE),
        ('FG-001', 'PIP-01', TRUE, 40, FALSE),
        ('FG-002', 'PRC-02', FALSE, 0, FALSE),
        ('FG-002', 'PRC-03', FALSE, 0, FALSE),
        ('FG-002', 'PIP-02', FALSE, 0, FALSE),
        ('FG-003', 'PRC-03', FALSE, 0, FALSE),
        ('FG-003', 'PRC-04', FALSE, 0, FALSE),
        ('FG-003', 'PIP-02', FALSE, 0, FALSE),
        ('LNG-001', 'PRC-04', FALSE, 120, TRUE),
        ('LNG-001', 'STG-01', FALSE, 120, FALSE),
        ('LNG-001', 'PIP-02', FALSE, 80, FALSE),
        ('LNG-002', 'STG-01', FALSE, 120, FALSE),
        ('LNG-002', 'EXP-01', FALSE, 120, FALSE),
        ('LNG-002', 'PIP-01', FALSE, 120, FALSE),
        ('LNG-003', 'EXP-01', FALSE, 120, FALSE),
        ('LNG-003', 'PIP-01', FALSE, 120, FALSE),
        ('CD-001', 'PRC-02', FALSE, 0, FALSE),
        ('CD-001', 'STG-02', FALSE, 0, FALSE),
        ('CD-001', 'PIP-01', FALSE, 0, FALSE),
        ('CD-002', 'STG-02', FALSE, 0, FALSE),
        ('CD-002', 'EXP-02', FALSE, 0, FALSE),
        ('CD-002', 'PIP-01', FALSE, 0, FALSE),
        ('REF-001', 'PRC-05', FALSE, 80, FALSE),
        ('REF-001', 'PRC-04', FALSE, 80, FALSE),
        ('REF-001', 'PIP-02', FALSE, 80, FALSE),
        ('REF-002', 'PRC-04', FALSE, 80, FALSE),
        ('REF-002', 'PRC-05', FALSE, 80, FALSE),
        ('REF-002', 'PIP-02', FALSE, 80, FALSE),
        ('BOG-001', 'STG-01', FALSE, 80, FALSE),
        ('BOG-001', 'PRC-06', FALSE, 80, FALSE),
        ('BOG-001', 'PIP-01', FALSE, 80, FALSE),
        ('BOG-002', 'PRC-06', FALSE, 0, FALSE),
        ('BOG-002', 'PRC-04', FALSE, 0, FALSE),
        ('BOG-002', 'PIP-02', FALSE, 0, FALSE),
        ('HPF-001', 'PRC-02', FALSE, 0, FALSE),
        ('HPF-001', 'FLR-01', FALSE, 0, TRUE),
        ('HPF-001', 'PIP-01', FALSE, 0, FALSE),
        ('LPF-001', 'PRC-04', FALSE, 0, FALSE),
        ('LPF-001', 'FLR-02', FALSE, 0, FALSE),
        ('LPF-001', 'PIP-01', FALSE, 0, FALSE),
        ('FW-001', 'UTL-03', TRUE, 80, FALSE),
        ('FW-001', 'PIP-01', TRUE, 80, FALSE),
        ('FW-001', 'PIP-02', TRUE, 80, FALSE),
        ('IA-001', 'UTL-04', FALSE, 0, FALSE),
        ('IA-001', 'CTL-01', FALSE, 0, FALSE),
        ('IA-001', 'PIP-01', FALSE, 0, FALSE),
        ('N2-001', 'UTL-04', FALSE, 0, FALSE),
        ('N2-001', 'PRC-04', FALSE, 0, FALSE),
        ('N2-001', 'PIP-02', FALSE, 0, FALSE),
        ('HM-001', 'UTL-05', FALSE, 80, FALSE),
        ('HM-001', 'PRC-04', FALSE, 80, FALSE),
        ('HM-001', 'PIP-01', FALSE, 80, FALSE),
        ('WTR-001', 'UTL-01', TRUE, 80, FALSE),
        ('WTR-001', 'PRC-03', TRUE, 80, FALSE),
        ('WTR-001', 'PIP-01', TRUE, 80, FALSE),
        ('WW-001', 'PRC-02', FALSE, 0, FALSE),
        ('WW-001', 'UTL-02', FALSE, 0, FALSE),
        ('WW-001', 'PIP-01', FALSE, 0, FALSE)
) AS links(pipeline_code, area_code, heat_tracing, min_insulation_thickness_mm, passive_fire_protection)
JOIN pipeline AS p ON p.pipeline_code = links.pipeline_code
JOIN area AS a ON a.area_code = links.area_code;

-- Чертежи и спулы

INSERT INTO isometric_drawing (isometric_number, pipeline_id)
SELECT drawings.isometric_number, p.pipeline_id
FROM (VALUES
        ('ISO-001', 'FG-001'),
        ('ISO-002', 'FG-002'),
        ('ISO-003', 'FG-003'),
        ('ISO-004', 'LNG-001'),
        ('ISO-005', 'LNG-002'),
        ('ISO-006', 'LNG-003'),
        ('ISO-007', 'CD-001'),
        ('ISO-008', 'CD-002'),
        ('ISO-009', 'REF-001'),
        ('ISO-010', 'REF-002'),
        ('ISO-011', 'BOG-001'),
        ('ISO-012', 'BOG-002'),
        ('ISO-013', 'HPF-001'),
        ('ISO-014', 'LPF-001'),
        ('ISO-015', 'FW-001'),
        ('ISO-016', 'IA-001'),
        ('ISO-017', 'N2-001'),
        ('ISO-018', 'HM-001'),
        ('ISO-019', 'WTR-001'),
        ('ISO-020', 'WW-001')
) AS drawings(isometric_number, pipeline_code)
JOIN pipeline AS p ON p.pipeline_code = drawings.pipeline_code;

INSERT INTO isometric_revision (isometric_id, revision, issue_date)
SELECT d.isometric_id, revisions.revision, revisions.issue_date
FROM (VALUES
        ('ISO-001', '00', DATE '2023-01-01'),
        ('ISO-002', '01', DATE '2023-01-02'),
        ('ISO-003', '02', DATE '2023-01-03'),
        ('ISO-004', '03', DATE '2023-01-04'),
        ('ISO-005', '01', DATE '2023-01-05'),
        ('ISO-006', '02', DATE '2023-01-06'),
        ('ISO-007', '03', DATE '2023-01-07'),
        ('ISO-008', '01', DATE '2024-01-08'),
        ('ISO-009', '02', DATE '2024-01-09'),
        ('ISO-010', '03', DATE '2024-01-10'),
        ('ISO-011', '01', DATE '2024-01-11'),
        ('ISO-012', '02', DATE '2024-01-12'),
        ('ISO-013', '03', DATE '2024-01-13'),
        ('ISO-014', '01', DATE '2024-01-14'),
        ('ISO-015', '02', DATE '2025-01-15'),
        ('ISO-016', '03', DATE '2025-01-16'),
        ('ISO-017', '01', DATE '2025-01-17'),
        ('ISO-018', '02', DATE '2025-01-18'),
        ('ISO-019', '03', DATE '2025-01-19'),
        ('ISO-020', '01', DATE '2025-01-20'),
        ('ISO-001', '01', DATE '2024-02-01')
) AS revisions(isometric_number, revision, issue_date)
JOIN isometric_drawing AS d ON d.isometric_number = revisions.isometric_number;

INSERT INTO spool (spool_code, isometric_revision_id, area_id, weight_ton, fabrication_status)
SELECT spools.spool_code, r.isometric_revision_id, a.area_id,
       spools.weight_ton, spools.fabrication_status
FROM (VALUES
        ('SP-001', 'ISO-001', '00', 'PRC-01', 0.085, 'released'),
        ('SP-002', 'ISO-002', '01', 'PRC-02', 0.320, 'released'),
        ('SP-003', 'ISO-003', '02', 'PRC-03', 0.145, 'released'),
        ('SP-004', 'ISO-004', '03', 'PRC-04', 1.250, 'released'),
        ('SP-005', 'ISO-005', '01', 'STG-01', 0.670, 'released'),
        ('SP-006', 'ISO-006', '02', 'EXP-01', 0.190, 'released'),
        ('SP-007', 'ISO-007', '03', 'PRC-02', 0.430, 'released'),
        ('SP-008', 'ISO-008', '01', 'STG-02', 1.780, 'released'),
        ('SP-009', 'ISO-009', '02', 'PRC-05', 0.275, 'released'),
        ('SP-010', 'ISO-010', '03', 'PRC-04', 0.940, 'released'),
        ('SP-011', 'ISO-011', '01', 'STG-01', 0.120, 'released'),
        ('SP-012', 'ISO-012', '02', 'PRC-06', 0.560, 'released'),
        ('SP-013', 'ISO-013', '03', 'PRC-02', 0.210, 'released'),
        ('SP-014', 'ISO-014', '01', 'PRC-04', 1.460, 'released'),
        ('SP-015', 'ISO-015', '02', 'UTL-03', 0.375, 'released'),
        ('SP-016', 'ISO-016', '03', 'UTL-04', 0.065, 'released'),
        ('SP-017', 'ISO-017', '01', 'UTL-04', 0.510, 'released'),
        ('SP-018', 'ISO-018', '02', 'UTL-05', 0.830, 'released'),
        ('SP-019', 'ISO-019', '03', 'UTL-01', 0.155, 'released'),
        ('SP-020', 'ISO-020', '01', 'PRC-02', 1.120, 'released'),
        ('SP-021', 'ISO-001', '01', 'PRC-01', 0.240, 'released')
) AS spools(spool_code, isometric_number, revision, area_code, weight_ton, fabrication_status)
JOIN isometric_drawing AS d ON d.isometric_number = spools.isometric_number
JOIN isometric_revision AS r ON r.isometric_id = d.isometric_id AND r.revision = spools.revision
JOIN area AS a ON a.area_code = spools.area_code
JOIN pipeline_area AS pa ON pa.pipeline_id = d.pipeline_id AND pa.area_id = a.area_id;

-- Сварщики и сертификаты

INSERT INTO welder (welder_employer_no, welder_name, welder_license_no, welder_last_attestation_date)
VALUES
    ('W001', 'Иванов Сергей Петрович', '104827', DATE '2025-01-01'),
    ('W002', 'Петров Алексей Викторович', '205319', DATE '2025-01-02'),
    ('W003', 'Смирнов Дмитрий Андреевич', '318406', DATE '2025-01-03'),
    ('W004', 'Кузнецов Михаил Олегович', '426751', DATE '2025-01-04'),
    ('W005', 'Волков Андрей Сергеевич', '537208', DATE '2025-01-05'),
    ('W006', 'Соколов Павел Игоревич', '648193', DATE '2025-01-06'),
    ('W007', 'Фёдоров Николай Алексеевич', '759024', DATE '2025-01-07'),
    ('W008', 'Морозов Евгений Владимирович', '861735', DATE '2025-01-08'),
    ('W009', 'Козлов Максим Юрьевич', '972146', DATE '2025-01-09'),
    ('W010', 'Васильев Роман Дмитриевич', '103958', DATE '2025-01-10'),
    ('W011', 'Ахмедов Азизбек Рустамович', '214680', DATE '2025-01-11'),
    ('W012', 'Каримов Бахтиёр Улугбекович', '325791', DATE '2025-01-12'),
    ('W013', 'Рахимов Дилшод Фарходович', '436802', DATE '2025-01-13'),
    ('W014', 'Юсупов Шерзод Абдурахманович', '547913', DATE '2025-01-14'),
    ('W015', 'Турсунов Нурбек Бакытович', '658024', DATE '2025-01-15'),
    ('W016', 'Садыков Эрмек Кубанычбекович', '769135', DATE '2025-01-16'),
    ('W017', 'Ибрагимов Данияр Маратович', '870246', DATE '2025-01-17'),
    ('W018', 'Назаров Фаррух Рахматович', '981357', DATE '2025-01-18'),
    ('W019', 'Исмоилов Комрон Шарифович', '192468', DATE '2025-01-19'),
    ('W020', 'Алимов Бобур Азизович', '243579', DATE '2025-01-20');

INSERT INTO welder_certificate (welder_id, certificate_number, standard, valid_until)
SELECT w.welder_id, certificates.certificate_number, certificates.standard, certificates.valid_until
FROM (VALUES
        ('W001', '900001', 'ISO 9606-1', DATE '2027-03-04'),
        ('W002', '900002', 'ISO 9606-1', DATE '2028-05-07'),
        ('W003', '900003', 'ISO 9606-1', DATE '2026-07-10'),
        ('W004', '900004', 'ISO 9606-1', DATE '2027-09-13'),
        ('W005', '900005', 'ISO 9606-1', DATE '2028-11-16'),
        ('W006', '900006', 'ISO 9606-1', DATE '2026-01-19'),
        ('W007', '900007', 'ISO 9606-1', DATE '2027-03-22'),
        ('W008', '900008', 'ISO 9606-1', DATE '2028-05-25'),
        ('W009', '900009', 'ISO 9606-1', DATE '2026-07-01'),
        ('W010', '900010', 'ISO 9606-1', DATE '2027-09-04'),
        ('W011', '900011', 'ISO 9606-1', DATE '2028-11-07'),
        ('W012', '900012', 'ISO 9606-1', DATE '2026-01-10'),
        ('W013', '900013', 'ISO 9606-1', DATE '2027-03-13'),
        ('W014', '900014', 'ISO 9606-1', DATE '2028-05-16'),
        ('W015', '900015', 'ISO 9606-1', DATE '2026-07-19'),
        ('W016', '900016', 'ISO 9606-1', DATE '2027-09-22'),
        ('W017', '900017', 'ISO 9606-1', DATE '2028-11-25'),
        ('W018', '900018', 'ISO 9606-1', DATE '2026-01-01'),
        ('W001', '910001', 'ISO 9606-2', DATE '2027-03-04'),
        ('W002', '910002', 'ISO 9606-3', DATE '2028-05-07'),
        ('W003', '910003', 'ISO 9606-4', DATE '2026-07-10'),
        ('W004', '910004', 'ISO 9606-5', DATE '2027-09-13')
) AS certificates(welder_employer_no, certificate_number, standard, valid_until)
JOIN welder AS w ON w.welder_employer_no = certificates.welder_employer_no;

-- Справочники компонентов и материалов

INSERT INTO component_type (type_code, type_name)
VALUES
    ('PIPE', 'Pipe'),
    ('ELBOW', 'Elbow'),
    ('TEE-EQ', 'Equal tee'),
    ('TEE-RED', 'Reducing tee'),
    ('RED-CON', 'Concentric reducer'),
    ('RED-ECC', 'Eccentric reducer'),
    ('FLG-WN', 'Weld neck flange'),
    ('FLG-BL', 'Blind flange'),
    ('CAP', 'Pipe cap'),
    ('COUPLING', 'Coupling'),
    ('VLV-BALL', 'Ball valve'),
    ('VLV-GATE', 'Gate valve'),
    ('VLV-GLOBE', 'Globe valve'),
    ('VLV-CHECK', 'Check valve'),
    ('VLV-BFLY', 'Butterfly valve'),
    ('STRAINER', 'Strainer'),
    ('EXP-JOINT', 'Expansion joint'),
    ('ORIFICE', 'Orifice plate'),
    ('PRESS-GAUGE', 'Pressure gauge'),
    ('TEMP-SENSOR', 'Temperature sensor');

INSERT INTO material (material_code, material_name, material_standard)
VALUES
    ('A106 Gr A', 'Carbon steel', 'ASTM A106'),
    ('A106 Gr B', 'Carbon steel', 'ASTM A106'),
    ('A106 Gr C', 'Carbon steel', 'ASTM A106'),
    ('A53 Gr A', 'Carbon steel', 'ASTM A53'),
    ('A53 Gr B', 'Carbon steel', 'ASTM A53'),
    ('A333 Gr 1', 'Low-temperature carbon steel', 'ASTM A333'),
    ('A333 Gr 3', 'Low-temperature alloy steel', 'ASTM A333'),
    ('A333 Gr 6', 'Low-temperature carbon steel', 'ASTM A333'),
    ('A312 TP304', 'Stainless steel', 'ASTM A312'),
    ('A312 TP304L', 'Stainless steel', 'ASTM A312'),
    ('A312 TP316', 'Stainless steel', 'ASTM A312'),
    ('A312 TP316L', 'Stainless steel', 'ASTM A312'),
    ('A312 TP321', 'Stainless steel', 'ASTM A312'),
    ('A312 TP347', 'Stainless steel', 'ASTM A312'),
    ('A335 P5', 'Alloy steel', 'ASTM A335'),
    ('A335 P9', 'Alloy steel', 'ASTM A335'),
    ('A335 P11', 'Alloy steel', 'ASTM A335'),
    ('A335 P22', 'Alloy steel', 'ASTM A335'),
    ('A335 P91', 'Alloy steel', 'ASTM A335'),
    ('A312 TP310S', 'Stainless steel', 'ASTM A312');

INSERT INTO insulation_material (material_code, material_name)
VALUES
    ('MINERAL-WOOL', 'Mineral wool'),
    ('PIR', 'Polyisocyanurate foam'),
    ('CELLULAR-GLASS', 'Cellular glass'),
    ('AEROGEL', 'Aerogel blanket');

INSERT INTO cladding_material (material_code, material_name, coating)
VALUES
    ('GALV-STEEL', 'Galvanized steel sheet', 'Zinc'),
    ('SS-304', 'Stainless steel sheet 304', 'None'),
    ('ALUMINUM', 'Aluminum sheet', 'None'),
    ('COATED-STEEL', 'Coated steel sheet', 'Polyester');

-- Поставщики

INSERT INTO vendor (vendor_name, vendor_code, country, tax_id, vendor_address, phone, email, contact_name, contact_position)
VALUES
    ('PJSC TMK', 'V01', 'Russia', '7710373095', '40 Pokrovka Street, Building 2A, Moscow, 101000, Russia', '+7 495 788 50 05', 'sales@tmk-group.com', NULL, NULL),
    ('Swagelok Georgia', 'V02', 'United States', '987654321', '2555 Marconi Drive, Alpharetta, GA 30005, USA', '+1 678 624 0949', 'info@georgia.swagelok.com', NULL, NULL),
    ('BUTTING Gruppe GmbH & Co. KG', 'V03', 'Germany', 'DE261425104', 'Gifhorner Strasse 59, 29379 Knesebeck, Germany', '+49 5834 50-0', 'info@butting.de', 'Andrea Kiel', 'Marketing and Communications'),
    ('New Machine Co., Ltd.', 'V04', 'Japan', '1234567890123', '3-24-8 Shiohama, Kawasaki-ku, Kawasaki-shi, Kanagawa 210-0826, Japan', '+81 44 589 7604', 'info@new-machine.co.jp', NULL, NULL),
    ('Hebei Renlong Pipe Fittings Co., Ltd.', 'V05', 'China', '91110000123456789X', 'No Jia 2, Yuquan Road, Haidian District, Beijing 100143, China', '+86 137 1877 9097', 'Qing.h@rlpipes.com', 'Qing Huang', 'Sales Manager'),
    ('Piping Supplies Inc.', 'V06', 'United States', '987654322', '18 E Black Horse Pike, Williamstown, NJ 08094, USA', '+1 609 561 9323', 'joe@pipingsuppliesinc.com', 'Joe Walker', 'Owner'),
    ('JCM Industries', 'V07', 'United States', '987654323', '200 Old Boston Road, Nash, TX 75569, USA', '+1 903 832 2581', 'sales@jcmindustries.com', NULL, NULL),
    ('Missouri Pipe Fittings Company', 'V08', 'United States', '987654324', '400 Withers Avenue, St. Louis, MO 63147, USA', '+1 314 421 0790', 'sales@mopipe.us', NULL, NULL),
    ('EHG Edelstahl Rohrherstellung GmbH', 'V09', 'Germany', 'DE987654321', 'Gewerbestrasse 3, 08237 Steinberg, Germany', '+49 37462 688 0', 'info@ehg-steinberg.de', NULL, NULL),
    ('fischer Edelstahlrohre GmbH', 'V10', 'Germany', 'DE987654322', 'Im Gewerbegebiet 7, 77855 Achern-Fautenbach, Germany', '+49 7841 6803-0', 'sales@fischer-group.com', 'Guido Eckenwalder', 'Sales Director'),
    ('Esta Rohr GmbH', 'V11', 'Germany', 'DE987654323', 'Eisenhuettenstrasse 11-17, 57074 Siegen, Germany', '+49 271 6909-0', 'info@esta-rohr.de', NULL, NULL),
    ('Hirose Valves Industry Co., Ltd.', 'V12', 'Japan', '1234567890124', '436 Serigawa-cho, Hikone, Shiga, Japan', '+81 749 23 2020', 'info@hirose-valves.co.jp', NULL, NULL),
    ('Nippon Bend Co., Ltd.', 'V13', 'Japan', '1234567890125', '3-14-21 Honhaneda, Ota-ku, Tokyo 144-0044, Japan', '+81 3 3744 2141', 'bend@cside.com', 'Mitsunori Tsukidate', 'Representative Director'),
    ('Cangzhou Jinyi Pipe Fittings Manufacturing Co., Ltd.', 'V14', 'China', '91130000123456789X', 'Cangyan Road Industrial Park, Yanshan County, Cangzhou City, Hebei, China', '+86 177 6151 2539', 'sales@jinyipipefitting.com', NULL, NULL),
    ('Cangzhou Shenlong Pipe Manufacturing Co., Ltd.', 'V15', 'China', '91310000123456789X', '10A6, No 526 Laoshan Road, Pudong New District, Shanghai, China', '+86 21 6841 5567', 'info@pipesl.com', NULL, NULL);

-- Поставки и документы

INSERT INTO delivery (delivery_code, vendor_id, delivery_date)
SELECT data.delivery_code, vendor.vendor_id, data.delivery_date
FROM (VALUES
    ('DEL-001', 'V01', DATE '2024-03-12'),
    ('DEL-002', 'V02', DATE '2024-04-18'),
    ('DEL-003', 'V03', DATE '2024-05-14'),
    ('DEL-004', 'V04', DATE '2024-06-20'),
    ('DEL-005', 'V05', DATE '2024-07-16'),
    ('DEL-006', 'V06', DATE '2024-08-09'),
    ('DEL-007', 'V07', DATE '2024-09-23'),
    ('DEL-008', 'V08', DATE '2024-10-11'),
    ('DEL-009', 'V09', DATE '2024-11-07'),
    ('DEL-010', 'V10', DATE '2024-12-03'),
    ('DEL-011', 'V11', DATE '2025-01-21'),
    ('DEL-012', 'V12', DATE '2025-02-14'),
    ('DEL-013', 'V13', DATE '2025-03-05'),
    ('DEL-014', 'V14', DATE '2025-04-17'),
    ('DEL-015', 'V15', DATE '2025-05-28')
) AS data(delivery_code, vendor_code, delivery_date)
JOIN vendor ON vendor.vendor_code = data.vendor_code;

INSERT INTO delivery_document (delivery_id, document_type, document_number)
SELECT delivery.delivery_id, data.document_type, data.document_number
FROM (VALUES
    ('DEL-001', 'Delivery note', 'DN-2024-001'),
    ('DEL-002', 'Commercial invoice', 'INV-2024-002'),
    ('DEL-002', 'Bill of lading', 'BL-2024-002'),
    ('DEL-003', 'Commercial invoice', 'INV-2024-003'),
    ('DEL-003', 'CMR consignment note', 'CMR-2024-003'),
    ('DEL-004', 'Commercial invoice', 'INV-2024-004'),
    ('DEL-004', 'Bill of lading', 'BL-2024-004'),
    ('DEL-005', 'Commercial invoice', 'INV-2024-005'),
    ('DEL-005', 'Bill of lading', 'BL-2024-005'),
    ('DEL-006', 'Commercial invoice', 'INV-2024-006'),
    ('DEL-006', 'Bill of lading', 'BL-2024-006'),
    ('DEL-007', 'Commercial invoice', 'INV-2024-007'),
    ('DEL-007', 'Bill of lading', 'BL-2024-007'),
    ('DEL-008', 'Commercial invoice', 'INV-2024-008'),
    ('DEL-008', 'Bill of lading', 'BL-2024-008'),
    ('DEL-009', 'Commercial invoice', 'INV-2024-009'),
    ('DEL-009', 'CMR consignment note', 'CMR-2024-009'),
    ('DEL-010', 'Commercial invoice', 'INV-2024-010'),
    ('DEL-010', 'CMR consignment note', 'CMR-2024-010'),
    ('DEL-011', 'Commercial invoice', 'INV-2025-011'),
    ('DEL-011', 'CMR consignment note', 'CMR-2025-011'),
    ('DEL-012', 'Commercial invoice', 'INV-2025-012'),
    ('DEL-012', 'Bill of lading', 'BL-2025-012'),
    ('DEL-013', 'Commercial invoice', 'INV-2025-013'),
    ('DEL-013', 'Bill of lading', 'BL-2025-013'),
    ('DEL-014', 'Commercial invoice', 'INV-2025-014'),
    ('DEL-014', 'Bill of lading', 'BL-2025-014'),
    ('DEL-015', 'Commercial invoice', 'INV-2025-015'),
    ('DEL-015', 'Bill of lading', 'BL-2025-015')
) AS data(delivery_code, document_type, document_number)
JOIN delivery ON delivery.delivery_code = data.delivery_code;

-- Компоненты и изоляция

INSERT INTO component (component_no, component_type_id, spool_id, material_id, delivery_id, nominal_diameter_inch, wall_thickness_mm, length_mm, weight_ton, certificate_no)
SELECT data.component_no, ct.component_type_id, sp.spool_id, m.material_id, d.delivery_id,
       data.nominal_diameter_inch, data.wall_thickness_mm, data.length_mm, data.weight_ton, data.certificate_no
FROM (VALUES
        ('C-001', 'PIPE', 'SP-001', 'A106 Gr A', 'DEL-001', 6, 7.11, 1800, 0.084, 'CERT-001'),
        ('C-002', 'ELBOW', 'SP-002', 'A106 Gr B', 'DEL-002', 4, 6.02, 152, 0.006, 'CERT-002'),
        ('C-003', 'TEE-EQ', 'SP-003', 'A106 Gr C', 'DEL-003', 8, 8.18, 305, 0.028, 'CERT-003'),
        ('C-004', 'TEE-RED', 'SP-004', 'A53 Gr A', 'DEL-004', 6, 7.11, 229, 0.014, 'CERT-004'),
        ('C-005', 'RED-CON', 'SP-005', 'A53 Gr B', 'DEL-005', 8, 8.18, 203, 0.018, 'CERT-005'),
        ('C-006', 'RED-ECC', 'SP-006', 'A333 Gr 1', 'DEL-001', 6, 7.11, 140, 0.009, 'CERT-006'),
        ('C-007', 'FLG-WN', 'SP-007', 'A333 Gr 3', 'DEL-002', 4, 8.56, 102, 0.012, 'CERT-007'),
        ('C-008', 'FLG-BL', 'SP-008', 'A333 Gr 6', 'DEL-003', 8, NULL, 46, 0.038, 'CERT-008'),
        ('C-009', 'CAP', 'SP-009', 'A312 TP304', 'DEL-004', 3, 5.49, 76, 0.003, 'CERT-009'),
        ('C-010', 'COUPLING', 'SP-010', 'A312 TP304L', 'DEL-005', 2, 5.54, 80, 0.002, 'CERT-010'),
        ('C-011', 'VLV-BALL', 'SP-011', 'A312 TP316', 'DEL-001', 4, NULL, 305, 0.045, 'CERT-011'),
        ('C-012', 'VLV-GATE', 'SP-012', 'A312 TP316L', 'DEL-002', 6, NULL, 403, 0.092, 'CERT-012'),
        ('C-013', 'VLV-GLOBE', 'SP-013', 'A312 TP321', 'DEL-003', 3, NULL, 241, 0.031, 'CERT-013'),
        ('C-014', 'VLV-CHECK', 'SP-014', 'A312 TP347', 'DEL-004', 8, NULL, 495, 0.115, 'CERT-014'),
        ('C-015', 'VLV-BFLY', 'SP-015', 'A335 P5', 'DEL-005', 10, NULL, 127, 0.076, 'CERT-015'),
        ('C-016', 'STRAINER', 'SP-016', 'A335 P9', 'DEL-001', 4, NULL, 250, 0.024, 'CERT-016'),
        ('C-017', 'EXP-JOINT', 'SP-017', 'A335 P11', 'DEL-002', 6, NULL, 220, 0.017, 'CERT-017'),
        ('C-018', 'ORIFICE', 'SP-018', 'A335 P22', 'DEL-003', 8, NULL, 12, 0.010, 'CERT-018'),
        ('C-019', 'PRESS-GAUGE', 'SP-019', 'A335 P91', 'DEL-004', NULL, NULL, NULL, 0.002, 'CERT-019'),
        ('C-020', 'TEMP-SENSOR', 'SP-020', 'A312 TP310S', 'DEL-005', NULL, NULL, NULL, 0.001, 'CERT-020'),
        ('C-021', 'FLG-WN', 'SP-008', 'A333 Gr 6', 'DEL-003', 4, 8.56, 102, 0.012, 'CERT-021'),
        ('C-022', 'FLG-WN', 'SP-009', 'A312 TP304', 'DEL-004', 8, 8.18, 152, 0.038, 'CERT-022'),
        ('C-023', 'FLG-WN', 'SP-001', 'A312 TP316L', 'DEL-005', 2, NULL, NULL, 0.020, 'CERT-023'),
        ('C-024', 'FLG-WN', 'SP-002', 'A312 TP316L', 'DEL-005', 2, NULL, NULL, 0.020, 'CERT-024'),
        ('C-025', 'FLG-WN', 'SP-002', 'A312 TP316L', 'DEL-005', 3, NULL, NULL, 0.020, 'CERT-025'),
        ('C-026', 'FLG-WN', 'SP-003', 'A312 TP316L', 'DEL-005', 3, NULL, NULL, 0.020, 'CERT-026'),
        ('C-027', 'FLG-WN', 'SP-003', 'A312 TP316L', 'DEL-005', 4, NULL, NULL, 0.020, 'CERT-027'),
        ('C-028', 'FLG-WN', 'SP-004', 'A312 TP316L', 'DEL-005', 4, NULL, NULL, 0.020, 'CERT-028'),
        ('C-029', 'FLG-WN', 'SP-004', 'A312 TP316L', 'DEL-005', 6, NULL, NULL, 0.020, 'CERT-029'),
        ('C-030', 'FLG-WN', 'SP-005', 'A312 TP316L', 'DEL-005', 6, NULL, NULL, 0.020, 'CERT-030'),
        ('C-031', 'FLG-WN', 'SP-005', 'A312 TP316L', 'DEL-005', 8, NULL, NULL, 0.020, 'CERT-031'),
        ('C-032', 'FLG-WN', 'SP-006', 'A312 TP316L', 'DEL-005', 8, NULL, NULL, 0.020, 'CERT-032'),
        ('C-033', 'FLG-WN', 'SP-006', 'A312 TP316L', 'DEL-005', 10, NULL, NULL, 0.020, 'CERT-033'),
        ('C-034', 'FLG-WN', 'SP-007', 'A312 TP316L', 'DEL-005', 10, NULL, NULL, 0.020, 'CERT-034'),
        ('C-035', 'FLG-WN', 'SP-007', 'A312 TP316L', 'DEL-005', 2, NULL, NULL, 0.020, 'CERT-035'),
        ('C-036', 'FLG-WN', 'SP-008', 'A312 TP316L', 'DEL-005', 2, NULL, NULL, 0.020, 'CERT-036'),
        ('C-037', 'FLG-WN', 'SP-008', 'A312 TP316L', 'DEL-005', 3, NULL, NULL, 0.020, 'CERT-037'),
        ('C-038', 'FLG-WN', 'SP-009', 'A312 TP316L', 'DEL-005', 3, NULL, NULL, 0.020, 'CERT-038'),
        ('C-039', 'FLG-WN', 'SP-009', 'A312 TP316L', 'DEL-005', 4, NULL, NULL, 0.020, 'CERT-039'),
        ('C-040', 'FLG-WN', 'SP-010', 'A312 TP316L', 'DEL-005', 4, NULL, NULL, 0.020, 'CERT-040'),
        ('C-041', 'FLG-WN', 'SP-010', 'A312 TP316L', 'DEL-005', 6, NULL, NULL, 0.020, 'CERT-041'),
        ('C-042', 'FLG-WN', 'SP-011', 'A312 TP316L', 'DEL-005', 6, NULL, NULL, 0.020, 'CERT-042'),
        ('C-043', 'FLG-WN', 'SP-011', 'A312 TP316L', 'DEL-005', 8, NULL, NULL, 0.020, 'CERT-043'),
        ('C-044', 'FLG-WN', 'SP-012', 'A312 TP316L', 'DEL-005', 8, NULL, NULL, 0.020, 'CERT-044'),
        ('C-045', 'FLG-WN', 'SP-012', 'A312 TP316L', 'DEL-005', 10, NULL, NULL, 0.020, 'CERT-045'),
        ('C-046', 'FLG-WN', 'SP-013', 'A312 TP316L', 'DEL-005', 10, NULL, NULL, 0.020, 'CERT-046'),
        ('C-047', 'FLG-WN', 'SP-013', 'A312 TP316L', 'DEL-005', 2, NULL, NULL, 0.020, 'CERT-047'),
        ('C-048', 'FLG-WN', 'SP-014', 'A312 TP316L', 'DEL-005', 2, NULL, NULL, 0.020, 'CERT-048'),
        ('C-049', 'FLG-WN', 'SP-014', 'A312 TP316L', 'DEL-005', 3, NULL, NULL, 0.020, 'CERT-049'),
        ('C-050', 'FLG-WN', 'SP-015', 'A312 TP316L', 'DEL-005', 3, NULL, NULL, 0.020, 'CERT-050'),
        ('C-051', 'FLG-WN', 'SP-015', 'A312 TP316L', 'DEL-005', 4, NULL, NULL, 0.020, 'CERT-051'),
        ('C-052', 'FLG-WN', 'SP-016', 'A312 TP316L', 'DEL-005', 4, NULL, NULL, 0.020, 'CERT-052'),
        ('C-053', 'FLG-WN', 'SP-016', 'A312 TP316L', 'DEL-005', 6, NULL, NULL, 0.020, 'CERT-053'),
        ('C-054', 'FLG-WN', 'SP-017', 'A312 TP316L', 'DEL-005', 6, NULL, NULL, 0.020, 'CERT-054'),
        ('C-055', 'FLG-WN', 'SP-017', 'A312 TP316L', 'DEL-005', 8, NULL, NULL, 0.020, 'CERT-055'),
        ('C-056', 'FLG-WN', 'SP-018', 'A312 TP316L', 'DEL-005', 8, NULL, NULL, 0.020, 'CERT-056'),
        ('C-057', 'FLG-WN', 'SP-018', 'A312 TP316L', 'DEL-005', 10, NULL, NULL, 0.020, 'CERT-057'),
        ('C-058', 'FLG-WN', 'SP-019', 'A312 TP316L', 'DEL-005', 10, NULL, NULL, 0.020, 'CERT-058')
) AS data(component_no, type_code, spool_code, material_code, delivery_code, nominal_diameter_inch, wall_thickness_mm, length_mm, weight_ton, certificate_no)
JOIN component_type AS ct ON ct.type_code = data.type_code
JOIN spool AS sp ON sp.spool_code = data.spool_code
JOIN material AS m ON m.material_code = data.material_code
JOIN delivery AS d ON d.delivery_code = data.delivery_code;

INSERT INTO component_insulation (component_id, insulation_material_id, insulation_thickness_mm, cladding_material_id, cladding_thickness_mm)
SELECT c.component_id, im.insulation_material_id, data.insulation_thickness_mm,
       cm.cladding_material_id, data.cladding_thickness_mm
FROM (VALUES
    ('C-001', 'MINERAL-WOOL', 40, 'GALV-STEEL', 0.80),
    ('C-002', 'PIR', 80, 'SS-304', 0.60),
    ('C-003', 'CELLULAR-GLASS', 100, 'ALUMINUM', 0.80),
    ('C-004', 'AEROGEL', 120, 'COATED-STEEL', 0.70),
    ('C-005', 'MINERAL-WOOL', 120, 'GALV-STEEL', 0.80),
    ('C-006', 'CELLULAR-GLASS', 120, 'SS-304', 0.60),
    ('C-007', 'PIR', 40, 'ALUMINUM', 0.80),
    ('C-008', 'MINERAL-WOOL', 100, 'GALV-STEEL', 1.00),
    ('C-009', 'AEROGEL', 80, 'SS-304', 0.60),
    ('C-010', 'PIR', 80, 'ALUMINUM', 0.80),
    ('C-011', 'CELLULAR-GLASS', 120, 'SS-304', 0.80),
    ('C-012', 'MINERAL-WOOL', 80, 'GALV-STEEL', 0.80),
    ('C-013', 'AEROGEL', 60, 'SS-304', 0.60),
    ('C-014', 'PIR', 80, 'COATED-STEEL', 0.70),
    ('C-015', 'MINERAL-WOOL', 80, 'GALV-STEEL', 0.80),
    ('C-016', 'CELLULAR-GLASS', 100, 'ALUMINUM', 1.00),
    ('C-017', 'AEROGEL', 40, 'SS-304', 0.60),
    ('C-018', 'PIR', 80, 'COATED-STEEL', 0.70)
) AS data(component_no, insulation_code, insulation_thickness_mm, cladding_code, cladding_thickness_mm)
JOIN component AS c ON c.component_no = data.component_no
JOIN insulation_material AS im ON im.material_code = data.insulation_code
JOIN cladding_material AS cm ON cm.material_code = data.cladding_code;

-- Соединения

INSERT INTO weld_joint (weld_joint_no, first_component_id, second_component_id, weld_type, welding_process, weld_date, status)
VALUES
    ('WJ-001', 1, 2, 'butt', 'GTAW', DATE '2026-02-01', 'accepted'),
    ('WJ-002', 2, 3, 'butt', 'GTAW', DATE '2026-02-02', 'pending'),
    ('WJ-003', 3, 4, 'butt', 'GTAW', DATE '2026-02-03', 'accepted'),
    ('WJ-004', 4, 5, 'butt', 'GTAW', DATE '2026-02-04', 'pending'),
    ('WJ-005', 5, 6, 'butt', 'GTAW', DATE '2026-02-05', 'accepted'),
    ('WJ-006', 6, 7, 'butt', 'GTAW', DATE '2026-02-06', 'pending'),
    ('WJ-007', 7, 8, 'butt', 'GTAW', DATE '2026-02-07', 'accepted'),
    ('WJ-008', 8, 9, 'butt', 'GTAW', DATE '2026-02-08', 'pending'),
    ('WJ-009', 9, 10, 'butt', 'GTAW', DATE '2026-02-09', 'accepted'),
    ('WJ-010', 10, 11, 'butt', 'GTAW', DATE '2026-02-10', 'pending'),
    ('WJ-011', 11, 12, 'butt', 'GTAW', DATE '2026-02-11', 'accepted'),
    ('WJ-012', 12, 13, 'butt', 'GTAW', DATE '2026-02-12', 'pending'),
    ('WJ-013', 13, 14, 'butt', 'GTAW', DATE '2026-02-13', 'accepted'),
    ('WJ-014', 14, 15, 'butt', 'GTAW', DATE '2026-02-14', 'pending'),
    ('WJ-015', 15, 16, 'butt', 'GTAW', DATE '2026-02-15', 'accepted'),
    ('WJ-016', 16, 17, 'butt', 'GTAW', DATE '2026-02-16', 'pending'),
    ('WJ-017', 17, 18, 'butt', 'GTAW', DATE '2026-02-17', 'accepted'),
    ('WJ-018', 18, 19, 'butt', 'GTAW', DATE '2026-02-18', 'pending'),
    ('WJ-019', 19, 20, 'butt', 'GTAW', DATE '2026-02-19', 'accepted'),
    ('WJ-020', 20, 1, 'butt', 'GTAW', DATE '2026-02-20', 'pending');

INSERT INTO weld_assignment (weld_joint_id, welder_id)
VALUES
    (1, 1),
    (1, 2),
    (2, 3),
    (2, 4),
    (3, 5),
    (3, 6),
    (4, 7),
    (4, 8),
    (5, 9),
    (5, 10),
    (6, 11),
    (6, 12),
    (7, 13),
    (7, 14),
    (8, 15),
    (8, 16),
    (9, 17),
    (9, 18),
    (10, 19),
    (10, 20);

INSERT INTO flange_connection (flange_connection_no, first_component_id, second_component_id, gasket_type, bolt_specification, assembly_date, status)
SELECT data.connection_no, first_component.component_id, second_component.component_id,
       data.gasket_type, data.bolt_specification, data.assembly_date, data.status
FROM (VALUES
    ('FC-001', 'C-007', 'C-021', 'Spiral wound, graphite filler', 'ASTM A193 B7 studs with ASTM A194 2H nuts', DATE '2025-04-15', 'assembled'),
    ('FC-002', 'C-008', 'C-022', 'PTFE gasket', 'ASTM A193 B8M studs with ASTM A194 8M nuts', DATE '2025-09-22', 'accepted'),
    ('FC-003', 'C-023', 'C-024', 'Spiral wound, graphite filler', 'ASTM A193 B7 studs with ASTM A194 2H nuts', DATE '2025-02-05', 'assembled'),
    ('FC-004', 'C-025', 'C-026', 'PTFE gasket', 'ASTM A193 B8M studs with ASTM A194 8M nuts', DATE '2025-02-16', 'accepted'),
    ('FC-005', 'C-027', 'C-028', 'Spiral wound, PTFE filler', 'ASTM A193 B7 studs with ASTM A194 2H nuts', DATE '2025-02-27', 'pending'),
    ('FC-006', 'C-029', 'C-030', 'Spiral wound, graphite filler', 'ASTM A193 B8M studs with ASTM A194 8M nuts', DATE '2025-03-10', 'assembled'),
    ('FC-007', 'C-031', 'C-032', 'PTFE gasket', 'ASTM A193 B7 studs with ASTM A194 2H nuts', DATE '2025-03-21', 'accepted'),
    ('FC-008', 'C-033', 'C-034', 'Spiral wound, PTFE filler', 'ASTM A193 B8M studs with ASTM A194 8M nuts', DATE '2025-04-01', 'pending'),
    ('FC-009', 'C-035', 'C-036', 'Spiral wound, graphite filler', 'ASTM A193 B7 studs with ASTM A194 2H nuts', DATE '2025-04-12', 'assembled'),
    ('FC-010', 'C-037', 'C-038', 'PTFE gasket', 'ASTM A193 B8M studs with ASTM A194 8M nuts', DATE '2025-04-23', 'accepted'),
    ('FC-011', 'C-039', 'C-040', 'Spiral wound, PTFE filler', 'ASTM A193 B7 studs with ASTM A194 2H nuts', DATE '2025-05-04', 'pending'),
    ('FC-012', 'C-041', 'C-042', 'Spiral wound, graphite filler', 'ASTM A193 B8M studs with ASTM A194 8M nuts', DATE '2025-05-15', 'assembled'),
    ('FC-013', 'C-043', 'C-044', 'PTFE gasket', 'ASTM A193 B7 studs with ASTM A194 2H nuts', DATE '2025-05-26', 'accepted'),
    ('FC-014', 'C-045', 'C-046', 'Spiral wound, PTFE filler', 'ASTM A193 B8M studs with ASTM A194 8M nuts', DATE '2025-06-06', 'pending'),
    ('FC-015', 'C-047', 'C-048', 'Spiral wound, graphite filler', 'ASTM A193 B7 studs with ASTM A194 2H nuts', DATE '2025-06-17', 'assembled'),
    ('FC-016', 'C-049', 'C-050', 'PTFE gasket', 'ASTM A193 B8M studs with ASTM A194 8M nuts', DATE '2025-06-28', 'accepted'),
    ('FC-017', 'C-051', 'C-052', 'Spiral wound, PTFE filler', 'ASTM A193 B7 studs with ASTM A194 2H nuts', DATE '2025-07-09', 'pending'),
    ('FC-018', 'C-053', 'C-054', 'Spiral wound, graphite filler', 'ASTM A193 B8M studs with ASTM A194 8M nuts', DATE '2025-07-20', 'assembled'),
    ('FC-019', 'C-055', 'C-056', 'PTFE gasket', 'ASTM A193 B7 studs with ASTM A194 2H nuts', DATE '2025-07-31', 'accepted'),
    ('FC-020', 'C-057', 'C-058', 'Spiral wound, PTFE filler', 'ASTM A193 B8M studs with ASTM A194 8M nuts', DATE '2025-08-11', 'pending')
) AS data(connection_no, first_component_no, second_component_no, gasket_type, bolt_specification, assembly_date, status)
JOIN component AS first_component ON first_component.component_no = data.first_component_no
JOIN component AS second_component ON second_component.component_no = data.second_component_no;

-- Оборудование

INSERT INTO equipment (equipment_code, equipment_type, equipment_name, area_id, vendor_id, manufacturing_status)
SELECT data.equipment_code, data.equipment_type, data.equipment_name, a.area_id, v.vendor_id, data.manufacturing_status
FROM (VALUES
    ('EQ-001', 'Control system', 'Distributed control system', 'CTL-01', 'V01', 'installed'),
    ('EQ-002', 'Separator', 'Feed gas inlet separator', 'PRC-02', 'V03', 'installed'),
    ('EQ-003', 'Filter', 'Feed gas filter separator', 'PRC-01', 'V05', 'installed'),
    ('EQ-004', 'Absorber', 'Acid gas removal absorber', 'PRC-03', 'V03', 'installed'),
    ('EQ-005', 'Dryer', 'Molecular sieve gas dryer', 'PRC-03', 'V03', 'installed'),
    ('EQ-006', 'Heat exchanger', 'Main cryogenic heat exchanger', 'PRC-04', 'V03', 'installed'),
    ('EQ-007', 'Compressor', 'Refrigerant compressor', 'PRC-05', 'V04', 'installed'),
    ('EQ-008', 'Compressor', 'Boil-off gas compressor', 'PRC-06', 'V04', 'installed'),
    ('EQ-009', 'Tank', 'LNG storage tank', 'STG-01', 'V03', 'installed'),
    ('EQ-010', 'Tank', 'Condensate storage tank', 'STG-02', 'V03', 'installed'),
    ('EQ-011', 'Pump', 'LNG loading pump', 'EXP-01', 'V04', 'installed'),
    ('EQ-012', 'Pump', 'Condensate loading pump', 'EXP-02', 'V04', 'installed'),
    ('EQ-013', 'Flare stack', 'High-pressure flare stack', 'FLR-01', 'V05', 'installed'),
    ('EQ-014', 'Flare stack', 'Low-pressure flare stack', 'FLR-02', 'V05', 'installed'),
    ('EQ-015', 'Filter', 'Treated water filter', 'UTL-01', 'V02', 'installed'),
    ('EQ-016', 'Tank', 'Wastewater treatment tank', 'UTL-02', 'V03', 'installed'),
    ('EQ-017', 'Pump', 'Firewater pump', 'UTL-03', 'V04', 'installed'),
    ('EQ-018', 'Compressor', 'Instrument air compressor', 'UTL-04', 'V04', 'installed'),
    ('EQ-019', 'Generator', 'Nitrogen generator', 'UTL-04', 'V02', 'fabrication'),
    ('EQ-020', 'Boiler', 'Heating medium boiler', 'UTL-05', 'V03', 'fabrication')
) AS data(equipment_code, equipment_type, equipment_name, area_code, vendor_code, manufacturing_status)
JOIN area AS a ON a.area_code = data.area_code
JOIN vendor AS v ON v.vendor_code = data.vendor_code;

-- Контроль и ремонт

INSERT INTO inspection (weld_joint_id, inspection_type, inspection_date, result, report_no, defect_description)
SELECT w.weld_joint_id, data.inspection_type, data.inspection_date, data.result, data.report_no, data.defect_description
FROM (VALUES
    ('WJ-001', 'VT', DATE '2026-04-01', 'accepted', 'RPT-001', NULL),
    ('WJ-002', 'VT', DATE '2026-04-03', 'rejected', 'RPT-002', 'Undercut at weld toe'),
    ('WJ-003', 'UT', DATE '2026-04-05', 'accepted', 'RPT-003', NULL),
    ('WJ-004', 'PT', DATE '2026-04-07', 'accepted', 'RPT-004', NULL),
    ('WJ-005', 'MT', DATE '2026-04-09', 'accepted', 'RPT-005', NULL),
    ('WJ-006', 'RT', DATE '2026-04-11', 'rejected', 'RPT-006', 'Porosity indication'),
    ('WJ-007', 'RT', DATE '2026-04-13', 'accepted', 'RPT-007', NULL),
    ('WJ-008', 'UT', DATE '2026-04-15', 'accepted', 'RPT-008', NULL),
    ('WJ-009', 'PT', DATE '2026-04-17', 'accepted', 'RPT-009', NULL),
    ('WJ-010', 'UT', DATE '2026-04-19', 'rejected', 'RPT-010', 'Lack of fusion indication'),
    ('WJ-011', 'VT', DATE '2026-04-21', 'accepted', 'RPT-011', NULL),
    ('WJ-012', 'RT', DATE '2026-04-23', 'accepted', 'RPT-012', NULL),
    ('WJ-013', 'UT', DATE '2026-04-25', 'accepted', 'RPT-013', NULL),
    ('WJ-014', 'PT', DATE '2026-04-27', 'rejected', 'RPT-014', 'Surface crack indication'),
    ('WJ-015', 'MT', DATE '2026-04-29', 'accepted', 'RPT-015', NULL),
    ('WJ-016', 'VT', DATE '2026-05-01', 'accepted', 'RPT-016', NULL),
    ('WJ-017', 'RT', DATE '2026-05-03', 'accepted', 'RPT-017', NULL),
    ('WJ-018', 'VT', DATE '2026-05-05', 'rejected', 'RPT-018', 'Excessive weld reinforcement'),
    ('WJ-019', 'PT', DATE '2026-05-07', 'accepted', 'RPT-019', NULL),
    ('WJ-020', 'MT', DATE '2026-05-09', 'accepted', 'RPT-020', NULL),
    ('WJ-004', 'RT', DATE '2026-05-11', 'rejected', 'RPT-021', 'Porosity indication'),
    ('WJ-008', 'UT', DATE '2026-05-12', 'rejected', 'RPT-022', 'Lack of fusion indication'),
    ('WJ-012', 'PT', DATE '2026-05-13', 'rejected', 'RPT-023', 'Surface crack indication'),
    ('WJ-016', 'MT', DATE '2026-05-14', 'rejected', 'RPT-024', 'Linear surface indication'),
    ('WJ-020', 'VT', DATE '2026-05-15', 'rejected', 'RPT-025', 'Undercut at weld toe')
) AS data(weld_joint_no, inspection_type, inspection_date, result, report_no, defect_description)
JOIN weld_joint AS w ON w.weld_joint_no = data.weld_joint_no;

INSERT INTO repair_with_inspection (inspection_id, repair_date, repair_reason, repair_description, status)
SELECT i.inspection_id, data.repair_date, i.defect_description, data.repair_description, 'planned'
FROM (VALUES
    ('WJ-002', 'RPT-002', DATE '2026-06-05', 'Remove defect and repair weld'),
    ('WJ-006', 'RPT-006', DATE '2026-06-06', 'Remove porous section and repair weld'),
    ('WJ-010', 'RPT-010', DATE '2026-06-08', 'Remove lack of fusion and repair weld'),
    ('WJ-014', 'RPT-014', DATE '2026-06-10', 'Remove crack and repair weld'),
    ('WJ-018', 'RPT-018', DATE '2026-06-12', 'Correct weld profile'),
    ('WJ-004', 'RPT-021', DATE '2026-06-15', 'Remove porous section and repair weld'),
    ('WJ-008', 'RPT-022', DATE '2026-06-17', 'Remove lack of fusion and repair weld'),
    ('WJ-012', 'RPT-023', DATE '2026-06-19', 'Remove crack and repair weld'),
    ('WJ-016', 'RPT-024', DATE '2026-06-22', 'Remove linear indication and repair weld'),
    ('WJ-020', 'RPT-025', DATE '2026-06-24', 'Repair undercut at weld toe')
) AS data(weld_joint_no, report_no, repair_date, repair_description)
JOIN weld_joint AS w ON w.weld_joint_no = data.weld_joint_no
JOIN inspection AS i ON i.weld_joint_id = w.weld_joint_id AND i.report_no = data.report_no;

INSERT INTO repair_without_inspection (weld_joint_id, repair_date, repair_reason, repair_description, status)
SELECT w.weld_joint_id, data.repair_date, data.repair_reason, data.repair_description, data.status
FROM (VALUES
    ('WJ-003', DATE '2026-03-12', 'Incorrect root gap identified by site supervisor', 'Remove weld, correct root gap and reweld joint', 'completed'),
    ('WJ-007', DATE '2026-03-19', 'Wrong welding process used during fabrication', 'Remove affected weld metal and reweld using the approved process', 'completed'),
    ('WJ-011', DATE '2026-03-25', 'Joint misalignment identified during fabrication', 'Cut joint, realign components and reweld', 'completed')
) AS data(weld_joint_no, repair_date, repair_reason, repair_description, status)
JOIN weld_joint AS w ON w.weld_joint_no = data.weld_joint_no;

-- Испытания

INSERT INTO test_package (test_package_code, test_type, test_date, status)
VALUES
    ('TP-001', 'hydrostatic', NULL, 'planned'),
    ('TP-002', 'leak', NULL, 'planned'),
    ('TP-003', 'hydrostatic', DATE '2026-07-06', 'passed'),
    ('TP-004', 'pneumatic', DATE '2026-07-12', 'failed'),
    ('TP-005', 'leak', DATE '2026-07-20', 'passed'),
    ('TP-006', 'hydrostatic', NULL, 'in_progress'),
    ('TP-007', 'pneumatic', NULL, 'planned'),
    ('TP-008', 'leak', NULL, 'planned'),
    ('TP-009', 'hydrostatic', DATE '2026-08-04', 'passed'),
    ('TP-010', 'leak', DATE '2026-08-10', 'failed');

INSERT INTO test_package_spool (test_package_id, spool_id)
SELECT t.test_package_id, s.spool_id
FROM (VALUES
        ('TP-001', 'SP-001'),
        ('TP-001', 'SP-021'),
        ('TP-001', 'SP-007'),
        ('TP-001', 'SP-008'),
        ('TP-002', 'SP-004'),
        ('TP-002', 'SP-008'),
        ('TP-002', 'SP-009'),
        ('TP-003', 'SP-002'),
        ('TP-003', 'SP-003'),
        ('TP-004', 'SP-005'),
        ('TP-004', 'SP-006'),
        ('TP-005', 'SP-010'),
        ('TP-005', 'SP-011'),
        ('TP-006', 'SP-012'),
        ('TP-006', 'SP-013'),
        ('TP-007', 'SP-014'),
        ('TP-007', 'SP-015'),
        ('TP-008', 'SP-016'),
        ('TP-008', 'SP-017'),
        ('TP-009', 'SP-018'),
        ('TP-009', 'SP-019'),
        ('TP-010', 'SP-020')
) AS links(test_package_code, spool_code)
JOIN test_package AS t ON t.test_package_code = links.test_package_code
JOIN spool AS s ON s.spool_code = links.spool_code;

INSERT INTO test_package_spool (test_package_id, spool_id)
SELECT t.test_package_id, s.spool_id
FROM (VALUES
    ('TP-003', 'SP-001'),
    ('TP-003', 'SP-009'),
    ('TP-003', 'SP-010'),
    ('TP-003', 'SP-017'),
    ('TP-003', 'SP-018'),
    ('TP-004', 'SP-002'),
    ('TP-004', 'SP-003'),
    ('TP-004', 'SP-010'),
    ('TP-004', 'SP-011'),
    ('TP-004', 'SP-018'),
    ('TP-004', 'SP-019'),
    ('TP-005', 'SP-003'),
    ('TP-005', 'SP-004'),
    ('TP-005', 'SP-012'),
    ('TP-006', 'SP-004'),
    ('TP-006', 'SP-005'),
    ('TP-007', 'SP-005'),
    ('TP-007', 'SP-006'),
    ('TP-007', 'SP-013'),
    ('TP-008', 'SP-006'),
    ('TP-008', 'SP-007'),
    ('TP-008', 'SP-014'),
    ('TP-008', 'SP-015'),
    ('TP-009', 'SP-007'),
    ('TP-009', 'SP-008'),
    ('TP-009', 'SP-015'),
    ('TP-009', 'SP-016'),
    ('TP-010', 'SP-008'),
    ('TP-010', 'SP-009'),
    ('TP-010', 'SP-016'),
    ('TP-010', 'SP-017')
) AS links(test_package_code, spool_code)
JOIN test_package AS t ON t.test_package_code = links.test_package_code
JOIN spool AS s ON s.spool_code = links.spool_code
ON CONFLICT (test_package_id, spool_id) DO NOTHING;

INSERT INTO test_package_flange_connection (test_package_id, flange_connection_id)
SELECT t.test_package_id, f.flange_connection_id
FROM (VALUES
    ('TP-001', 'FC-001'),
    ('TP-002', 'FC-002'),
    ('TP-003', 'FC-003'),
    ('TP-004', 'FC-004'),
    ('TP-005', 'FC-005'),
    ('TP-006', 'FC-006'),
    ('TP-007', 'FC-007'),
    ('TP-008', 'FC-008'),
    ('TP-009', 'FC-009'),
    ('TP-010', 'FC-010'),
    ('TP-003', 'FC-011'),
    ('TP-004', 'FC-012'),
    ('TP-005', 'FC-013'),
    ('TP-006', 'FC-014'),
    ('TP-007', 'FC-015'),
    ('TP-008', 'FC-016'),
    ('TP-009', 'FC-017'),
    ('TP-010', 'FC-018'),
    ('TP-003', 'FC-019'),
    ('TP-004', 'FC-020')
) AS links(test_package_code, flange_connection_no)
JOIN test_package AS t ON t.test_package_code = links.test_package_code
JOIN flange_connection AS f ON f.flange_connection_no = links.flange_connection_no;

INSERT INTO test_package_equipment (test_package_id, equipment_id)
SELECT t.test_package_id, e.equipment_id
FROM (VALUES
    ('TP-001', 'EQ-002'),
    ('TP-001', 'EQ-003'),
    ('TP-002', 'EQ-006'),
    ('TP-003', 'EQ-005'),
    ('TP-003', 'EQ-004'),
    ('TP-004', 'EQ-009'),
    ('TP-005', 'EQ-011'),
    ('TP-006', 'EQ-007'),
    ('TP-007', 'EQ-008'),
    ('TP-008', 'EQ-012'),
    ('TP-009', 'EQ-017'),
    ('TP-010', 'EQ-016')
) AS links(test_package_code, equipment_code)
JOIN test_package AS t ON t.test_package_code = links.test_package_code
JOIN equipment AS e ON e.equipment_code = links.equipment_code;

COMMIT;
